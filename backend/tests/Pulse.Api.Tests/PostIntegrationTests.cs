using System.Net;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;

namespace Pulse.Api.Tests;

public sealed class PostIntegrationTests
    : IClassFixture<PulseApiFactory>
{
    private readonly HttpClient _client;

    public PostIntegrationTests(PulseApiFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task CreatePost_WithValidToken_ReturnsCreatedPost()
    {
        var session = await ApiTestHelpers.RegisterAsync(_client);

        using var request = ApiTestHelpers.CreateAuthorizedRequest(
            session,
            HttpMethod.Post,
            "/api/v1/posts",
            JsonContent.Create(new
            {
                content = "Pulse üzerindeki ilk gönderim."
            }));

        using var response = await _client.SendAsync(request);

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);

        var body = await response.Content
            .ReadFromJsonAsync<JsonElement>();

        Assert.Equal(
            "Pulse üzerindeki ilk gönderim.",
            body.GetProperty("content").GetString());

        Assert.Equal(
            session.UserId,
            body.GetProperty("author")
                .GetProperty("id")
                .GetInt32());

        Assert.Equal(
            0,
            body.GetProperty("likeCount").GetInt32());

        Assert.Equal(
            0,
            body.GetProperty("replyCount").GetInt32());

        Assert.False(
            body.GetProperty("isLikedByCurrentUser").GetBoolean());
    }

    [Fact]
    public async Task CreatePost_WithMoreThan280Characters_ReturnsBadRequest()
    {
        var session = await ApiTestHelpers.RegisterAsync(_client);

        using var request = ApiTestHelpers.CreateAuthorizedRequest(
            session,
            HttpMethod.Post,
            "/api/v1/posts",
            JsonContent.Create(new
            {
                content = new string('a', 281)
            }));

        using var response = await _client.SendAsync(request);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);

        var body = await response.Content
            .ReadFromJsonAsync<JsonElement>();

        Assert.Equal(
            "content",
            body.GetProperty("field").GetString());
    }

    [Fact]
    public async Task DeletePost_ByAnotherUser_ReturnsForbidden()
    {
        var author = await ApiTestHelpers.RegisterAsync(
            _client,
            "Post Author");

        var otherUser = await ApiTestHelpers.RegisterAsync(
            _client,
            "Other User");

        var postId = await CreatePostAsync(
            author,
            "Only the author may delete this.");

        using var request = ApiTestHelpers.CreateAuthorizedRequest(
            otherUser,
            HttpMethod.Delete,
            $"/api/v1/posts/{postId}");

        using var response = await _client.SendAsync(request);

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Reply_ToReply_ReturnsBadRequest()
    {
        var session = await ApiTestHelpers.RegisterAsync(_client);

        var parentPostId = await CreatePostAsync(
            session,
            "Parent post");

        var replyId = await CreateReplyAsync(
            session,
            parentPostId,
            "First-level reply");

        using var request = ApiTestHelpers.CreateAuthorizedRequest(
            session,
            HttpMethod.Post,
            $"/api/v1/posts/{replyId}/replies",
            JsonContent.Create(new
            {
                content = "Nested reply"
            }));

        using var response = await _client.SendAsync(request);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);

        var body = await response.Content
            .ReadFromJsonAsync<JsonElement>();

        Assert.Equal(
            "parentPostId",
            body.GetProperty("field").GetString());
    }

    [Fact]
    public async Task LikeAndUnlikePost_UpdatesLikeState()
    {
        var author = await ApiTestHelpers.RegisterAsync(_client);
        var liker = await ApiTestHelpers.RegisterAsync(_client);

        var postId = await CreatePostAsync(
            author,
            "Likeable post");

        using var likeRequest = ApiTestHelpers.CreateAuthorizedRequest(
            liker,
            HttpMethod.Post,
            $"/api/v1/posts/{postId}/likes");

        using var likeResponse = await _client.SendAsync(likeRequest);

        Assert.Equal(HttpStatusCode.OK, likeResponse.StatusCode);

        var likedBody = await likeResponse.Content
            .ReadFromJsonAsync<JsonElement>();

        Assert.True(
            likedBody.GetProperty("isLiked").GetBoolean());

        Assert.Equal(
            1,
            likedBody.GetProperty("likeCount").GetInt32());

        using var unlikeRequest = ApiTestHelpers.CreateAuthorizedRequest(
            liker,
            HttpMethod.Delete,
            $"/api/v1/posts/{postId}/likes");

        using var unlikeResponse = await _client.SendAsync(unlikeRequest);

        Assert.Equal(HttpStatusCode.OK, unlikeResponse.StatusCode);

        var unlikedBody = await unlikeResponse.Content
            .ReadFromJsonAsync<JsonElement>();

        Assert.False(
            unlikedBody.GetProperty("isLiked").GetBoolean());

        Assert.Equal(
            0,
            unlikedBody.GetProperty("likeCount").GetInt32());
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

    private async Task<int> CreateReplyAsync(
        TestUserSession session,
        int parentPostId,
        string content)
    {
        using var request = ApiTestHelpers.CreateAuthorizedRequest(
            session,
            HttpMethod.Post,
            $"/api/v1/posts/{parentPostId}/replies",
            new StringContent(
                JsonSerializer.Serialize(new { content }),
                Encoding.UTF8,
                "application/json"));

        using var response = await _client.SendAsync(request);
        response.EnsureSuccessStatusCode();

        var body = await response.Content
            .ReadFromJsonAsync<JsonElement>();

        return body.GetProperty("id").GetInt32();
    }
}