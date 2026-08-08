using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using Pulse.Api.Auth;
using Pulse.Api.Contracts;
using Pulse.Api.Data;
using Pulse.Api.Domain;
using Pulse.Api.RateLimiting;

namespace Pulse.Api.Endpoints;

public static class MvpEndpoints
{
    public static IEndpointRouteBuilder MapMvpEndpoints(
        this IEndpointRouteBuilder endpoints)
    {
        var authGroup = endpoints
            .MapGroup("/api/v1/auth")
            .AllowAnonymous();

        authGroup.MapPost("/register", RegisterAsync);
        authGroup.MapPost("/login", LoginAsync);

        var apiGroup = endpoints
            .MapGroup("/api/v1")
            .RequireAuthorization();

        apiGroup.MapGet("/feed", GetFeedAsync);

        apiGroup.MapPost("/posts", CreatePostAsync);
        apiGroup.MapDelete("/posts/{postId:int}", DeletePostAsync);

        apiGroup.MapPost(
            "/posts/{postId:int}/replies",
            CreateReplyAsync);

        apiGroup.MapPost(
            "/posts/{postId:int}/reply",
            CreateReplyAsync);

        apiGroup.MapPost(
            "/posts/{postId:int}/likes",
            LikePostAsync);

        apiGroup.MapPost(
            "/posts/{postId:int}/like",
            LikePostAsync);

        apiGroup.MapDelete(
            "/posts/{postId:int}/likes",
            UnlikePostAsync);

        apiGroup.MapDelete(
            "/posts/{postId:int}/like",
            UnlikePostAsync);

        apiGroup.MapGet(
            "/profiles/me",
            GetCurrentProfileAsync);

        apiGroup.MapPut(
            "/profiles/me",
            UpdateCurrentProfileAsync);

        apiGroup.MapGet(
            "/profiles/{username}",
            GetProfileAsync);

        apiGroup.MapGet(
            "/profiles/{username}/posts",
            GetProfilePostsAsync);

        apiGroup.MapPost(
            "/profiles/{username}/follow",
            FollowAsync);

        apiGroup.MapDelete(
            "/profiles/{username}/follow",
            UnfollowAsync);

        apiGroup.MapPost(
            "/users/{username}/follow",
            FollowAsync);

        apiGroup.MapDelete(
            "/users/{username}/follow",
            UnfollowAsync);

        return endpoints;
    }

    private static async Task<IResult> RegisterAsync(
        RegisterBody request,
        HttpContext httpContext,
        PulseDbContext dbContext,
        PasswordService passwordService,
        JwtTokenService tokenService,
        AuthRateLimiter rateLimiter,
        CancellationToken cancellationToken)
    {
        var partition =
            httpContext.Connection.RemoteIpAddress?.ToString()
            ?? "unknown";

        if (!await rateLimiter.CheckRegisterAsync(
                partition,
                cancellationToken))
        {
            return Results.Json(
                new ApiErrorResponse(
                    "Too many registration attempts."),
                statusCode: StatusCodes.Status429TooManyRequests);
        }

        var username = request.Username?.Trim();
        var email = request.Email?.Trim();
        var displayName = request.DisplayName?.Trim();
        var password = request.Password;

        if (string.IsNullOrWhiteSpace(username)
            || username.Length is < 3 or > 30
            || username.Any(
                character =>
                    !char.IsLetterOrDigit(character)
                    && character != '_'))
        {
            return ValidationError(
                "Username must contain 3 to 30 letters, numbers, or underscores.",
                "username");
        }

        if (string.IsNullOrWhiteSpace(email)
            || email.Length > 254
            || !email.Contains('@'))
        {
            return ValidationError(
                "A valid email address is required.",
                "email");
        }

        if (string.IsNullOrWhiteSpace(displayName)
            || displayName.Length > 80)
        {
            return ValidationError(
                "Display name is required and cannot exceed 80 characters.",
                "displayName");
        }

        if (string.IsNullOrWhiteSpace(password)
            || password.Length < 8)
        {
            return ValidationError(
                "Password must contain at least 8 characters.",
                "password");
        }

        var normalizedUsername = Normalize(username);
        var normalizedEmail = Normalize(email);

        if (await dbContext.Users.AnyAsync(
                user =>
                    user.NormalizedUsername
                    == normalizedUsername,
                cancellationToken))
        {
            return Results.Conflict(
                new ApiErrorResponse(
                    "Username is already in use.",
                    "username"));
        }

        if (await dbContext.Users.AnyAsync(
                user =>
                    user.NormalizedEmail
                    == normalizedEmail,
                cancellationToken))
        {
            return Results.Conflict(
                new ApiErrorResponse(
                    "Email is already in use.",
                    "email"));
        }

        var user = new User
        {
            Username = username,
            NormalizedUsername = normalizedUsername,
            Email = email,
            NormalizedEmail = normalizedEmail,
            DisplayName = displayName,
            PasswordHash =
                passwordService.HashPassword(password),
            CreatedAtUtc = DateTimeOffset.UtcNow
        };

        dbContext.Users.Add(user);
        await dbContext.SaveChangesAsync(cancellationToken);

        var token = tokenService.CreateToken(user);

        return Results.Created(
            $"/api/v1/profiles/{user.Username}",
            CreateAuthResponse(user, token));
    }

