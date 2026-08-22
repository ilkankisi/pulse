using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using Pulse.Api.Contracts;
using Pulse.Api.Data;

namespace Pulse.Api.Endpoints;

public static class SocialGraphEndpoints
{
    public static IEndpointRouteBuilder MapSocialGraphEndpoints(
        this IEndpointRouteBuilder endpoints)
    {
        var group = endpoints
            .MapGroup("/api/v1/profiles")
            .RequireAuthorization()
            .WithTags("Profiles");

        group.MapGet(
            "/{username}/followers",
            GetFollowersAsync);

        group.MapGet(
            "/{username}/following",
            GetFollowingAsync);

        return endpoints;
    }

    private static async Task<IResult> GetFollowersAsync(
        string username,
        ClaimsPrincipal principal,
        PulseDbContext db,
        CancellationToken cancellationToken)
    {
        if (!PostEndpoints.TryGetUserId(
                principal,
                out var currentUserId))
        {
            return Results.Unauthorized();
        }

        var targetUserId = await FindUserIdAsync(
            username,
            db,
            cancellationToken);

        if (targetUserId is null)
        {
            return Results.NotFound(
                new ApiErrorResponse(
                    "User was not found."));
        }

        if (await HasBlockRelationshipAsync(
                db,
                currentUserId,
                targetUserId.Value,
                cancellationToken))
        {
            return Results.NotFound(
                new ApiErrorResponse(
                    "User was not found."));
        }

        var users = await db.Follows
            .AsNoTracking()
            .Where(
                follow =>
                    follow.FollowingId ==
                    targetUserId.Value)
            .OrderBy(
                follow =>
                    follow.Follower.Username)
            .Select(
                follow =>
                    new SocialGraphUserProjection(
                        follow.FollowerId,
                        follow.Follower.Username,
                        follow.Follower.DisplayName,
                        follow.Follower.AvatarUrl))
            .ToListAsync(cancellationToken);

        var items = await BuildCanonicalItemsAsync(
            users,
            currentUserId,
            db,
            cancellationToken);

        return Results.Ok(
            new SocialGraphCollectionResponse(items));
    }

    private static async Task<IResult> GetFollowingAsync(
        string username,
        ClaimsPrincipal principal,
        PulseDbContext db,
        CancellationToken cancellationToken)
    {
        if (!PostEndpoints.TryGetUserId(
                principal,
                out var currentUserId))
        {
            return Results.Unauthorized();
        }

        var targetUserId = await FindUserIdAsync(
            username,
            db,
            cancellationToken);

        if (targetUserId is null)
        {
            return Results.NotFound(
                new ApiErrorResponse(
                    "User was not found."));
        }

        if (await HasBlockRelationshipAsync(
                db,
                currentUserId,
                targetUserId.Value,
                cancellationToken))
        {
            return Results.NotFound(
                new ApiErrorResponse(
                    "User was not found."));
        }

        var users = await db.Follows
            .AsNoTracking()
            .Where(
                follow =>
                    follow.FollowerId ==
                    targetUserId.Value)
            .OrderBy(
                follow =>
                    follow.FollowingUser.Username)
            .Select(
                follow =>
                    new SocialGraphUserProjection(
                        follow.FollowingId,
                        follow.FollowingUser.Username,
                        follow.FollowingUser.DisplayName,
                        follow.FollowingUser.AvatarUrl))
            .ToListAsync(cancellationToken);

        var items = await BuildCanonicalItemsAsync(
            users,
            currentUserId,
            db,
            cancellationToken);

        return Results.Ok(
            new SocialGraphCollectionResponse(items));
    }

    private static async Task<int?> FindUserIdAsync(
        string username,
        PulseDbContext db,
        CancellationToken cancellationToken)
    {
        var normalizedUsername =
            username.Trim().ToUpperInvariant();

        return await db.Users
            .AsNoTracking()
            .Where(
                user =>
                    user.NormalizedUsername ==
                    normalizedUsername)
            .Select(
                user => (int?)user.Id)
            .SingleOrDefaultAsync(
                cancellationToken);
    }

    private static async Task<
        IReadOnlyList<SocialGraphUserResponse>>
        BuildCanonicalItemsAsync(
            IReadOnlyList<SocialGraphUserProjection> users,
            int currentUserId,
            PulseDbContext db,
            CancellationToken cancellationToken)
    {
        if (users.Count == 0)
        {
            return Array.Empty<SocialGraphUserResponse>();
        }

        var userIds =
            users
                .Select(user => user.Id)
                .ToArray();

        var blockedUserIds = await db.Blocks
            .AsNoTracking()
            .Where(
                block =>
                    (block.BlockerId ==
                         currentUserId &&
                     userIds.Contains(
                         block.BlockedUserId)) ||
                    (block.BlockedUserId ==
                         currentUserId &&
                     userIds.Contains(
                         block.BlockerId)))
            .Select(
                block =>
                    block.BlockerId ==
                    currentUserId
                        ? block.BlockedUserId
                        : block.BlockerId)
            .ToListAsync(cancellationToken);

        var blockedSet =
            blockedUserIds.ToHashSet();

        var visibleUserIds =
            userIds
                .Where(
                    id =>
                        !blockedSet.Contains(id))
                .ToArray();

        var followedUserIds = await db.Follows
            .AsNoTracking()
            .Where(
                follow =>
                    follow.FollowerId ==
                    currentUserId &&
                    visibleUserIds.Contains(
                        follow.FollowingId))
            .Select(
                follow =>
                    follow.FollowingId)
            .ToListAsync(cancellationToken);

        var followedSet =
            followedUserIds.ToHashSet();

        return users
            .Where(
                user =>
                    !blockedSet.Contains(
                        user.Id))
            .Select(
                user =>
                    new SocialGraphUserResponse(
                        user.Id,
                        user.Username,
                        user.DisplayName,
                        user.AvatarUrl,
                        followedSet.Contains(
                            user.Id)))
            .ToList();
    }

    private static Task<bool> HasBlockRelationshipAsync(
        PulseDbContext db,
        int currentUserId,
        int targetUserId,
        CancellationToken cancellationToken)
    {
        if (currentUserId == targetUserId)
        {
            return Task.FromResult(false);
        }

        return db.Blocks
            .AsNoTracking()
            .AnyAsync(
                block =>
                    (block.BlockerId ==
                         currentUserId &&
                     block.BlockedUserId ==
                         targetUserId) ||
                    (block.BlockerId ==
                         targetUserId &&
                     block.BlockedUserId ==
                         currentUserId),
                cancellationToken);
    }

    private sealed record SocialGraphUserProjection(
        int Id,
        string Username,
        string DisplayName,
        string? AvatarUrl);

    private sealed record SocialGraphCollectionResponse(
        IReadOnlyList<SocialGraphUserResponse> Items);
}