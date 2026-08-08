using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using Pulse.Api.Contracts;
using Pulse.Api.Data;
using Pulse.Api.Domain;

namespace Pulse.Api.Endpoints;

public static class ProfileEndpoints
{
    public static IEndpointRouteBuilder MapProfileEndpoints(
        this IEndpointRouteBuilder endpoints)
    {
        var group = endpoints
            .MapGroup("/api/v1/profiles")
            .RequireAuthorization()
            .WithTags("Profiles");

        group.MapGet("/me", GetCurrentProfileAsync);
        group.MapPut("/me", UpdateCurrentProfileAsync);
        group.MapGet("/{username}", GetProfileAsync);
        group.MapGet("/{username}/posts", GetProfilePostsAsync);

        return endpoints;
    }

    private static async Task<IResult> GetCurrentProfileAsync(
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

        var user = await db.Users
            .AsNoTracking()
            .SingleOrDefaultAsync(
                candidate => candidate.Id == currentUserId,
                cancellationToken);

        if (user is null)
        {
            return Results.NotFound(
                new ApiErrorResponse("User was not found."));
        }

        return Results.Ok(
            await CreateProfileResponseAsync(
                db,
                user,
                currentUserId,
                cancellationToken));
    }

    private static async Task<IResult> GetProfileAsync(
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

        var normalizedUsername =
            username.Trim().ToUpperInvariant();

        var user = await db.Users
            .AsNoTracking()
            .SingleOrDefaultAsync(
                candidate =>
                    candidate.NormalizedUsername ==
                    normalizedUsername,
                cancellationToken);

        if (user is null)
        {
            return Results.NotFound(
                new ApiErrorResponse("User was not found."));
        }

        return Results.Ok(
            await CreateProfileResponseAsync(
                db,
                user,
                currentUserId,
                cancellationToken));
    }

    private static async Task<IResult> UpdateCurrentProfileAsync(
        UpdateProfileRequest request,
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

        var displayName =
            request.DisplayName?.Trim() ?? string.Empty;
        var bio = NormalizeOptional(request.Bio);
        var avatarUrl = NormalizeOptional(request.AvatarUrl);

        if (displayName.Length is < 1 or > 80)
        {
            return Results.BadRequest(
                new ApiErrorResponse(
                    "Display name must be between 1 and 80 characters.",
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

        if (avatarUrl is not null &&
            (!Uri.TryCreate(
                 avatarUrl,
                 UriKind.Absolute,
                 out var parsedAvatarUrl) ||
             (parsedAvatarUrl.Scheme != Uri.UriSchemeHttp &&
              parsedAvatarUrl.Scheme != Uri.UriSchemeHttps)))
        {
            return Results.BadRequest(
                new ApiErrorResponse(
                    "Avatar URL must be a valid HTTP or HTTPS URL.",
                    "avatarUrl"));
        }

        var user = await db.Users
            .SingleOrDefaultAsync(
                candidate => candidate.Id == currentUserId,
                cancellationToken);

        if (user is null)
        {
            return Results.NotFound(
                new ApiErrorResponse("User was not found."));
        }

        user.DisplayName = displayName;
        user.Bio = bio;
        user.AvatarUrl = avatarUrl;

        await db.SaveChangesAsync(cancellationToken);

        return Results.Ok(
            await CreateProfileResponseAsync(
                db,
                user,
                currentUserId,
                cancellationToken));
    }

    private static async Task<IResult> GetProfilePostsAsync(
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

        var normalizedUsername =
            username.Trim().ToUpperInvariant();

        var user = await db.Users
            .AsNoTracking()
            .SingleOrDefaultAsync(
                candidate =>
                    candidate.NormalizedUsername ==
                    normalizedUsername,
                cancellationToken);

        if (user is null)
        {
            return Results.NotFound(
                new ApiErrorResponse("User was not found."));
        }

        var posts = await db.Posts
            .AsNoTracking()
            .Include(post => post.Author)
            .Where(post =>
                post.AuthorId == user.Id &&
                post.ParentPostId == null)
            .OrderByDescending(post => post.CreatedAtUtc)
            .ThenByDescending(post => post.Id)
            .ToListAsync(cancellationToken);
        var response = new List<PostResponse>(posts.Count);

        foreach (var post in posts)
        {
            response.Add(
                await PostEndpoints.ToResponseAsync(
                    db,
                    post,
                    currentUserId,
                    cancellationToken));
        }

        return Results.Ok(response);
    }

    internal static async Task<ProfileResponse> CreateProfileResponseAsync(
        PulseDbContext db,
        User user,
        int currentUserId,
        CancellationToken cancellationToken)
    {
        var postCount = await db.Posts
            .AsNoTracking()
            .CountAsync(
                post =>
                    post.AuthorId == user.Id &&
                    post.ParentPostId == null,
                cancellationToken);

        var followerCount = await db.Follows
            .AsNoTracking()
            .CountAsync(
                follow => follow.FollowingId == user.Id,
                cancellationToken);

        var followingCount = await db.Follows
            .AsNoTracking()
            .CountAsync(
                follow => follow.FollowerId == user.Id,
                cancellationToken);

        var isCurrentUser = user.Id == currentUserId;

        var isFollowing = !isCurrentUser &&
            await db.Follows
                .AsNoTracking()
                .AnyAsync(
                    follow =>
                        follow.FollowerId == currentUserId &&
                        follow.FollowingId == user.Id,
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
            isCurrentUser);
    }

    private static string? NormalizeOptional(string? value)
    {
        var normalized = value?.Trim();

        return string.IsNullOrEmpty(normalized)
            ? null
            : normalized;
    }
}