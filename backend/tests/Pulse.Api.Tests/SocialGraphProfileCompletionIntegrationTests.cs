using System.Net;
using System.Net.Http.Json;
using System.Text.Json;

namespace Pulse.Api.Tests;

public sealed class SocialGraphProfileCompletionIntegrationTests
    : IClassFixture<PulseApiFactory>
{
    private readonly HttpClient _client;

    public SocialGraphProfileCompletionIntegrationTests(
        PulseApiFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task Profile_ReturnsCanonicalCountsAndFollowState()
    {
        var viewer = await ApiTestHelpers.RegisterAsync(
            _client,
            "Profile Viewer");

        var target = await ApiTestHelpers.RegisterAsync(
            _client,
            "Profile Target");

        using (var followRequest =
               ApiTestHelpers.CreateAuthorizedRequest(
                   viewer,
                   HttpMethod.Post,
                   $"/api/v1/profiles/{target.Username}/follow"))
        using (var followResponse =
               await _client.SendAsync(followRequest))
        {
            followResponse.EnsureSuccessStatusCode();
        }

        int rootPostId;

        using (var createPostRequest =
               ApiTestHelpers.CreateAuthorizedRequest(
                   target,
                   HttpMethod.Post,
                   "/api/v1/posts"))
        {
            createPostRequest.Content =
                JsonContent.Create(
                    new
                    {
                        content = "Visible root post",
                    });

            using var createPostResponse =
                await _client.SendAsync(createPostRequest);

            createPostResponse.EnsureSuccessStatusCode();

            var createPostBody =
                await createPostResponse.Content
                    .ReadFromJsonAsync<JsonElement>();

            rootPostId =
                createPostBody
                    .GetProperty("id")
                    .GetInt32();
        }

        using (var createReplyRequest =
               ApiTestHelpers.CreateAuthorizedRequest(
                   target,
                   HttpMethod.Post,
                   $"/api/v1/posts/{rootPostId}/replies"))
        {
            createReplyRequest.Content =
                JsonContent.Create(
                    new
                    {
                        content =
                            "Reply is not part of postCount",
                    });

            using var createReplyResponse =
                await _client.SendAsync(createReplyRequest);

            createReplyResponse.EnsureSuccessStatusCode();
        }

        using var request =
            ApiTestHelpers.CreateAuthorizedRequest(
                viewer,
                HttpMethod.Get,
                $"/api/v1/profiles/{target.Username}");

        using var response =
            await _client.SendAsync(request);

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var body =
            await response.Content
                .ReadFromJsonAsync<JsonElement>();

        Assert.Equal(
            target.Username,
            body
                .GetProperty("username")
                .GetString());

        Assert.True(
            body
                .GetProperty(
                    "isFollowedByCurrentUser")
                .GetBoolean());

        Assert.Equal(
            1,
            body
                .GetProperty("followerCount")
                .GetInt32());

        Assert.Equal(
            1,
            body
                .GetProperty("postCount")
                .GetInt32());
    }

    [Fact]
    public async Task ProfilePosts_ReturnOnlyRootPosts()
    {
        var viewer = await ApiTestHelpers.RegisterAsync(
            _client,
            "Posts Viewer");

        var target = await ApiTestHelpers.RegisterAsync(
            _client,
            "Posts Target");

        int rootPostId;

        using (var createPostRequest =
               ApiTestHelpers.CreateAuthorizedRequest(
                   target,
                   HttpMethod.Post,
                   "/api/v1/posts"))
        {
            createPostRequest.Content =
                JsonContent.Create(
                    new
                    {
                        content = "Canonical root post",
                    });

            using var createPostResponse =
                await _client.SendAsync(createPostRequest);

            createPostResponse.EnsureSuccessStatusCode();

            var createPostBody =
                await createPostResponse.Content
                    .ReadFromJsonAsync<JsonElement>();

            rootPostId =
                createPostBody
                    .GetProperty("id")
                    .GetInt32();
        }

        using (var createReplyRequest =
               ApiTestHelpers.CreateAuthorizedRequest(
                   target,
                   HttpMethod.Post,
                   $"/api/v1/posts/{rootPostId}/replies"))
        {
            createReplyRequest.Content =
                JsonContent.Create(
                    new
                    {
                        content =
                            "Nested reply must not be listed",
                    });

            using var createReplyResponse =
                await _client.SendAsync(createReplyRequest);

            createReplyResponse.EnsureSuccessStatusCode();
        }

        using var request =
            ApiTestHelpers.CreateAuthorizedRequest(
                viewer,
                HttpMethod.Get,
                $"/api/v1/profiles/{target.Username}/posts");

        using var response =
            await _client.SendAsync(request);

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var body =
            await response.Content
                .ReadFromJsonAsync<JsonElement>();

        var items =
            body
                .GetProperty("items")
                .EnumerateArray()
                .ToArray();

        Assert.Single(items);

        Assert.Equal(
            rootPostId,
            items[0]
                .GetProperty("id")
                .GetInt32());

        Assert.Equal(
            "Canonical root post",
            items[0]
                .GetProperty("content")
                .GetString());
    }
}