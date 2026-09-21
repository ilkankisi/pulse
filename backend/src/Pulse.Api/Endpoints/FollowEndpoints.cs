using System.Security.Claims;

using Microsoft.EntityFrameworkCore;

using Pulse.Api.Contracts;
using Pulse.Api.Data;
using Pulse.Api.Domain;

namespace Pulse.Api.Endpoints;

public static class FollowEndpoints
{
    public static IEndpointRouteBuilder MapFollowEndpoints(
        this IEndpointRouteBuilder endpoints)
    {
        var group = endpoints
            .MapGroup("/api/v1/profiles/{username}")
            .RequireAuthorization()
            .WithTags("SocialGraph");

        group.MapGet("/followers", GetFollowersAsync);
        group.MapGet("/following", GetFollowingAsync);
        group.MapPost("/follow", FollowAsync);
        group.MapDelete("/follow", UnfollowAsync);

        return endpoints;
    }

    private static async Task<IResult> FollowAsync(
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

        var target = await FindProfileAsync(
            db,
            username,
            cancellationToken);

        if (target is null)
        {
            return Results.NotFound(
                new ApiErrorResponse(
                    "Profile was not found."));
        }

        if (target.Id == currentUserId)
        {
            return Results.BadRequest(
                new ApiErrorResponse(
                    "You cannot follow yourself.",
                    "username"));
        }

        if (await HasBlockAsync(
                db,
                currentUserId,
                target.Id,
                cancellationToken))
        {
            return Results.NotFound(
                new ApiErrorResponse(
                    "Profile was not found."));
        }

        var existing = await db.Follows
            .SingleOrDefaultAsync(
                follow =>
                    follow.FollowerId == currentUserId
                    && follow.FollowingId == target.Id,
                cancellationToken);

        if (existing is null)
        {
            db.Follows.Add(
                new Follow
                {
                    FollowerId = currentUserId,
                    FollowingId = target.Id,
                    CreatedAtUtc = DateTimeOffset.UtcNow,
                });

            await db.SaveChangesAsync(
                cancellationToken);
        }

        return Results.Ok(
            new FollowResponse(
                target.Username,
                true));
    }

    private static async Task<IResult> UnfollowAsync(
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

        var target = await FindProfileAsync(
            db,
            username,
            cancellationToken);

        if (target is null)
        {
            return Results.NotFound(
                new ApiErrorResponse(
                    "Profile was not found."));
        }

        var existing = await db.Follows
            .SingleOrDefaultAsync(
                follow =>
                    follow.FollowerId == currentUserId
                    && follow.FollowingId == target.Id,
                cancellationToken);

        if (existing is not null)
        {
            db.Follows.Remove(existing);

            await db.SaveChangesAsync(
                cancellationToken);
        }

        return Results.Ok(
            new FollowResponse(
                target.Username,
                false));
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

        var target = await FindProfileAsync(
            db,
            username,
            cancellationToken);

        if (target is null)
        {
            return Results.NotFound(
                new ApiErrorResponse(
                    "Profile was not found."));
        }

        if (await HasBlockAsync(
                db,
                currentUserId,
                target.Id,
                cancellationToken))
        {
            return Results.NotFound(
                new ApiErrorResponse(
                    "Profile was not found."));
        }

        var followers = await db.Follows
            .AsNoTracking()
            .Where(
                follow =>
                    follow.FollowingId == target.Id)
            .Include(
                follow =>
                    follow.Follower)
            .OrderBy(
                follow =>
                    follow.Follower.Username)
            .ToListAsync(
                cancellationToken);

        var items =
            new List<SocialGraphUserResponse>(
                followers.Count);

        foreach (var follow in followers)
        {
            if (!IsProfileActive(follow.Follower)
                || await HasBlockAsync(
                    db,
                    currentUserId,
                    follow.Follower.Id,
                    cancellationToken))
            {
                continue;
            }
        
        items.Add(
        await ToSocialGraphUserAsync(
        db,
        follow.Follower,
        currentUserId,
                    cancellationToken));
        }

        return Results.Ok(
            new
            {
                items,
            });
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

        var target = await FindProfileAsync(
            db,
            username,
            cancellationToken);

        if (target is null)
        {
            return Results.NotFound(
                new ApiErrorResponse(
                    "Profile was not found."));
        }

        if (await HasBlockAsync(
                db,
                currentUserId,
                target.Id,
                cancellationToken))
        {
            return Results.NotFound(
                new ApiErrorResponse(
                    "Profile was not found."));
        }

        var following = await db.Follows
            .AsNoTracking()
            .Where(
                follow =>
                    follow.FollowerId == target.Id)
            .Include(
                follow =>
                    follow.FollowingUser)
            .OrderBy(
                follow =>
                    follow.FollowingUser.Username)
            .ToListAsync(
                cancellationToken);

        var items =
            new List<SocialGraphUserResponse>(
                following.Count);

        foreach (var follow in following)
        {
            if (!IsProfileActive(follow.FollowingUser)
                || await HasBlockAsync(
                    db,
                    currentUserId,
                    follow.FollowingUser.Id,
                    cancellationToken))
            {
                continue;
            }
        
        items.Add(
        await ToSocialGraphUserAsync(
        db,
        follow.FollowingUser,
        currentUserId,
                    cancellationToken));
        }

        return Results.Ok(
            new
            {
                items,
            });
    }

