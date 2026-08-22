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

using var factory = new TestFactory();

using var scope = factory.Services.CreateScope();

    var source =
        scope.ServiceProvider.GetRequiredService<EndpointDataSource>();

    var actual = new HashSet<string>(StringComparer.Ordinal);

    foreach (var endpoint in source.Endpoints.OfType<RouteEndpoint>())
    {
        var methods =
            endpoint.Metadata.GetMetadata<HttpMethodMetadata>()?.HttpMethods;

        if (methods is null)
        {
            continue;
        }

        var path = Normalize(endpoint.RoutePattern.RawText ?? string.Empty);

        foreach (var method in methods)
        {
            var route = method.ToUpperInvariant() + " " + path;

            if (route == "GET /health"
                || route.Contains(" /api/v1/", StringComparison.Ordinal))
            {
                actual.Add(route);
            }
        }
    }

    var u = Parameter("username");
    var p = Parameter("postId");
    var r = Parameter("reportId");

    var expected = new HashSet<string>(
        new[]
        {
            "GET /health",
            "POST /api/v1/auth/register",
            "POST /api/v1/auth/login",
            "GET /api/v1/me",
            "PUT /api/v1/me",
            "GET /api/v1/profiles/" + u,
            "GET /api/v1/profiles/" + u + "/followers",
            "GET /api/v1/profiles/" + u + "/following",
            "GET /api/v1/profiles/" + u + "/posts",
            "POST /api/v1/profiles/" + u + "/follow",
            "DELETE /api/v1/profiles/" + u + "/follow",
            "GET /api/v1/feed",
            "POST /api/v1/posts",
            "DELETE /api/v1/posts/" + p,
            "POST /api/v1/posts/" + p + "/replies",
            "POST /api/v1/posts/" + p + "/likes",
            "DELETE /api/v1/posts/" + p + "/likes",
            "POST /api/v1/profiles/" + u + "/block",
            "DELETE /api/v1/profiles/" + u + "/block",
            "GET /api/v1/blocks",
            "POST /api/v1/reports",
            "GET /api/v1/moderation/reports",
            "GET /api/v1/moderation/reports/" + r,
            "POST /api/v1/moderation/reports/" + r + "/resolve",
            "POST /api/v1/moderation/reports/" + r + "/dismiss"
        },
        StringComparer.Ordinal);

    Assert.Equal(
        expected.OrderBy(x => x),
        actual.OrderBy(x => x));
}

private static string Normalize(string route)
{
    var value =
        route.StartsWith("/", StringComparison.Ordinal)
            ? route
            : "/" + route;

    value = value.Replace(
        Parameter("postId", "int"),
        Parameter("postId"),
        StringComparison.Ordinal);

    value = value.Replace(
        Parameter("reportId", "int"),
        Parameter("reportId"),
        StringComparison.Ordinal);

    return value.Length > 1 ? value.TrimEnd('/') : value;
}

private static string Parameter(string name)
{
    return string.Concat(
        Convert.ToChar(123),
        name,
        Convert.ToChar(125));
}

private static string Parameter(string name, string constraint)
{
    return string.Concat(
        Convert.ToChar(123),
        name,
        ":",
        constraint,
        Convert.ToChar(125));
}

private sealed class TestFactory : WebApplicationFactory<Program>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");
    }
}

}