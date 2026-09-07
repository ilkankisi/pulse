using System.Net;

using System.Net.Http.Json;

using System.Text.Json;

namespace Pulse.Api.Tests;

public sealed class HealthEndpointTests

: IClassFixture<PulseApiFactory>

{

private readonly HttpClient _client;

public HealthEndpointTests(PulseApiFactory factory)
{
    _client = factory.CreateClient();
}

[Fact]
public async Task GetHealth_WithoutToken_ReturnsOkStatus()
{
    var response =
        await _client.GetAsync("/health");

    Assert.Equal(
        HttpStatusCode.OK,
        response.StatusCode);

    var body =
        await response.Content
            .ReadFromJsonAsync<JsonElement>();

    Assert.Equal(
        "ok",
        body.GetProperty("status").GetString());
}

}