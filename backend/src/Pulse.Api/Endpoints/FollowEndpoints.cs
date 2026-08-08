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
            .WithTags("Follows");

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

        var targetUser = await FindUserAsync(
            username,
            db,
            cancellationToken);

        if (targetUser is null)
        {
            return Results.NotFound(
                new ApiErrorResponse("User was not found."));
        }

        if (targetUser.Id == currentUserId)
        {
            return Results.BadRequest(
                new ApiErrorResponse(
                    "Users cannot follow themselves.",
                    "username"));
        }

        var existingFollow = await db.Follows
            .SingleOrDefaultAsync(
                follow =>
                    follow.FollowerId == currentUserId &&
                    follow.FollowingId == targetUser.Id,
                cancellationToken);

        if (existingFollow is null)
        {
            db.Follows.Add(new Follow
            {
                FollowerId = currentUserId,
                FollowingId = targetUser.Id,
                CreatedAtUtc = DateTimeOffset.UtcNow
            });

            try
            {
                await db.SaveChangesAsync(cancellationToken);
            }
            catch (DbUpdateException)
            {
                db.ChangeTracker.Clear();
            }
        }

        return Results.Ok(
            await CreateResponseAsync(
                targetUser.Id,
                true,
                db,
                cancellationToken));
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

        var targetUser = await FindUserAsync(
            username,
            db,
            cancellationToken);

        if (targetUser is null)
        {
            return Results.NotFound(
                new ApiErrorResponse("User was not found."));
        }

        if (targetUser.Id == currentUserId)
        {
            return Results.BadRequest(
                new ApiErrorResponse(
                    "Users cannot unfollow themselves.",
                    "username"));
        }

        var existingFollow = await db.Follows
            .SingleOrDefaultAsync(
                follow =>
                    follow.FollowerId == currentUserId &&
                    follow.FollowingId == targetUser.Id,
                cancellationToken);

        if (existingFollow is not null)
        {
            db.Follows.Remove(existingFollow);
            await db.SaveChangesAsync(cancellationToken);
        }

        return Results.Ok(
            await CreateResponseAsync(
                targetUser.Id,
                false,
                db,
                cancellationToken));
    }

    private static async Task<User?> FindUserAsync(
        string username,
        PulseDbContext db,
        CancellationToken cancellationToken)
    {
        var normalizedUsername =
            username.Trim().ToUpperInvariant();

        return await db.Users
            .AsNoTracking()
            .SingleOrDefaultAsync(
                user =>
                    user.NormalizedUsername ==
                    normalizedUsername,
                cancellationToken);
    }

    private static async Task<FollowResponse> CreateResponseAsync(
        int userId,
        bool isFollowing,
        PulseDbContext db,
        CancellationToken cancellationToken)
    {
        var followerCount = await db.Follows
            .AsNoTracking()
            .CountAsync(
                follow => follow.FollowingId == userId,
                cancellationToken);

        return new FollowResponse(
            userId,
            isFollowing,
            followerCount);
    }
}