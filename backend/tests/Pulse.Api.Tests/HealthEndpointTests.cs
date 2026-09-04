using System.Net;

using System.Net.Http.Json;

using Microsoft.AspNetCore.Hosting;

using Microsoft.AspNetCore.Mvc.Testing;

namespace Pulse.Api.Tests;

public sealed class HealthEndpointTests

: IClassFixture<WebApplicationFactory<Program>>

{

private readonly HttpClient _client;

public HealthEndpointTests(

WebApplicationFactory<Program> factory)

{

_client =

factory

.WithWebHostBuilder(

builder =>

{

builder.UseEnvironment("Testing");

})

.CreateClient();

}

[Fact]

public async Task GetHealth_WithoutToken_ReturnsOkStatus()

{

using var response =

await _client.GetAsync("/health");

Assert.Equal(
    HttpStatusCode.OK,
    response.StatusCode);

var payload =
    await response.Content.ReadFromJsonAsync<HealthResponse>();

Assert.NotNull(payload);
Assert.Equal(
    "ok",
    payload.Status);

}

private sealed record HealthResponse(

string Status);

}