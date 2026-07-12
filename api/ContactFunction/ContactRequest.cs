namespace ContactFunction;

/// <summary>
/// Mirrors the JSON body posted by assets/js/contact-form.js in the matpadley.github.io repo.
/// Company and RenderedAt are the honeypot/timing anti-bot signals - see ContactFunction.cs.
/// </summary>
public record ContactRequest(
    string? Name,
    string? Email,
    string? Message,
    string? Company,
    string? RenderedAt);
