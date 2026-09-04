using System.Net;

using System.Net.Http.Headers;

using System.Net.Http.Json;

using System.Text.Json;

namespace Pulse.Api.Tests;

public sealed class AuthIntegrationTests

: IClassFixture<PulseApiFactory>

{

private readonly HttpClient _client;

public AuthIntegrationTests(PulseApiFactory factory)
{
    _client = factory.CreateClient();
}

[Fact]
public async Task Register_WithoutToken_CreatesUserAndReturnsJwt()
{
    var uniqueValue = Guid.NewGuid().ToString("N");
    var username = $"user_{uniqueValue[..12]}";

    var response = await _client.PostAsJsonAsync(
        "/api/v1/auth/register",
        new
        {
            username,
            displayName = "Pulse User",
            password = "StrongPassword123!"
        });

    Assert.Equal(HttpStatusCode.Created, response.StatusCode);

    var body = await response.Content
        .ReadFromJsonAsync<JsonElement>();

    Assert.False(
        string.IsNullOrWhiteSpace(
            body.GetProperty("accessToken").GetString()));

    Assert.Equal(
        "Bearer",
        body.GetProperty("tokenType").GetString());

    Assert.Equal(
        username,
        body.GetProperty("user")
            .GetProperty("username")
            .GetString());

    Assert.Equal(
        "Pulse User",
        body.GetProperty("user")
            .GetProperty("displayName")
            .GetString());
}

[Fact]
public async Task Login_WithValidCredentials_ReturnsJwt()
{
    var uniqueValue = Guid.NewGuid().ToString("N");
    var username = $"user_{uniqueValue[..12]}";
    const string password = "StrongPassword123!";

    var registerResponse = await _client.PostAsJsonAsync(
        "/api/v1/auth/register",
        new
        {
            username,
            displayName = "Login User",
            password
        });

    Assert.Equal(
        HttpStatusCode.Created,
        registerResponse.StatusCode);

    var loginResponse = await _client.PostAsJsonAsync(
        "/api/v1/auth/login",
        new
        {
            username,
            password
        });

    Assert.Equal(HttpStatusCode.OK, loginResponse.StatusCode);

    var body = await loginResponse.Content
        .ReadFromJsonAsync<JsonElement>();

    Assert.False(
        string.IsNullOrWhiteSpace(
            body.GetProperty("accessToken").GetString()));

    Assert.Equal(
        username,
        body.GetProperty("user")
            .GetProperty("username")
            .GetString());
}

[Fact]
public async Task Login_WithInvalidPassword_ReturnsUnauthorized()
{
    var uniqueValue = Guid.NewGuid().ToString("N");
    var username = $"user_{uniqueValue[..12]}";

    var registerResponse = await _client.PostAsJsonAsync(
        "/api/v1/auth/register",
        new
        {
            username,
            displayName = "Invalid Login User",
            password = "StrongPassword123!"
        });

    Assert.Equal(
        HttpStatusCode.Created,
        registerResponse.StatusCode);

    var loginResponse = await _client.PostAsJsonAsync(
        "/api/v1/auth/login",
        new
        {
            username,
            password = "IncorrectPassword123!"
        });

    Assert.Equal(
        HttpStatusCode.Unauthorized,
        loginResponse.StatusCode);
}

}

internal static class ApiTestHelpers

{

public static async Task<TestUserSession> RegisterAsync(

HttpClient client,

string? displayName = null)

{

var uniqueValue = Guid.NewGuid().ToString("N");

var username = $"user_{uniqueValue[..12]}";

var resolvedDisplayName = displayName ?? "Test User";

    var response = await client.PostAsJsonAsync(
        "/api/v1/auth/register",
        new
        {
            username,
            displayName = resolvedDisplayName,
            password = "StrongPassword123!"
        });

    response.EnsureSuccessStatusCode();

    var body = await response.Content
        .ReadFromJsonAsync<JsonElement>();

    return new TestUserSession(
        body.GetProperty("user").GetProperty("id").GetInt32(),
        username,
        $"{username}@pulse.local",
        body.GetProperty("accessToken").GetString()
            ?? throw new InvalidOperationException(
                "Registration did not return an access token."));
}

public static HttpRequestMessage CreateAuthorizedRequest(
    TestUserSession session,
    HttpMethod method,
    string requestUri,
    HttpContent? content = null)
{
    var request = new HttpRequestMessage(method, requestUri)
    {
        Content = content
    };

    request.Headers.Authorization =
        new AuthenticationHeaderValue(
            "Bearer",
            session.AccessToken);

    return request;
}

}

internal sealed record TestUserSession(

int UserId,

string Username,

string Email,

string AccessToken);