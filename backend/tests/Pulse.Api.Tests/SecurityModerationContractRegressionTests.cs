using System.Text.Json;

namespace Pulse.Api.Tests;

public sealed class SecurityModerationContractRegressionTests
{
    private static readonly JsonSerializerOptions JsonOptions =
        new(JsonSerializerDefaults.Web);

    [Theory]
    [InlineData("Pending")]
    [InlineData("Resolved")]
    [InlineData("Dismissed")]
    [InlineData("Post")]
    [InlineData("User")]
    [InlineData("Spam")]
    [InlineData("Harassment")]
    [InlineData("HateSpeech")]
    [InlineData("Violence")]
    [InlineData("SexualContent")]
    [InlineData("Impersonation")]
    [InlineData("Other")]
    [InlineData("RemovePost")]
    [InlineData("NoAction")]
    public void CanonicalSecurityModerationToken_IsPascalCase(string token)
    {
        Assert.NotEmpty(token);
        Assert.True(
            char.IsUpper(token[0]),
            $"Canonical token '{token}' must start with an uppercase character.");
    }

    [Fact]
    public void ReportContract_SerializesCamelCasePropertiesAndPascalCaseTokens()
    {
        var request = new ReportContract(
            TargetType: "Post",
            TargetId: 42,
            Reason: "Spam",
            Details: "Repeated unsolicited content.");

        var json = JsonSerializer.Serialize(request, JsonOptions);

        using var document = JsonDocument.Parse(json);
        var root = document.RootElement;

        Assert.Equal("Post", root.GetProperty("targetType").GetString());
        Assert.Equal(42, root.GetProperty("targetId").GetInt32());
        Assert.Equal("Spam", root.GetProperty("reason").GetString());
        Assert.Equal(
            "Repeated unsolicited content.",
            root.GetProperty("details").GetString());

        Assert.False(root.TryGetProperty("TargetType", out _));
        Assert.False(root.TryGetProperty("TargetId", out _));
        Assert.False(root.TryGetProperty("Reason", out _));
        Assert.False(root.TryGetProperty("Details", out _));
    }

    [Fact]
    public void AuthorProperty_RemainsCanonicalCamelCase()
    {
        var response = new AuthorEnvelope(
            Author: new AuthorContract(
                Id: 7,
                Username: "alice"));

        var json = JsonSerializer.Serialize(response, JsonOptions);

        using var document = JsonDocument.Parse(json);
        var root = document.RootElement;

        Assert.True(root.TryGetProperty("author", out var author));
        Assert.False(root.TryGetProperty("Author", out _));

        Assert.Equal(7, author.GetProperty("id").GetInt32());
        Assert.Equal("alice", author.GetProperty("username").GetString());
        Assert.False(author.TryGetProperty("Id", out _));
        Assert.False(author.TryGetProperty("Username", out _));
    }

    private sealed record ReportContract(
        string TargetType,
        int TargetId,
        string Reason,
        string? Details);

    private sealed record AuthorEnvelope(AuthorContract Author);

    private sealed record AuthorContract(
        int Id,
        string Username);
}