    private static async Task<User?> FindProfileAsync(
        PulseDbContext db,
        string username,
        CancellationToken cancellationToken)
    {
        var normalized =
            username
                .Trim()
                .ToUpperInvariant();

        var user = await db.Users
        .AsNoTracking()
        .SingleOrDefaultAsync(
        user =>
        user.NormalizedUsername == normalized,
        cancellationToken);
        
        return user is not null && IsProfileActive(user)
            ? user
            : null;
        }
        
    private static bool IsProfileActive(User user)
    {
        var type = user.GetType();
        
        var isActive = type.GetProperty("IsActive");
        if (isActive?.PropertyType == typeof(bool)
            && isActive.GetValue(user) is bool active
            && !active)
        {
            return false;
        }
        
        foreach (var propertyName in new[] { "IsDisabled", "IsDeleted" })
        {
            var property = type.GetProperty(propertyName);
            if (property?.PropertyType == typeof(bool)
                && property.GetValue(user) is bool value
                && value)
            {
                return false;
            }
        }
        
        foreach (var propertyName in new[]
                 {
                     "DeactivatedAtUtc",
                     "DeactivatedAt",
                     "DeletedAtUtc",
                     "DeletedAt",
                 })
        {
            var property = type.GetProperty(propertyName);
            if (property is not null
                && property.GetValue(user) is not null)
            {
                return false;
            }
        }
        
        var status = type.GetProperty("Status")?.GetValue(user)?.ToString();
        if (status is not null
            && (status.Equals("Inactive", StringComparison.OrdinalIgnoreCase)
                || status.Equals("Disabled", StringComparison.OrdinalIgnoreCase)
                || status.Equals("Deactivated", StringComparison.OrdinalIgnoreCase)
                || status.Equals("Deleted", StringComparison.OrdinalIgnoreCase)))
        {
            return false;
        }
        
        return true;
    }

    private static async Task<bool> HasBlockAsync(
        PulseDbContext db,
        int currentUserId,
        int targetUserId,
        CancellationToken cancellationToken)
    {
        return await db.Blocks
            .AsNoTracking()
            .AnyAsync(
                block =>
                    (block.BlockerId == currentUserId
                     && block.BlockedUserId == targetUserId)
                    || (block.BlockerId == targetUserId
                        && block.BlockedUserId == currentUserId),
                cancellationToken);
    }

    private static async Task<SocialGraphUserResponse>
        ToSocialGraphUserAsync(
            PulseDbContext db,
            User user,
            int currentUserId,
            CancellationToken cancellationToken)
    {
        var isFollowed =
            user.Id != currentUserId
            && await db.Follows
                .AsNoTracking()
                .AnyAsync(
                    follow =>
                        follow.FollowerId == currentUserId
                        && follow.FollowingId == user.Id,
                    cancellationToken);

        return new SocialGraphUserResponse(
            user.Id,
            user.Username,
            user.DisplayName,
            user.AvatarUrl,
            isFollowed);
    }
}