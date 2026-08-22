using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Pulse.Api.Data;

namespace Pulse.Api.Tests;

public sealed class PulseApiFactory : WebApplicationFactory<Program>
{
    private readonly string _databaseName =
        $"PulseTests-{Guid.NewGuid():N}";

    protected override void ConfigureWebHost(
        IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");

        builder.ConfigureAppConfiguration(
            (_, configuration) =>
            {
                configuration.AddInMemoryCollection(
                    new Dictionary<string, string?>
                    {
                        ["Jwt:Key"] =
                            "integration-test-key-at-least-32-bytes-long",
                        ["Jwt:Issuer"] = "Pulse.Api",
                        ["Jwt:Audience"] = "Pulse.Client",
                        ["RateLimiting:Register:PermitLimit"] = "1000",
                        ["RateLimiting:Login:PermitLimit"] = "1000"
                    });
            });

        builder.ConfigureServices(
            services =>
            {
                services.RemoveAll<PulseDbContext>();
                services.RemoveAll<DbContextOptions<PulseDbContext>>();

                var optionConfigurationDescriptors = services
                    .Where(
                        descriptor =>
                            IsPulseDbContextOptionsConfiguration(
                                descriptor.ServiceType))
                    .ToList();

                foreach (var descriptor
                         in optionConfigurationDescriptors)
                {
                    services.Remove(descriptor);
                }

                services.AddDbContext<PulseDbContext>(
                    options =>
                        options.UseInMemoryDatabase(_databaseName));
            });
    }

    public new HttpClient CreateClient()
    {
        var client = base.CreateClient();

        ResetDatabase();

        return client;
    }

    private void ResetDatabase()
    {
        using var scope = Services.CreateScope();

        var dbContext =
            scope.ServiceProvider
                .GetRequiredService<PulseDbContext>();

        dbContext.Database.EnsureDeleted();
        dbContext.Database.EnsureCreated();
    }

    private static bool IsPulseDbContextOptionsConfiguration(
        Type serviceType)
    {
        if (!serviceType.IsGenericType)
        {
            return false;
        }

        var genericTypeDefinition =
            serviceType.GetGenericTypeDefinition();

        return genericTypeDefinition.FullName
                == "Microsoft.EntityFrameworkCore.Infrastructure."
                + "IDbContextOptionsConfiguration`1"
            && serviceType.GenericTypeArguments.Length == 1
            && serviceType.GenericTypeArguments[0]
                == typeof(PulseDbContext);
    }
}