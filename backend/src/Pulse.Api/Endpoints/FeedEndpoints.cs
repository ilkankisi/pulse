using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using Pulse.Api.Contracts;
using Pulse.Api.Data;
using Pulse.Api.Domain;

namespace Pulse.Api.Endpoints;

public static class FeedEndpoints
{
    public static IEndpointRouteBuilder MapFeedEndpoints(
        this IEndpointRouteBuilder endpoints)
    {
        endpoints.MapGet(
                "/api/v1/feed",
                GetFeedAsync)
            .RequireAuthorization();

        return endpoints;
    }

    private static async Task<IResult> GetFeedAsync(
        ClaimsPrincipal principal,
        PulseDbContext dbContext,
        CancellationToken cancellationToken)
    {
        if (!PostEndpoints.TryGetUserId(
                principal,
                out var currentUserId))
        {
            return Results.Unauthorized();
        }

        var followedUserIds = await dbContext.Follows
            .Where(
                follow =>
                    follow.FollowerId == currentUserId)
            .Select(follow => follow.FollowingId)
            .ToListAsync(cancellationToken);

        var blockedUserIds = await dbContext.Blocks
            .AsNoTracking()
            .Where(
                block =>
                    block.BlockerId == currentUserId
                    || block.BlockedUserId == currentUserId)
            .Select(
                block =>
                    block.BlockerId == currentUserId
                        ? block.BlockedUserId
                        : block.BlockerId)
            .ToListAsync(cancellationToken);

        IQueryable<Post> query = dbContext.Posts
            .AsNoTracking()
            .Include(post => post.Author)
            .Where(
                post =>
                    post.ParentPostId == null
                    && post.DeletedAt == null
                    && !blockedUserIds.Contains(post.AuthorId));

        if (followedUserIds.Count > 0)
        {
            query = query.Where(
                post =>
                    post.AuthorId == currentUserId
                    || followedUserIds.Contains(post.AuthorId));
        }

        var posts = await query
            .OrderByDescending(post => post.CreatedAtUtc)
            .ThenByDescending(post => post.Id)
            .ToListAsync(cancellationToken);

        var responses =
            new List<PostResponse>(posts.Count);

        foreach (var post in posts)
        {
            responses.Add(
                await PostEndpoints.ToResponseAsync(
                    dbContext,
                    post,
                    currentUserId,
                    cancellationToken));
        }

        return Results.Ok(
            new FeedListResponse(responses));
    }
}