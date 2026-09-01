using Microsoft.EntityFrameworkCore;
using Pulse.Api.Contracts;
using Pulse.Api.Data;

namespace Pulse.Api.Endpoints;

public static class SocialGraphEndpoints
{
    public static IEndpointRouteBuilder MapSocialGraphEndpoints(
        this IEndpointRouteBuilder endpoints)
    {
        endpoints.MapDelete(
        "/api/v1/profiles/{username}/followers/{followerId:int}",
        RemoveFollowerAsync)
        .RequireAuthorization()
        .WithTags("Profiles");
        // Removing followers is not part of the canonical API contract.

        return endpoints;
    }

    private static async Task<IResult> RemoveFollowerAsync(
        HttpContext httpContext,
        PulseDbContext dbContext,
        string username,
        int followerId,
        CancellationToken cancellationToken)
    {
        if (!PostEndpoints.TryGetUserId(
                httpContext,
                out var currentUserId))
        {
            return Results.Unauthorized();
        }

        var normalizedUsername =
            username.Trim().ToUpperInvariant();

        var profile = await dbContext.Users
            .AsNoTracking()
            .SingleOrDefaultAsync(
                user =>
                    user.NormalizedUsername == normalizedUsername,
                cancellationToken);

        if (profile is null)
        {
            return Results.NotFound(
                new ApiErrorResponse(
                    "Profile was not found."));
        }

        if (profile.Id != currentUserId)
        {
            return Results.Json(
                new ApiErrorResponse(
                    "Only the profile owner can remove a follower."),
                statusCode: StatusCodes.Status403Forbidden);
        }

        var follow = await dbContext.Follows
            .SingleOrDefaultAsync(
                candidate =>
                    candidate.FollowerId == followerId
                    && candidate.FollowingId == currentUserId,
                cancellationToken);

        if (follow is null)
        {
            return Results.NotFound(
                new ApiErrorResponse(
                    "Follower was not found."));
        }

        dbContext.Follows.Remove(follow);
        await dbContext.SaveChangesAsync(cancellationToken);

        return Results.NoContent();
    }
}