    private static async Task<IResult> LoginAsync(
        LoginBody request,
        HttpContext httpContext,
        PulseDbContext dbContext,
        PasswordService passwordService,
        JwtTokenService tokenService,
        AuthRateLimiter rateLimiter,
        CancellationToken cancellationToken)
    {
        var login =
            request.Login
            ?? request.Email
            ?? request.Username;

        if (string.IsNullOrWhiteSpace(login)
            || string.IsNullOrWhiteSpace(request.Password))
        {
            return ValidationError(
                "Login and password are required.",
                null);
        }

        var partition =
            $"{httpContext.Connection.RemoteIpAddress}:{Normalize(login)}";

        if (!await rateLimiter.CheckLoginAsync(
                partition,
                cancellationToken))
        {
            return Results.Json(
                new ApiErrorResponse(
                    "Too many login attempts."),
                statusCode: StatusCodes.Status429TooManyRequests);
        }

        var normalizedLogin = Normalize(login);

        var user = await dbContext.Users
            .SingleOrDefaultAsync(
                candidate =>
                    candidate.NormalizedEmail
                    == normalizedLogin
                    || candidate.NormalizedUsername
                    == normalizedLogin,
                cancellationToken);

        if (user is null
            || !passwordService.VerifyPassword(
                request.Password,
                user.PasswordHash))
        {
            return Results.Unauthorized();
        }

        var token = tokenService.CreateToken(user);

        return Results.Ok(
            CreateAuthResponse(user, token));
    }

    private static async Task<IResult> CreatePostAsync(
        CreatePostRequest request,
        ClaimsPrincipal principal,
        PulseDbContext dbContext,
        CancellationToken cancellationToken)
    {
        var userId = GetRequiredUserId(principal);
        var content = request.Content?.Trim();

        if (string.IsNullOrWhiteSpace(content)
            || content.Length > 280)
        {
            return ValidationError(
                "Post content must contain between 1 and 280 characters.",
                "content");
        }

        var post = new Post
        {
            AuthorId = userId,
            Content = content,
            CreatedAtUtc = DateTimeOffset.UtcNow
        };

        dbContext.Posts.Add(post);
        await dbContext.SaveChangesAsync(cancellationToken);

        await dbContext.Entry(post)
            .Reference(item => item.Author)
            .LoadAsync(cancellationToken);

        return Results.Created(
            $"/api/v1/posts/{post.Id}",
            await CreatePostResponseAsync(
                dbContext,
                post,
                userId,
                cancellationToken));
    }

    private static async Task<IResult> DeletePostAsync(
        int postId,
        ClaimsPrincipal principal,
        PulseDbContext dbContext,
        CancellationToken cancellationToken)
    {
        var userId = GetRequiredUserId(principal);

        var post = await dbContext.Posts
            .SingleOrDefaultAsync(
                item => item.Id == postId,
                cancellationToken);

        if (post is null)
        {
            return Results.NotFound();
        }

        if (post.AuthorId != userId)
        {
            return Results.Forbid();
        }

        dbContext.Posts.Remove(post);
        await dbContext.SaveChangesAsync(cancellationToken);

        return Results.NoContent();
    }

