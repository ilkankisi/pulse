using System.Text.Json;

using Xunit;

namespace Pulse.Api.IntegrationTests;

public sealed class AuthEndpointsTests

{

[Fact]

public void Login_request_body_uses_canonical_login_field()

{

var request = new

{

login = "ilkan",

password = "Password123!"

};

    var json = JsonSerializer.Serialize(request);

    using var document = JsonDocument.Parse(json);
    var root = document.RootElement;

    Assert.True(root.TryGetProperty("login", out var login));
    Assert.Equal("ilkan", login.GetString());

    Assert.True(root.TryGetProperty("password", out var password));
    Assert.Equal("Password123!", password.GetString());

    Assert.False(root.TryGetProperty("username", out _));
}

[Fact]
public void Login_request_body_example_matches_backend_contract()
{
    const string json =
        """
        {
          "login": "ilkan",
          "password": "Password123!"
        }
        """;

    using var document = JsonDocument.Parse(json);
    var root = document.RootElement;

    Assert.Equal(2, root.EnumerateObject().Count());
    Assert.Equal("ilkan", root.GetProperty("login").GetString());
    Assert.Equal(
        "Password123!",
        root.GetProperty("password").GetString());
}

}