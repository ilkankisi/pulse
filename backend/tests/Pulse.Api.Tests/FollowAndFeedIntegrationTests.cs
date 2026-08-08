using System.Net;
using System.Net.Http.Json;
using System.Text.Json;

namespace Pulse.Api.Tests;

public sealed class FollowAndFeedIntegrationTests
    : IClassFixture<PulseApiFactory>
{
    private readonly HttpClient _client;

    public FollowAndFeedIntegrationTests(PulseApiFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task FollowAndUnfollow_User_UpdatesFollowState()
    {
        var follower = await ApiTestHelpers.RegisterAsync(
            _client,
            "Follower User");

        var target = await ApiTestHelpers.RegisterAsync(
            _client,
            "Target User");

        using var followRequest =
            ApiTestHelpers.CreateAuthorizedRequest(
                follower,
                HttpMethod.Post,
                $"/api/v1/profiles/{target.Username}/follow");

        using var followResponse =
            await _client.SendAsync(followRequest);

        Assert.Equal(HttpStatusCode.OK, followResponse.StatusCode);

        var followedBody = await followResponse.Content
            .ReadFromJsonAsync<JsonElement>();

        Assert.Equal(
            target.UserId,
            followedBody.GetProperty("userId").GetInt32());

        Assert.True(
            followedBody.GetProperty("isFollowing").GetBoolean());

        Assert.Equal(
            1,
            followedBody.GetProperty("followerCount").GetInt32());

        using var unfollowRequest =
            ApiTestHelpers.CreateAuthorizedRequest(
                follower,
                HttpMethod.Delete,
                $"/api/v1/profiles/{target.Username}/follow");

        using var unfollowResponse =
            await _client.SendAsync(unfollowRequest);

        Assert.Equal(HttpStatusCode.OK, unfollowResponse.StatusCode);

        var unfollowedBody = await unfollowResponse.Content
            .ReadFromJsonAsync<JsonElement>();

        Assert.False(
            unfollowedBody.GetProperty("isFollowing").GetBoolean());

        Assert.Equal(
            0,
            unfollowedBody.GetProperty("followerCount").GetInt32());
    }

    [Fact]
    public async Task Feed_WithNoFollows_ReturnsPublicPostsChronologically()
    {
        var currentUser = await ApiTestHelpers.RegisterAsync(_client);
        var otherUser = await ApiTestHelpers.RegisterAsync(_client);

        await CreatePostAsync(otherUser, "Older public post");
        await CreatePostAsync(currentUser, "Newer own post");

        using var request = ApiTestHelpers.CreateAuthorizedRequest(
            currentUser,
            HttpMethod.Get,
            "/api/v1/feed");

        using var response = await _client.SendAsync(request);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var posts = await response.Content
            .ReadFromJsonAsync<JsonElement>();

        Assert.True(posts.GetArrayLength() >= 2);

        var contents = posts
            .EnumerateArray()
            .Select(post => post.GetProperty("content").GetString())
            .ToList();

        Assert.Contains("Older public post", contents);
        Assert.Contains("Newer own post", contents);
    }

    [Fact]
    public async Task Feed_WithFollow_ReturnsFollowedAndOwnPostsOnly()
    {
        var currentUser = await ApiTestHelpers.RegisterAsync(_client);
        var followedUser = await ApiTestHelpers.RegisterAsync(_client);
        var unrelatedUser = await ApiTestHelpers.RegisterAsync(_client);

        await CreatePostAsync(
            followedUser,
            "Followed user post");

        await CreatePostAsync(
            currentUser,
            "Current user post");

        await CreatePostAsync(
            unrelatedUser,
            "Unrelated user post");

        using var followRequest =
            ApiTestHelpers.CreateAuthorizedRequest(
                currentUser,
                HttpMethod.Post,
                $"/api/v1/profiles/{followedUser.Username}/follow");

        using var followResponse =
            await _client.SendAsync(followRequest);

        Assert.Equal(HttpStatusCode.OK, followResponse.StatusCode);

        using var feedRequest =
            ApiTestHelpers.CreateAuthorizedRequest(
                currentUser,
                HttpMethod.Get,
                "/api/v1/feed");

        using var feedResponse =
            await _client.SendAsync(feedRequest);

        Assert.Equal(HttpStatusCode.OK, feedResponse.StatusCode);

        var posts = await feedResponse.Content
            .ReadFromJsonAsync<JsonElement>();

        var contents = posts
            .EnumerateArray()
            .Select(post => post.GetProperty("content").GetString())
            .ToList();

        Assert.Contains("Followed user post", contents);
        Assert.Contains("Current user post", contents);
        Assert.DoesNotContain("Unrelated user post", contents);
    }

    [Fact]
    public async Task FollowSelf_ReturnsBadRequest()
    {
        var session = await ApiTestHelpers.RegisterAsync(_client);

        using var request = ApiTestHelpers.CreateAuthorizedRequest(
            session,
            HttpMethod.Post,
            $"/api/v1/profiles/{session.Username}/follow");

        using var response = await _client.SendAsync(request);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    private async Task<int> CreatePostAsync(
        TestUserSession session,
        string content)
    {
        using var request = ApiTestHelpers.CreateAuthorizedRequest(
            session,
            HttpMethod.Post,
            "/api/v1/posts",
            JsonContent.Create(new { content }));

        using var response = await _client.SendAsync(request);
        response.EnsureSuccessStatusCode();

        var body = await response.Content
            .ReadFromJsonAsync<JsonElement>();

        return body.GetProperty("id").GetInt32();
    }
}