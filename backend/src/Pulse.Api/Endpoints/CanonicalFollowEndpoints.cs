using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using Pulse.Api.Contracts;
using Pulse.Api.Data;
using Pulse.Api.Domain;

namespace Pulse.Api.Endpoints;

public static class CanonicalFollowEndpoints
{
    public static IEndpointRouteBuilder MapCanonicalFollowEndpoints(
        this IEndpointRouteBuilder endpoints)
    {
        var group = endpoints
            .MapGroup("/api/v1/profiles")
            .RequireAuthorization();

        group.MapPost(
            "/{username}/follow",
            FollowAsync);

        group.MapDelete(
            "/{username}/follow",
            UnfollowAsync);

        return endpoints;
    }

    private static async Task<IResult> FollowAsync(
        string username,
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

        var targetUser = await FindUserAsync(
            dbContext,
            username,
            cancellationToken);

        if (targetUser is null)
        {
            return Results.NotFound();
        }

        if (targetUser.Id == currentUserId)
        {
            return Results.BadRequest(
                new ApiErrorResponse(
                    "Users cannot follow themselves.",
                    "username"));
        }

        var follow = await dbContext.Follows.FindAsync(
            new object[]
            {
                currentUserId,
                targetUser.Id
            },
            cancellationToken);

        if (follow is null)
        {
            dbContext.Follows.Add(
                new Follow
                {
                    FollowerId = currentUserId,
                    FollowingId = targetUser.Id,
                    CreatedAtUtc = DateTimeOffset.UtcNow
                });

            await dbContext.SaveChangesAsync(cancellationToken);
        }

        return Results.Ok(
            await CreateResponseAsync(
                dbContext,
                targetUser.Id,
                true,
                cancellationToken));
    }

    private static async Task<IResult> UnfollowAsync(
        string username,
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

        var targetUser = await FindUserAsync(
            dbContext,
            username,
            cancellationToken);

        if (targetUser is null)
        {
            return Results.NotFound();
        }

        var follow = await dbContext.Follows.FindAsync(
            new object[]
            {
                currentUserId,
                targetUser.Id
            },
            cancellationToken);

        if (follow is not null)
        {
            dbContext.Follows.Remove(follow);
            await dbContext.SaveChangesAsync(cancellationToken);
        }

        return Results.Ok(
            await CreateResponseAsync(
                dbContext,
                targetUser.Id,
                false,
                cancellationToken));
    }

    private static Task<User?> FindUserAsync(
        PulseDbContext dbContext,
        string username,
        CancellationToken cancellationToken)
    {
        var normalizedUsername =
            username.Trim().ToUpperInvariant();

        return dbContext.Users.SingleOrDefaultAsync(
            user =>
                user.NormalizedUsername
                == normalizedUsername,
            cancellationToken);
    }

    private static async Task<FollowResponse> CreateResponseAsync(
        PulseDbContext dbContext,
        int targetUserId,
        bool isFollowing,
        CancellationToken cancellationToken)
    {
        var followerCount = await dbContext.Follows.CountAsync(
            follow => follow.FollowingId == targetUserId,
            cancellationToken);

        return new FollowResponse(
            targetUserId,
            isFollowing,
            followerCount);
    }
}