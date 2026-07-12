using Azure.Communication.Email;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

var host = new HostBuilder()
    .ConfigureFunctionsWebApplication()
    .ConfigureServices((context, services) =>
    {
        services
            .AddApplicationInsightsTelemetryWorkerService()
            .ConfigureFunctionsApplicationInsights();

        services.AddSingleton(_ =>
        {
            var connectionString = context.Configuration["AcsConnectionString"]
                ?? throw new InvalidOperationException("AcsConnectionString app setting is not configured.");
            return new EmailClient(connectionString);
        });
    })
    .Build();

host.Run();
