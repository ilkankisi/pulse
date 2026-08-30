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

public void Backend_routes_match_canonical_contract()

{

using var factory =

new CanonicalRouteWebApplicationFactory();

    using var scope =
}

private static string Parameter(
    string name)
{
    return string.Concat(
        Convert.ToChar(123),
        name,
        Convert.ToChar(125));
}

private static string ParameterWithConstraint(
    string name,
    string constraint)
{
    return string.Concat(
        Convert.ToChar(123),
        name,
        ":",
        constraint,
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
        return normalized.TrimEnd('/');
    }

    return normalized;
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

}