using System.Security.Claims;
using System.Text.RegularExpressions;
using Microsoft.EntityFrameworkCore;
using Pulse.Api.Contracts;
using Pulse.Api.Data;
using Pulse.Api.Domain;

namespace Pulse.Api.Endpoints;

public static class ProfileEndpoints
{
    private const int DefaultPageSize = 20;
    private const int MaxPageSize = 50;

    private static readonly Regex MentionRegex = new(
        @"(?<![A-Za-z0-9_])@([A-Za-z0-9_]{1,32})(?![A-Za-z0-9_])",
        RegexOptions.Compiled | RegexOptions.CultureInvariant);

    public static IEndpointRouteBuilder MapProfileEndpoints(
        this IEndpointRouteBuilder endpoints)
    {
        var group = endpoints
            .MapGroup("/api/v1/profiles")
            .RequireAuthorization()
            .WithTags("Profiles");

        group.MapGet(
            "/{username}",
            GetProfileAsync);

        group.MapGet(
            "/{username}/posts",
            GetProfilePostsAsync);

        var searchGroup = endpoints
            .MapGroup("/api/v1/search")
            .RequireAuthorization()
            .WithTags("Search");

        searchGroup.MapGet(
            "/users",
            SearchUsersAsync)
            .WithName("SearchUsers");

        searchGroup.MapGet(
            "/posts",
            SearchPostsAsync)
            .WithName("SearchPosts");

        searchGroup.MapGet(
            "/mentions",
            GetMentionSuggestionsAsync)
            .WithName("GetMentionSuggestions");

        return endpoints;
    }

    internal static async Task<IResult> GetCurrentProfileContractAsync(
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
                candidate =>
                    candidate.Id == currentUserId,
                cancellationToken);

        if (user is null)
        {
            return Results.NotFound(
                new ApiErrorResponse(
                    "User was not found."));
        }

