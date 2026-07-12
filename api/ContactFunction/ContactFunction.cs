using System.Text.Json;
using System.Text.RegularExpressions;
using Azure.Communication.Email;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace ContactFunction;

/// <summary>
/// Backend for the /contact form on matpadley.github.io. AuthorizationLevel.Anonymous is
/// intentional: a static site can't keep a function key secret client-side, so this endpoint
/// is protected instead by CORS (platform-level, configured in infra/main.bicep) plus the
/// explicit Origin check below, and by the honeypot/timing contract shared with
/// assets/js/contact-form.js in the main repo.
/// </summary>
public class ContactFunction(EmailClient emailClient, IConfiguration configuration, ILogger<ContactFunction> logger)
{
    private const int MinSubmitSeconds = 3;
    private const int MaxFieldLength = 5000;

    private static readonly Regex EmailPattern = new(@"^[^@\s]+@[^@\s]+\.[^@\s]+$", RegexOptions.Compiled);
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    [Function("ContactForm")]
    public async Task<IActionResult> Run(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", "options", Route = "contact")] HttpRequest req)
    {
        var origin = req.Headers.Origin.ToString();
        var allowedOrigins = (configuration["AllowedOrigins"] ?? string.Empty)
            .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);

        // Platform CORS (see infra/main.bicep) already keeps browsers from reading a response
        // to a disallowed origin, but it doesn't stop the request from being processed - only a
        // browser enforces CORS. Reject explicitly here too, since curl/script callers ignore
        // CORS headers entirely. This still doesn't stop a caller that omits the Origin header
        // altogether (any non-browser client can do that); see AZURE_SETUP_TODO.md.
        if (!string.IsNullOrEmpty(origin) && !allowedOrigins.Contains(origin))
        {
            logger.LogWarning("Rejected contact form submission from disallowed origin {Origin}.", origin);
            return new StatusCodeResult(StatusCodes.Status403Forbidden);
        }

        if (HttpMethods.IsOptions(req.Method))
        {
            return new NoContentResult();
        }

        ContactRequest? payload;
        try
        {
            payload = await JsonSerializer.DeserializeAsync<ContactRequest>(req.Body, JsonOptions);
        }
        catch (JsonException)
        {
            return new BadRequestObjectResult(new { error = "Malformed request body." });
        }

        if (payload is null)
        {
            return new BadRequestObjectResult(new { error = "Malformed request body." });
        }

        // Anti-bot checks. Both are silently accepted (200, no email sent) rather than
        // rejected, so scripted abuse doesn't learn which signal tripped it.
        if (!string.IsNullOrWhiteSpace(payload.Company))
        {
            logger.LogInformation("Dropped contact submission: honeypot field was filled in.");
            return new OkResult();
        }

        if (!SubmittedSlowEnough(payload.RenderedAt))
        {
            logger.LogInformation("Dropped contact submission: submitted too quickly after render.");
            return new OkResult();
        }

        // Real validation. Surfaced to the caller, since these indicate a genuine client bug
        // rather than abuse.
        var validationError = Validate(payload);
        if (validationError is not null)
        {
            return new BadRequestObjectResult(new { error = validationError });
        }

        try
        {
            await SendEmailAsync(payload);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to send contact form email.");
            return new StatusCodeResult(StatusCodes.Status500InternalServerError);
        }

        return new OkResult();
    }

    private static bool SubmittedSlowEnough(string? renderedAtRaw)
    {
        if (!long.TryParse(renderedAtRaw, out var renderedAtMs))
        {
            return false;
        }

        var renderedAt = DateTimeOffset.FromUnixTimeMilliseconds(renderedAtMs);
        return DateTimeOffset.UtcNow - renderedAt >= TimeSpan.FromSeconds(MinSubmitSeconds);
    }

    private static string? Validate(ContactRequest payload)
    {
        if (string.IsNullOrWhiteSpace(payload.Name) || payload.Name.Length > MaxFieldLength)
        {
            return "Name is required.";
        }

        if (string.IsNullOrWhiteSpace(payload.Email)
            || payload.Email.Length > MaxFieldLength
            || !EmailPattern.IsMatch(payload.Email))
        {
            return "A valid email address is required.";
        }

        if (string.IsNullOrWhiteSpace(payload.Message) || payload.Message.Length > MaxFieldLength)
        {
            return "Message is required.";
        }

        return null;
    }

    private async Task SendEmailAsync(ContactRequest payload)
    {
        var sender = configuration["EmailSender"]
            ?? throw new InvalidOperationException("EmailSender app setting is not configured.");
        var recipient = configuration["ContactRecipientEmail"]
            ?? throw new InvalidOperationException("ContactRecipientEmail app setting is not configured.");

        var content = new EmailContent($"New contact form message from {payload.Name}")
        {
            PlainText = $"From: {payload.Name} <{payload.Email}>\n\n{payload.Message}",
        };

        var message = new EmailMessage(sender, recipient, content);
        message.ReplyTo.Add(new EmailAddress(payload.Email!, payload.Name));

        await emailClient.SendAsync(Azure.WaitUntil.Completed, message);
    }
}