    private static async Task<IResult> CreateReplyAsync(
        int postId,
        CreateReplyRequest request,
        ClaimsPrincipal principal,
        PulseDbContext dbContext,
        CancellationToken cancellationToken)
    {
        var userId = GetRequiredUserId(principal);
        var content = request.Content?.Trim();

        if (string.IsNullOrWhiteSpace(content)
            || content.Length > 280)
        {
            return ValidationError(
                "Reply content must contain between 1 and 280 characters.",
                "content");
        }

        var parentPost = await dbContext.Posts
            .AsNoTracking()
            .SingleOrDefaultAsync(
                post => post.Id == postId,
                cancellationToken);

        if (parentPost is null)
        {
            return Results.NotFound();
        }

        if (parentPost.ParentPostId.HasValue)
        {
            return ValidationError(
                "Replies cannot have replies.",
                "postId");
        }

        var reply = new Post
        {
            AuthorId = userId,
            ParentPostId = parentPost.Id,
            Content = content,
            CreatedAtUtc = DateTimeOffset.UtcNow
        };

        dbContext.Posts.Add(reply);
        await dbContext.SaveChangesAsync(cancellationToken);

        await dbContext.Entry(reply)
            .Reference(item => item.Author)
            .LoadAsync(cancellationToken);

        return Results.Created(
            $"/api/v1/posts/{reply.Id}",
            await CreatePostResponseAsync(
                dbContext,
                reply,
                userId,
                cancellationToken));
    }

    private static async Task<IResult> LikePostAsync(
        int postId,
        ClaimsPrincipal principal,
        PulseDbContext dbContext,
        CancellationToken cancellationToken)
    {
        var userId = GetRequiredUserId(principal);

        if (!await dbContext.Posts.AnyAsync(
                post => post.Id == postId,
                cancellationToken))
        {
            return Results.NotFound();
        }

        var like = await dbContext.PostLikes.FindAsync(
            new object[]
            {
                postId,
                userId
            },
            cancellationToken);

        if (like is null)
        {
            dbContext.PostLikes.Add(
                new PostLike
                {
                    PostId = postId,
                    UserId = userId,
                    CreatedAtUtc = DateTimeOffset.UtcNow
                });

            await dbContext.SaveChangesAsync(cancellationToken);
        }

        var likeCount = await dbContext.PostLikes.CountAsync(
            item => item.PostId == postId,
            cancellationToken);

        return Results.Created(
            $"/api/v1/posts/{postId}/likes",
            new LikeResponse(
                postId,
                true,
                likeCount));
    }

    private static async Task<IResult> UnlikePostAsync(
        int postId,
        ClaimsPrincipal principal,
        PulseDbContext dbContext,
        CancellationToken cancellationToken)
    {
        var userId = GetRequiredUserId(principal);

        var like = await dbContext.PostLikes.FindAsync(
            new object[]
            {
                postId,
                userId
            },
            cancellationToken);

        if (like is not null)
        {
            dbContext.PostLikes.Remove(like);
            await dbContext.SaveChangesAsync(cancellationToken);
        }

        return Results.NoContent();
    }

    private static async Task<IResult> FollowAsync(
        string username,
        ClaimsPrincipal principal,
        PulseDbContext dbContext,
        CancellationToken cancellationToken)
    {
        var currentUserId = GetRequiredUserId(principal);
        var normalizedUsername = Normalize(username);

        var targetUser = await dbContext.Users
            .SingleOrDefaultAsync(
                user =>
                    user.NormalizedUsername
                    == normalizedUsername,
                cancellationToken);

        if (targetUser is null)
        {
            return Results.NotFound();
        }

        if (targetUser.Id == currentUserId)
        {
            return ValidationError(
                "Users cannot follow themselves.",
                "username");
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

        var followerCount = await dbContext.Follows.CountAsync(
            item => item.FollowingId == targetUser.Id,
            cancellationToken);

        return Results.Created(
            $"/api/v1/profiles/{targetUser.Username}/follow",
            new FollowResponse(
                targetUser.Id,
                true,
                followerCount));
    }

    private static async Task<IResult> UnfollowAsync(
        string username,
        ClaimsPrincipal principal,
        PulseDbContext dbContext,
        CancellationToken cancellationToken)
    {
        var currentUserId = GetRequiredUserId(principal);
        var normalizedUsername = Normalize(username);

        var targetUser = await dbContext.Users
            .SingleOrDefaultAsync(
                user =>
                    user.NormalizedUsername
                    == normalizedUsername,
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

        return Results.NoContent();
    }

    private static async Task<IResult> GetFeedAsync(
        ClaimsPrincipal principal,
        PulseDbContext dbContext,
        CancellationToken cancellationToken)
    {
        var currentUserId = GetRequiredUserId(principal);

        var followedUserIds = await dbContext.Follows
            .Where(
                follow =>
                    follow.FollowerId
                    == currentUserId)
            .Select(follow => follow.FollowingId)
            .ToListAsync(cancellationToken);

        IQueryable<Post> query = dbContext.Posts
            .AsNoTracking()
            .Include(post => post.Author)
            .Where(post => post.ParentPostId == null);

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
                await CreatePostResponseAsync(
                    dbContext,
                    post,
                    currentUserId,
                    cancellationToken));
        }

        return Results.Ok(
            new PagedResponse<PostResponse>(
                responses,
                null));
    }

