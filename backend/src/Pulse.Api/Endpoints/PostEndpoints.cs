using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using Pulse.Api.Contracts;
using Pulse.Api.Data;
using Pulse.Api.Domain;

namespace Pulse.Api.Endpoints;

public static partial class PostEndpoints
{
    public static bool TryGetUserId(
        ClaimsPrincipal principal,
        out int userId)
    {
        var claim =
            principal.FindFirst(ClaimTypes.NameIdentifier)
            ?? principal.FindFirst(JwtRegisteredClaimNames.Sub);

        return int.TryParse(claim?.Value, out userId);
    }

    public static bool TryGetUserId(
        HttpContext context,
        out int userId)
    {
        return TryGetUserId(context.User, out userId);
    }

    public static Task<PostResponse> ToResponseAsync(
        PulseDbContext dbContext,
        Post post,
        int? currentUserId,
        CancellationToken cancellationToken = default)
    {
        return ToResponseCoreAsync(
            dbContext,
            post,
            currentUserId,
            cancellationToken);
    }

    public static Task<PostResponse> ToResponseAsync(
        Post post,
        PulseDbContext dbContext,
        int? currentUserId,
        CancellationToken cancellationToken = default)
    {
        return ToResponseCoreAsync(
            dbContext,
            post,
            currentUserId,
            cancellationToken);
    }

    public static Task<PostResponse> ToResponseAsync(
        Post post,
        int? currentUserId,
        PulseDbContext dbContext,
        CancellationToken cancellationToken = default)
    {
        return ToResponseCoreAsync(
            dbContext,
            post,
            currentUserId,
            cancellationToken);
    }

    private static async Task<PostResponse> ToResponseCoreAsync(
        PulseDbContext dbContext,
        Post post,
        int? currentUserId,
        CancellationToken cancellationToken)
    {
        var author = post.Author;

        if (author is null)
        {
            author = await dbContext.Users
                .AsNoTracking()
                .SingleAsync(
                    user => user.Id == post.AuthorId,
                    cancellationToken);
        }

        var likeCount = await dbContext.PostLikes
            .CountAsync(
                like => like.PostId == post.Id,
                cancellationToken);

        var replyCount = await dbContext.Posts
            .CountAsync(
                reply =>
                    reply.ParentPostId == post.Id
                    && reply.DeletedAt == null,
                cancellationToken);

        var isLikedByMe =
            currentUserId.HasValue
            && await dbContext.PostLikes.AnyAsync(
                like =>
                    like.PostId == post.Id
                    && like.UserId == currentUserId.Value,
                cancellationToken);

        return new PostResponse(
            post.Id,
            new PostAuthorResponse(
                author.Id,
                author.Username,
                author.DisplayName,
                author.AvatarUrl),
            post.Content,
            post.ParentPostId,
            post.CreatedAtUtc,
            likeCount,
            replyCount,
            isLikedByMe);
    }
}