        return Results.Ok(
            await CreateProfileResponseAsync(
                db,
                user,
                currentUserId,
                cancellationToken));
    }

    internal static async Task<IResult> UpdateCurrentProfileContractAsync(
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
            request.DisplayName?.Trim()
            ?? string.Empty;

        var bio =
            NormalizeOptional(request.Bio);

        var avatarUrl =
            NormalizeOptional(request.AvatarUrl);

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
                candidate =>
                    candidate.Id == currentUserId,
                cancellationToken);

        if (user is null)
        {
            return Results.NotFound(
                new ApiErrorResponse(
                    "User was not found."));
        }

        user.DisplayName = displayName;
        user.Bio = bio;
        user.AvatarUrl = avatarUrl;

        await db.SaveChangesAsync(
            cancellationToken);

        return Results.Ok(
            await CreateProfileResponseAsync(
                db,
                user,
                currentUserId,
                cancellationToken));
    }

    private static async Task<IResult> SearchUsersAsync(
        string? q,
        int? page,
        int? pageSize,
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

        var query = NormalizeSearchQuery(q);
        var requestedPage = NormalizePage(page);
        var requestedPageSize = NormalizePageSize(pageSize);

        var usersQuery = db.Users
            .AsNoTracking()
            .Where(
                user =>
                    query.Length > 0 &&
                    user.NormalizedUsername.Contains(query) &&
                    !db.Blocks.Any(
                        block =>
                            (block.BlockerId == currentUserId &&
                             block.BlockedUserId == user.Id) ||
                            (block.BlockerId == user.Id &&
                             block.BlockedUserId == currentUserId)));

        var totalCount = await usersQuery.CountAsync(
            cancellationToken);

        var users = await usersQuery
            .OrderBy(user => user.NormalizedUsername)
            .ThenBy(user => user.Id)
            .Skip((requestedPage - 1) * requestedPageSize)
            .Take(requestedPageSize)
            .Select(
                user => new
                {
                    id = user.Id,
                    username = user.Username,
                    displayName = user.DisplayName,
                    mention = new
                    {
                        id = user.Id,
                        username = user.Username,
                        displayName = user.DisplayName,
                    },
                })
            .ToListAsync(cancellationToken);

        return Results.Ok(
            new
            {
                items = users,
                page = requestedPage,
                pageSize = requestedPageSize,
                totalCount,
                hasNextPage =
                    requestedPage * requestedPageSize < totalCount,
            });
    }

    private static async Task<IResult> SearchPostsAsync(
        string? q,
        int? page,
        int? pageSize,
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

        var query = q?.Trim() ?? string.Empty;
        var requestedPage = NormalizePage(page);
        var requestedPageSize = NormalizePageSize(pageSize);

        if (query.Length == 0)
        {
            return Results.Ok(
                new
                {
                    items = Array.Empty<object>(),
                    page = requestedPage,
                    pageSize = requestedPageSize,
                    totalCount = 0,
                    hasNextPage = false,
                });
        }

        var postsQuery = db.Posts
            .AsNoTracking()
            .Include(post => post.Author)
            .Where(
                post =>
                    post.DeletedAt == null &&
                    post.Content.Contains(query) &&
                    !db.Blocks.Any(
                        block =>
                            (block.BlockerId == currentUserId &&
                             block.BlockedUserId == post.AuthorId) ||
                            (block.BlockerId == post.AuthorId &&
                             block.BlockedUserId == currentUserId)));

        var totalCount = await postsQuery.CountAsync(
            cancellationToken);

        var posts = await postsQuery
            .OrderByDescending(post => post.CreatedAtUtc)
            .ThenByDescending(post => post.Id)
            .Skip((requestedPage - 1) * requestedPageSize)
            .Take(requestedPageSize)
            .Select(
                post => new
                {
                    id = post.Id,
                    content = post.Content,
                    createdAtUtc = post.CreatedAtUtc,
                    author = new
                    {
                        id = post.Author.Id,
                        username = post.Author.Username,
                        displayName = post.Author.DisplayName,
                    },
                })
            .ToListAsync(cancellationToken);

        return Results.Ok(
            new
            {
                items = posts,
                page = requestedPage,
                pageSize = requestedPageSize,
                totalCount,
                hasNextPage =
                    requestedPage * requestedPageSize < totalCount,
            });
    }

    private static async Task<IResult> GetMentionSuggestionsAsync(
        string? q,
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

        var query = NormalizeSearchQuery(q);

        if (query.Length == 0)
        {
            return Results.Ok(Array.Empty<object>());
        }

        var users = await db.Users
            .AsNoTracking()
            .Where(
                user =>
                    user.NormalizedUsername.StartsWith(query) &&
                    !db.Blocks.Any(
                        block =>
                            (block.BlockerId == currentUserId &&
                             block.BlockedUserId == user.Id) ||
                            (block.BlockerId == user.Id &&
                             block.BlockedUserId == currentUserId)))
            .OrderBy(user => user.NormalizedUsername)
            .ThenBy(user => user.Id)
            .Take(DefaultPageSize)
            .Select(
                user => new
                {
                    id = user.Id,
                    username = user.Username,
                    displayName = user.DisplayName,
                })
            .ToListAsync(cancellationToken);

        return Results.Ok(users);
    }

    internal static async Task<IResult> ResolveMentionsAsync(
        string? content,
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

        var tokens = ExtractCanonicalMentions(content);

        if (tokens.Count == 0)
        {
            return Results.Ok(Array.Empty<object>());
        }

        var normalizedNames = tokens
            .Select(token => token.ToUpperInvariant())
            .Distinct(StringComparer.Ordinal)
            .ToArray();

        var users = await db.Users
            .AsNoTracking()
            .Where(
                user =>
                    normalizedNames.Contains(
                        user.NormalizedUsername) &&
                    !db.Blocks.Any(
                        block =>
                            (block.BlockerId == currentUserId &&
                             block.BlockedUserId == user.Id) ||
                            (block.BlockerId == user.Id &&
                             block.BlockedUserId == currentUserId)))
            .OrderBy(user => user.NormalizedUsername)
            .ThenBy(user => user.Id)
            .Select(
                user => new
                {
                    id = user.Id,
                    username = user.Username,
                    displayName = user.DisplayName,
                })
            .ToListAsync(cancellationToken);

        return Results.Ok(users);
    }

    private static List<string> ExtractCanonicalMentions(
        string? content)
    {
        if (string.IsNullOrWhiteSpace(content))
        {
            return [];
        }

        return MentionRegex
            .Matches(content)
            .Select(match => match.Groups[1].Value)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();
    }

    private static string NormalizeSearchQuery(
        string? value)
    {
        var normalized = value?.Trim() ?? string.Empty;

        if (normalized.StartsWith(
                "@",
                StringComparison.Ordinal))
        {
            normalized = normalized[1..];
        }

        return normalized.ToUpperInvariant();
    }

    private static int NormalizePage(
        int? page)
    {
        return page.GetValueOrDefault(1) < 1
            ? 1
            : page.Value;
    }

    private static int NormalizePageSize(
        int? pageSize)
    {
        var value =
            pageSize.GetValueOrDefault(DefaultPageSize);

        if (value < 1)
        {
            return DefaultPageSize;
        }

        return Math.Min(value, MaxPageSize);
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
                new ApiErrorResponse(
                    "User was not found."));
        }

        if (await HasBlockRelationshipAsync(
                db,
                currentUserId,
                user.Id,
                cancellationToken))
        {
            return Results.NotFound(
                new ApiErrorResponse(
                    "User was not found."));
        }

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
                new ApiErrorResponse(
                    "User was not found."));
        }

        if (await HasBlockRelationshipAsync(
                db,
                currentUserId,
                user.Id,
                cancellationToken))
        {
            return Results.NotFound(
                new ApiErrorResponse(
                    "User was not found."));
        }

        var posts = await db.Posts
            .AsNoTracking()
            .Include(post => post.Author)
            .Where(
                post =>
                    post.AuthorId == user.Id &&
                    post.ParentPostId == null &&
                    post.DeletedAt == null)
            .ToListAsync(cancellationToken);

        var orderedPosts = posts
            .OrderByDescending(
                post => post.CreatedAtUtc)
            .ThenByDescending(
                post => post.Id)
            .ToList();

        var items =
            new List<PostResponse>(
                orderedPosts.Count);

        foreach (var post in orderedPosts)
        {
            items.Add(
                await PostEndpoints.ToResponseAsync(
                    db,
                    post,
                    currentUserId,
                    cancellationToken));
        }

        return Results.Ok(
            new FeedListResponse(items));
    }

    private static async Task<ProfileResponse>
        CreateProfileResponseAsync(
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
                    post.ParentPostId == null &&
                    post.DeletedAt == null,
                cancellationToken);

        var followerCount = await db.Follows
            .AsNoTracking()
            .CountAsync(
                follow =>
                    follow.FollowingId == user.Id,
                cancellationToken);

        var followingCount = await db.Follows
            .AsNoTracking()
            .CountAsync(
                follow =>
                    follow.FollowerId == user.Id,
                cancellationToken);

        var isFollowedByCurrentUser =
            user.Id != currentUserId &&
            await db.Follows
                .AsNoTracking()
                .AnyAsync(
                    follow =>
                        follow.FollowerId ==
                        currentUserId &&
                        follow.FollowingId ==
                        user.Id,
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
            isFollowedByCurrentUser);
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

    private static string? NormalizeOptional(
        string? value)
    {
        var normalized =
            value?.Trim();

        return string.IsNullOrEmpty(
                normalized)
            ? null
            : normalized;
    }
}