    private static async Task<IResult> GetCurrentProfileAsync(
        ClaimsPrincipal principal,
        PulseDbContext dbContext,
        CancellationToken cancellationToken)
    {
        var currentUserId = GetRequiredUserId(principal);

        var user = await dbContext.Users
            .AsNoTracking()
            .SingleOrDefaultAsync(
                item => item.Id == currentUserId,
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
        var currentUserId = GetRequiredUserId(principal);

        var user = await dbContext.Users
            .SingleOrDefaultAsync(
                item => item.Id == currentUserId,
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
            return ValidationError(
                "Display name is required and cannot exceed 80 characters.",
                "displayName");
        }

        if (bio?.Length > 160)
        {
            return ValidationError(
                "Bio cannot exceed 160 characters.",
                "bio");
        }

        if (avatarUrl?.Length > 2048)
        {
            return ValidationError(
                "Avatar URL cannot exceed 2048 characters.",
                "avatarUrl");
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
        var currentUserId = GetRequiredUserId(principal);
        var normalizedUsername = Normalize(username);

        var user = await dbContext.Users
            .AsNoTracking()
            .SingleOrDefaultAsync(
                item =>
                    item.NormalizedUsername
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
        var currentUserId = GetRequiredUserId(principal);
        var normalizedUsername = Normalize(username);

        var user = await dbContext.Users
            .AsNoTracking()
            .SingleOrDefaultAsync(
                item =>
                    item.NormalizedUsername
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

        var responses =
            new List<PostResponse>(posts.Count);

        foreach (var post in posts)
        {
            responses.Add(
                await CreatePostResponseAsync(
                    dbContext,
                    post,
                    currentUserId,
                    cancellationToken));
        }

        return Results.Ok(
            new PagedResponse<PostResponse>(
                responses,
                null));
    }

    private static async Task<PostResponse> CreatePostResponseAsync(
        PulseDbContext dbContext,
        Post post,
        int currentUserId,
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

        var likeCount = await dbContext.PostLikes.CountAsync(
            like => like.PostId == post.Id,
            cancellationToken);

        var replyCount = await dbContext.Posts.CountAsync(
            reply =>
                reply.ParentPostId
                == post.Id,
            cancellationToken);

        var isLiked = await dbContext.PostLikes.AnyAsync(
            like =>
                like.PostId == post.Id
                && like.UserId == currentUserId,
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
            isLiked);
    }

    private static async Task<ProfileResponse> CreateProfileResponseAsync(
        PulseDbContext dbContext,
        User user,
        int currentUserId,
        CancellationToken cancellationToken)
    {
        var postCount = await dbContext.Posts.CountAsync(
            post => post.AuthorId == user.Id,
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

    private static object CreateAuthResponse(
        User user,
        JwtTokenResult token)
    {
        return new
        {
            accessToken = token.AccessToken,
            token = token.AccessToken,
            tokenType = "Bearer",
            expiresIn = token.ExpiresIn,
            expiresAt = token.ExpiresAtUtc,
            user = new
            {
                user.Id,
                user.Username,
                user.DisplayName,
                user.Bio,
                user.AvatarUrl
            }
        };
    }

    private static int GetRequiredUserId(
        ClaimsPrincipal principal)
    {
        var claim =
            principal.FindFirst(ClaimTypes.NameIdentifier)
            ?? principal.FindFirst(JwtRegisteredClaimNames.Sub);

        if (!int.TryParse(claim?.Value, out var userId))
        {
            throw new InvalidOperationException(
                "Authenticated user identifier is missing.");
        }

        return userId;
    }

    private static string Normalize(
        string value)
    {
        return value.Trim().ToUpperInvariant();
    }

    private static IResult ValidationError(
        string error,
        string? field)
    {
        return Results.BadRequest(
            new ApiErrorResponse(
                error,
                field));
    }

    private sealed record RegisterBody(
        string? Username,
        string? Email,
        string? Password,
        string? DisplayName);

    private sealed record LoginBody(
        string? Login,
        string? Email,
        string? Username,
        string? Password);
}