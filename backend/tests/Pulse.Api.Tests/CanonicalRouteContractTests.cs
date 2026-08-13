using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Pulse.Api.Tests;

public sealed class CanonicalRouteContractTests
{
    [Fact]
    public void Backend_routes_match_canonical_contract()
    {
        using var factory =
            new CanonicalRouteWebApplicationFactory();

        using var scope =
            factory.Services.CreateScope();

        var endpointDataSource =
            scope.ServiceProvider
                .GetRequiredService<EndpointDataSource>();

        var actualRoutes =
            endpointDataSource.Endpoints
                .OfType<RouteEndpoint>()
                .Select(
                    endpoint =>
                    {
                        var httpMethods =
                            endpoint.Metadata
                                .GetMetadata<HttpMethodMetadata>()?
                                .HttpMethods;

                        return new
                        {
                            Methods =
                                httpMethods
                                ?? Array.Empty<string>(),
                            Path =
                                NormalizeRoute(
                                    Regex.Replace(
                                        endpoint.RoutePattern.RawText
                                        ?? string.Empty,
                                        @"\{([^}:]+):[^}]+\}",
                                        "{$1}"))
                        };
                    })
                .SelectMany(
                    endpoint =>
                        endpoint.Methods.Select(
                            method =>
                                $"{method.ToUpperInvariant()} {endpoint.Path}"))
                .Where(
                    route =>
                        route.StartsWith(
                            "GET /health",
                            StringComparison.Ordinal)
                        || route.Contains(
                            " /api/v1/",
                            StringComparison.Ordinal))
                .ToHashSet(
                    StringComparer.Ordinal);

        var expectedRoutes =
            new HashSet<string>(
                StringComparer.Ordinal)
            {
                "GET /health",
                "POST /api/v1/auth/register",
                "POST /api/v1/auth/login",
                "GET /api/v1/me",
                "PUT /api/v1/me",
                "GET /api/v1/profiles/{username}",
                "GET /api/v1/profiles/{username}/followers",
                "GET /api/v1/profiles/{username}/following",
                "GET /api/v1/profiles/{username}/posts",
                "POST /api/v1/profiles/{username}/follow",
                "DELETE /api/v1/profiles/{username}/follow",
                "GET /api/v1/feed",
                "POST /api/v1/posts",
                "DELETE /api/v1/posts/{postId}",
                "POST /api/v1/posts/{postId}/replies",
                "POST /api/v1/posts/{postId}/likes",
                "DELETE /api/v1/posts/{postId}/likes",
                "POST /api/v1/profiles/{username}/block",
                "DELETE /api/v1/profiles/{username}/block",
                "GET /api/v1/blocks",
                "POST /api/v1/reports",
                "GET /api/v1/moderation/reports",
                "GET /api/v1/moderation/reports/{reportId}",
                "POST /api/v1/moderation/reports/{reportId}/resolve",
                "POST /api/v1/moderation/reports/{reportId}/dismiss"
            };

        Assert.Equal(
            expectedRoutes.OrderBy(
                route => route),
            actualRoutes.OrderBy(
                route => route));
    }

    private sealed class CanonicalRouteWebApplicationFactory
        : WebApplicationFactory<Program>
    {
        protected override void ConfigureWebHost(
            IWebHostBuilder builder)
        {
            builder.UseEnvironment(
                "Testing");
        }
    }

    private static string NormalizeRoute(
        string route)
    {
        var normalized =
            route.StartsWith(
                "/",
                StringComparison.Ordinal)
                ? route
                : $"/{route}";

        return normalized.Length > 1
            ? normalized.TrimEnd('/')
            : normalized;
    }
}