using System.Text.Json;

namespace Pulse.Api.Tests;

public sealed class SecurityModerationTokenContractTests
{
    private static readonly JsonSerializerOptions JsonOptions =
        new(JsonSerializerDefaults.Web);

    [Theory]
    [InlineData("Pending")]
    [InlineData("Reviewed")]
    [InlineData("ActionTaken")]
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
    public void ModerationToken_IsCanonicalPascalCase(string token)
    {
        Assert.NotEmpty(token);
        Assert.True(
            char.IsUpper(token[0]),
            $"Moderation token '{token}' must use canonical PascalCase.");
    }

    [Theory]
    [InlineData("pending")]
    [InlineData("reviewed")]
    [InlineData("actionTaken")]
    [InlineData("resolved")]
    [InlineData("dismissed")]
    [InlineData("post")]
    [InlineData("user")]
    [InlineData("spam")]
    [InlineData("harassment")]
    [InlineData("hateSpeech")]
    [InlineData("violence")]
    [InlineData("sexualContent")]
    [InlineData("impersonation")]
    [InlineData("other")]
    [InlineData("removePost")]
    [InlineData("noAction")]
    public void ModerationToken_NonCanonicalCasing_IsRejectedByContract(
        string token)
    {
        Assert.False(
            IsCanonicalPascalCaseToken(token),
            $"'{token}' must not be emitted as a canonical moderation token.");
    }

    [Fact]
    public void ReportJson_UsesCamelCasePropertyNamesWithPascalCaseTokenValues()
    {
        var response = new ReportContract(
            Id: 10,
            TargetType: "Post",
            TargetId: 25,
            Reason: "Harassment",
            Status: "Pending",
            ModerationAction: "NoAction",
            Author: new AuthorContract(
                Id: 7,
                Username: "alice"));

        var json = JsonSerializer.Serialize(response, JsonOptions);

        using var document = JsonDocument.Parse(json);
        var root = document.RootElement;

        Assert.Equal(10, root.GetProperty("id").GetInt32());
        Assert.Equal("Post", root.GetProperty("targetType").GetString());
        Assert.Equal(25, root.GetProperty("targetId").GetInt32());
        Assert.Equal("Harassment", root.GetProperty("reason").GetString());
        Assert.Equal("Pending", root.GetProperty("status").GetString());
        Assert.Equal(
            "NoAction",
            root.GetProperty("moderationAction").GetString());

        Assert.True(root.TryGetProperty("author", out var author));
        Assert.Equal(7, author.GetProperty("id").GetInt32());
        Assert.Equal("alice", author.GetProperty("username").GetString());

        Assert.False(root.TryGetProperty("TargetType", out _));
        Assert.False(root.TryGetProperty("TargetId", out _));
        Assert.False(root.TryGetProperty("Reason", out _));
        Assert.False(root.TryGetProperty("Status", out _));
        Assert.False(root.TryGetProperty("ModerationAction", out _));
        Assert.False(root.TryGetProperty("Author", out _));
    }

    private static bool IsCanonicalPascalCaseToken(string token)
    {
        return !string.IsNullOrWhiteSpace(token)
            && char.IsUpper(token[0]);
    }

    private sealed record ReportContract(
        int Id,
        string TargetType,
        int TargetId,
        string Reason,
        string Status,
        string ModerationAction,
        AuthorContract Author);

    private sealed record AuthorContract(
        int Id,
        string Username);
}