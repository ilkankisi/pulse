using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using Pulse.Api.Contracts;
using Pulse.Api.Data;
using Pulse.Api.Domain;

namespace Pulse.Api.Endpoints;

public static class CanonicalProfileEndpoints
{
    public static IEndpointRouteBuilder MapCanonicalProfileEndpoints(
        this IEndpointRouteBuilder endpoints)
    {
        var group = endpoints
            .MapGroup("/api/v1")
            .RequireAuthorization();

        group.MapGet("/me", GetCurrentProfileAsync);
        group.MapPut("/me", UpdateCurrentProfileAsync);
        group.MapGet(
            "/profiles/{username}",
            GetProfileAsync);
        group.MapGet(
            "/profiles/{username}/posts",
            GetProfilePostsAsync);

        return endpoints;
    }

    private static async Task<IResult> GetCurrentProfileAsync(
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

        var user = await dbContext.Users
            .AsNoTracking()
            .SingleOrDefaultAsync(
                candidate => candidate.Id == currentUserId,
                cancellationToken);

        if (user is null)
        {
            return Results.NotFound();
        }

        return Results.Ok(
            await CreateProfileResponseAsync(
                dbContext,
                user,
                currentUserId,
                cancellationToken));
    }

    private static async Task<IResult> UpdateCurrentProfileAsync(
        UpdateProfileRequest request,
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

        var user = await dbContext.Users.SingleOrDefaultAsync(
            candidate => candidate.Id == currentUserId,
            cancellationToken);

        if (user is null)
        {
            return Results.NotFound();
        }

        var displayName = request.DisplayName?.Trim();
        var bio = request.Bio?.Trim();
        var avatarUrl = request.AvatarUrl?.Trim();

        if (string.IsNullOrWhiteSpace(displayName)
            || displayName.Length > 80)
        {
            return Results.BadRequest(
                new ApiErrorResponse(
                    "Display name is required and cannot exceed 80 characters.",
                    "displayName"));
        }

        if (bio?.Length > 160)
        {
            return Results.BadRequest(
                new ApiErrorResponse(
                    "Bio cannot exceed 160 characters.",
                    "bio"));
        }

        if (avatarUrl?.Length > 2048)
        {
            return Results.BadRequest(
                new ApiErrorResponse(
                    "Avatar URL cannot exceed 2048 characters.",
                    "avatarUrl"));
        }

        user.DisplayName = displayName;
        user.Bio = string.IsNullOrWhiteSpace(bio)
            ? null
            : bio;
        user.AvatarUrl = string.IsNullOrWhiteSpace(avatarUrl)
            ? null
            : avatarUrl;

        await dbContext.SaveChangesAsync(cancellationToken);

        return Results.Ok(
            await CreateProfileResponseAsync(
                dbContext,
                user,
                currentUserId,
                cancellationToken));
    }

    private static async Task<IResult> GetProfileAsync(
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

        var normalizedUsername = Normalize(username);

        var user = await dbContext.Users
            .AsNoTracking()
            .SingleOrDefaultAsync(
                candidate =>
                    candidate.NormalizedUsername
                    == normalizedUsername,
                cancellationToken);

        if (user is null)
        {
            return Results.NotFound();
        }

        return Results.Ok(
            await CreateProfileResponseAsync(
                dbContext,
                user,
                currentUserId,
                cancellationToken));
    }

    private static async Task<IResult> GetProfilePostsAsync(
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

        var normalizedUsername = Normalize(username);

        var user = await dbContext.Users
            .AsNoTracking()
            .SingleOrDefaultAsync(
                candidate =>
                    candidate.NormalizedUsername
                    == normalizedUsername,
                cancellationToken);

        if (user is null)
        {
            return Results.NotFound();
        }

        var posts = await dbContext.Posts
            .AsNoTracking()
            .Include(post => post.Author)
            .Where(
                post =>
                    post.AuthorId == user.Id
                    && post.ParentPostId == null)
            .OrderByDescending(post => post.CreatedAtUtc)
            .ThenByDescending(post => post.Id)
            .ToListAsync(cancellationToken);

        var responses = new List<PostResponse>(posts.Count);

        foreach (var post in posts)
        {
            responses.Add(
                await PostEndpoints.ToResponseAsync(
                    dbContext,
                    post,
                    currentUserId,
                    cancellationToken));
        }

        return Results.Ok(responses);
    }

    private static async Task<ProfileResponse> CreateProfileResponseAsync(
        PulseDbContext dbContext,
        User user,
        int currentUserId,
        CancellationToken cancellationToken)
    {
        var postCount = await dbContext.Posts.CountAsync(
            post =>
                post.AuthorId == user.Id
                && post.ParentPostId == null,
            cancellationToken);

        var followerCount = await dbContext.Follows.CountAsync(
            follow => follow.FollowingId == user.Id,
            cancellationToken);

        var followingCount = await dbContext.Follows.CountAsync(
            follow => follow.FollowerId == user.Id,
            cancellationToken);

        var isFollowing =
            currentUserId != user.Id
            && await dbContext.Follows.AnyAsync(
                follow =>
                    follow.FollowerId == currentUserId
                    && follow.FollowingId == user.Id,
                cancellationToken);

        return new ProfileResponse(
            user.Id,
            user.Username,
            user.DisplayName,
            user.Bio,
            user.AvatarUrl,
            user.CreatedAtUtc,
            postCount,
            followerCount,
            followingCount,
            isFollowing,
            currentUserId == user.Id);
    }

    private static string Normalize(
        string value)
    {
        return value.Trim().ToUpperInvariant();
    }
}