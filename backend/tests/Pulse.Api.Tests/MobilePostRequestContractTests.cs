using System.Net;
using System.Text;
using System.Text.Json;

namespace Pulse.Api.Tests;

public sealed class MobilePostRequestContractTests
    : IClassFixture<PulseApiFactory>
{
    private readonly HttpClient _client;

    public MobilePostRequestContractTests(PulseApiFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task CreatePost_WithMobileCanonicalJson_UsesContentFieldForMention()
    {
        var session = await ApiTestHelpers.RegisterAsync(_client);

        using var request = ApiTestHelpers.CreateAuthorizedRequest(
            session,
            HttpMethod.Post,
            "/api/v1/posts",
            new StringContent(
                """{"content":"Merhaba @ilkan"}""",
                Encoding.UTF8,
                "application/json"));

        using var response = await _client.SendAsync(request);

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);

        var json = await response.Content.ReadAsStringAsync();
        using var document = JsonDocument.Parse(json);

        Assert.Equal(
            "Merhaba @ilkan",
            document.RootElement
                .GetProperty("content")
                .GetString());
    }
}