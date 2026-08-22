using System.Net;
using System.Net.Http.Headers;

namespace Pulse.Api.Tests;

public sealed class CorsIntegrationTests
    : IClassFixture<PulseApiFactory>
{
    private const string AllowedOrigin =
        "http://127.0.0.1:8080";

    private readonly HttpClient _client;

    public CorsIntegrationTests(PulseApiFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task GetApiEndpoint_FromAllowedOrigin_ReturnsCorsHeader()
    {
        using var request = new HttpRequestMessage(
            HttpMethod.Get,
            "/api/v1/feed");

        request.Headers.Add("Origin", AllowedOrigin);

        using var response = await _client.SendAsync(request);

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            response.StatusCode);

        Assert.True(
            response.Headers.TryGetValues(
                "Access-Control-Allow-Origin",
                out var origins));

        Assert.Contains(AllowedOrigin, origins);
    }

    [Fact]
    public async Task OptionsPreflight_FromAllowedOrigin_ReturnsNoContent()
    {
        using var request = new HttpRequestMessage(
            HttpMethod.Options,
            "/api/v1/feed");

        request.Headers.Add("Origin", AllowedOrigin);
        request.Headers.Add(
            "Access-Control-Request-Method",
            HttpMethod.Get.Method);
        request.Headers.Add(
            "Access-Control-Request-Headers",
            "authorization,content-type");

        using var response = await _client.SendAsync(request);

        Assert.Equal(
            HttpStatusCode.NoContent,
            response.StatusCode);

        Assert.True(
            response.Headers.TryGetValues(
                "Access-Control-Allow-Origin",
                out var origins));

        Assert.Contains(AllowedOrigin, origins);

        Assert.True(
            response.Headers.TryGetValues(
                "Access-Control-Allow-Methods",
                out var allowedMethods));

        Assert.Contains(
            HttpMethod.Get.Method,
            string.Join(",", allowedMethods),
            StringComparison.OrdinalIgnoreCase);
    }
}