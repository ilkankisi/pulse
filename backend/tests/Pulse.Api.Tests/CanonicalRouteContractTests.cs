using System;
using System.Collections.Generic;
using System.Linq;

using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.DependencyInjection;

using Xunit;

namespace Pulse.Api.Tests;

public sealed class CanonicalRouteContractTests
{
    [Fact]
    public void Backend_routes_include_canonical_contract()
    {
        using var factory =
            new CanonicalRouteWebApplicationFactory();

        using var scope =
            factory.Services.CreateScope();

        var actualRoutes = scope.ServiceProvider
            .GetServices<EndpointDataSource>()
            .SelectMany(source => source.Endpoints)
            .OfType<RouteEndpoint>()
            .SelectMany(
                endpoint =>
                {
                    var methods = endpoint.Metadata
                        .GetMetadata<HttpMethodMetadata>()
                        ?.HttpMethods;

                    if (methods is null)
                    {
                        return Array.Empty<string>();
                    }

                    var route = NormalizeRoute(
                        endpoint.RoutePattern.RawText
                        ?? endpoint.RoutePattern.ToString());

                    return methods.Select(
                        method => RouteKey(method, route));
                })
            .ToHashSet(StringComparer.OrdinalIgnoreCase);

        var expectedRoutes = new[]
        {
            RouteKey("GET", "/health"),
            RouteKey("POST", "/api/v1/auth/register"),
            RouteKey("POST", "/api/v1/auth/login"),
            RouteKey("GET", "/api/v1/feed"),
            RouteKey(
                "GET",
                $"/api/v1/posts/{Parameter("postId")}"),
            RouteKey("POST", "/api/v1/posts"),
            RouteKey(
                "DELETE",
                $"/api/v1/posts/{Parameter("postId")}"),
            RouteKey(
                "GET",
                $"/api/v1/posts/{Parameter("postId")}/replies"),
            RouteKey(
                "POST",
                $"/api/v1/posts/{Parameter("postId")}/replies"),
            RouteKey(
                "POST",
                $"/api/v1/posts/{Parameter("postId")}/likes"),
            RouteKey(
                "DELETE",
                $"/api/v1/posts/{Parameter("postId")}/likes"),
            RouteKey(
                "POST",
                $"/api/v1/posts/{Parameter("postId")}/reposts"),
            RouteKey(
                "DELETE",
                $"/api/v1/posts/{Parameter("postId")}/reposts"),
            RouteKey(
                "POST",
                $"/api/v1/posts/{Parameter("postId")}/quotes"),
            RouteKey(
                "POST",
                $"/api/v1/posts/{Parameter("postId")}/bookmarks"),
            RouteKey(
                "DELETE",
                $"/api/v1/posts/{Parameter("postId")}/bookmarks"),
            RouteKey("GET", "/api/v1/bookmarks"),
            RouteKey("GET", "/api/v1/notifications"),
            RouteKey(
                "PUT",
                $"/api/v1/notifications/"
                + $"{Parameter("notificationId")}/read"),
            RouteKey(
                "GET",
                $"/api/v1/hashtags/{Parameter("tag")}/posts"),
            RouteKey("POST", "/api/v1/media"),
            RouteKey(
                "POST",
                $"/api/v1/profiles/{Parameter("username")}/follow"),
            RouteKey(
                "DELETE",
                $"/api/v1/profiles/{Parameter("username")}/follow"),
            RouteKey(
                "DELETE",
                $"/api/v1/profiles/{Parameter("username")}/followers/"
                + Parameter("followerId"))
        };

        var missingRoutes = expectedRoutes
            .Where(route => !actualRoutes.Contains(route))
            .OrderBy(route => route, StringComparer.Ordinal)
            .ToArray();

        Assert.True(
            missingRoutes.Length == 0,
            "Missing canonical backend routes:"
            + Environment.NewLine
            + string.Join(
                Environment.NewLine,
                missingRoutes));
    }

    private static string RouteKey(
        string method,
        string route)
    {
        return string.Concat(
            method.ToUpperInvariant(),
            " ",
            NormalizeRoute(route));
    }

    private static string Parameter(
        string name)
    {
        return string.Concat(
            Convert.ToChar(123),
            name,
            Convert.ToChar(125));
    }

    private static string NormalizeRoute(
        string route)
    {
        var normalized =
            route.StartsWith(
                "/",
                StringComparison.Ordinal)
                ? route
                : string.Concat(
                    "/",
                    route);

        if (normalized.Length > 1)
        {
            normalized = normalized.TrimEnd('/');
        }

        var segments = normalized.Split('/');

        for (var index = 0; index < segments.Length; index++)
        {
            var segment = segments[index];

            if (segment.Length < 3
                || segment[0] != Convert.ToChar(123)
                || segment[^1] != Convert.ToChar(125))
            {
                continue;
            }

            var colonIndex = segment.IndexOf(
                ':',
                StringComparison.Ordinal);

            if (colonIndex <= 1)
            {
                continue;
            }

            segments[index] =
                segment[..colonIndex]
                + Convert.ToChar(125);
        }

        return string.Join(
            "/",
            segments);
    }

    private sealed class CanonicalRouteWebApplicationFactory
        : WebApplicationFactory<Program>
    {
        protected override void ConfigureWebHost(
            IWebHostBuilder builder)
        {
            builder.UseEnvironment("Testing");
        }
    }
}