using System.Security.Claims;
using System.Text.RegularExpressions;
using Microsoft.EntityFrameworkCore;
using Pulse.Api.Contracts;
using Pulse.Api.Data;
using Pulse.Api.Domain;
using Pulse.Api.Storage;

namespace Pulse.Api.Endpoints;

public static class SocialInteractionEndpoints
{
    private const int DefaultPageSize = 20;
    private const int MaxPageSize = 100;
    private const long MaxMediaBytes =
        25L * 1024L * 1024L;

    public static IEndpointRouteBuilder MapSocialInteractionEndpoints(
        this IEndpointRouteBuilder endpoints)
    {
        var posts = endpoints
            .MapGroup("/api/v1/posts")
            .RequireAuthorization();

        posts.MapGet(
            "/{postId:int}",
            GetPostAsync);

        posts.MapGet(
            "/{postId:int}/replies",
            GetRepliesAsync);

        posts.MapPost(
            "/{postId:int}/reposts",
            CreateRepostAsync);

        posts.MapDelete(
            "/{postId:int}/reposts",
            DeleteRepostAsync);

        posts.MapPost(
            "/{postId:int}/quotes",
            CreateQuoteAsync);

        posts.MapPost(
            "/{postId:int}/bookmarks",
            CreateBookmarkAsync);

        posts.MapDelete(
            "/{postId:int}/bookmarks",
            DeleteBookmarkAsync);

        endpoints.MapGet(
                "/api/v1/bookmarks",
                GetBookmarksAsync)
            .RequireAuthorization();

        endpoints.MapGet(
                "/api/v1/notifications",
                GetNotificationsAsync)
            .RequireAuthorization();

        endpoints.MapPut(
                "/api/v1/notifications/{notificationId:int}/read",
                SetNotificationReadAsync)
            .RequireAuthorization();

        endpoints.MapGet(
                "/api/v1/hashtags/{tag}/posts",
                GetHashtagPostsAsync)
            .RequireAuthorization();

        endpoints.MapPost(
                "/api/v1/media",
                UploadMediaAsync)
            .RequireAuthorization()
            .DisableAntiforgery();

        endpoints.MapGet(
                "/api/v1/media/{mediaId:int}/content",
                GetMediaContentAsync)
            .RequireAuthorization();

        return endpoints;
    }

    private static async Task<IResult> GetPostAsync(
        int postId,
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

        var post = await db.Posts
            .AsNoTracking()
            .Include(item => item.Author)
            .SingleOrDefaultAsync(
                item =>
                    item.Id == postId
                    && item.DeletedAt == null,
                cancellationToken);

        if (post is null)
        {
            return Results.NotFound();
        }

        return Results.Ok(
            await PostEndpoints.ToResponseAsync(
                db,
                post,
                currentUserId,
                cancellationToken));
    }

    private static async Task<IResult> GetRepliesAsync(
        int postId,
        ClaimsPrincipal principal,
        PulseDbContext db,
        string? cursor,
        int? limit,
        CancellationToken cancellationToken)
    {
        if (!PostEndpoints.TryGetUserId(
                principal,
                out var currentUserId))
        {
            return Results.Unauthorized();
        }

        var parentExists =
            await db.Posts
                .AsNoTracking()
                .AnyAsync(
                    item =>
                        item.Id == postId
                        && item.DeletedAt == null,
                    cancellationToken);

        if (!parentExists)
        {
            return Results.NotFound();
        }

        var pageSize = PageSize(limit);

        IQueryable<Post> query =
            db.Posts
                .AsNoTracking()
                .Include(item => item.Author)
                .Where(
                    item =>
                        item.ParentPostId == postId
                        && item.DeletedAt == null);

        if (int.TryParse(cursor, out var cursorId))
        {
            query =
                query.Where(item => item.Id < cursorId);
        }

        var posts = await query
            .OrderByDescending(item => item.CreatedAtUtc)
            .ThenByDescending(item => item.Id)
            .Take(pageSize + 1)
            .ToListAsync(cancellationToken);

        var nextCursor =
            TrimPage(
                posts,
                pageSize);

        var items =
            await MapPostsAsync(
                db,
                posts,
                currentUserId,
                cancellationToken);

        return Results.Ok(
            new PagedResponse<PostResponse>(
                items,
                nextCursor));
    }

    private static async Task<IResult> CreateRepostAsync(
        int postId,
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

        var originalPost = await db.Posts
            .AsNoTracking()
            .SingleOrDefaultAsync(
                item =>
                    item.Id == postId
                    && item.DeletedAt == null,
                cancellationToken);

        if (originalPost is null)
        {
            return Results.NotFound();
        }

        var existing =
            await db.Posts
                .AsNoTracking()
                .AnyAsync(
                    item =>
                        item.AuthorId == currentUserId
                        && item.OriginalPostId == postId
                        && item.Kind == PostKind.Repost
                        && item.DeletedAt == null,
                    cancellationToken);

        if (existing)
        {
            return Results.Conflict(
                new ApiErrorResponse(
                    "An active repost already exists."));
        }

        var repost = new Post
        {
            AuthorId = currentUserId,
            Content = string.Empty,
            Kind = PostKind.Repost,
            OriginalPostId = postId,
            CreatedAtUtc = DateTimeOffset.UtcNow
        };

        db.Posts.Add(repost);

        try
        {
            await db.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException)
        {
            return Results.Conflict(
                new ApiErrorResponse(
                    "An active repost already exists."));
        }

        await db.Entry(repost)
            .Reference(item => item.Author)
            .LoadAsync(cancellationToken);

        return Results.Created(
            $"/api/v1/posts/{repost.Id}",
            await PostEndpoints.ToResponseAsync(
                db,
                repost,
                currentUserId,
                cancellationToken));
    }

    private static async Task<IResult> DeleteRepostAsync(
        int postId,
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

        var repost = await db.Posts
            .SingleOrDefaultAsync(
                item =>
                    item.AuthorId == currentUserId
                    && item.OriginalPostId == postId
                    && item.Kind == PostKind.Repost
                    && item.DeletedAt == null,
                cancellationToken);

        if (repost is null)
        {
            return Results.NotFound();
        }

        repost.DeletedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(cancellationToken);

        return Results.NoContent();
    }
    private static async Task<IResult> CreateQuoteAsync(
        int postId,
        CreateQuoteRequest request,
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

        var content = request.Content?.Trim();

        if (string.IsNullOrWhiteSpace(content)
            || content.Length > 280)
        {
            return ValidationError(
                "Quote content must contain between 1 and 280 characters.",
                "content");
        }

        var originalExists =
            await db.Posts
                .AsNoTracking()
                .AnyAsync(
                    item =>
                        item.Id == postId
                        && item.DeletedAt == null,
                    cancellationToken);

        if (!originalExists)
        {
            return Results.NotFound();
        }

        var mediaIds =
            request.MediaIds?
                .Distinct()
                .ToArray()
            ?? Array.Empty<int>();

        var media =
            mediaIds.Length == 0
                ? new List<PostMedia>()
                : await db.PostMedia
                    .Where(
                        item =>
                            mediaIds.Contains(item.Id)
                            && item.OwnerUserId == currentUserId
                            && item.PostId == null)
                    .ToListAsync(cancellationToken);

        if (media.Count != mediaIds.Length)
        {
            return ValidationError(
                "One or more mediaIds are invalid, already attached, or owned by another user.",
                "mediaIds");
        }

        var quote = new Post
        {
            AuthorId = currentUserId,
            Content = content,
            Kind = PostKind.Quote,
            OriginalPostId = postId,
            CreatedAtUtc = DateTimeOffset.UtcNow
        };

        db.Posts.Add(quote);
        await db.SaveChangesAsync(cancellationToken);

        foreach (var item in media)
        {
            item.PostId = quote.Id;
        }

        await SocialInteractionService.IndexContentAsync(
            db,
            quote,
            currentUserId,
            content,
            cancellationToken);

        await db.SaveChangesAsync(cancellationToken);

        await db.Entry(quote)
            .Reference(item => item.Author)
            .LoadAsync(cancellationToken);

        return Results.Created(
            $"/api/v1/posts/{quote.Id}",
            await PostEndpoints.ToResponseAsync(
                db,
                quote,
                currentUserId,
                cancellationToken));
    }

    private static async Task<IResult> CreateBookmarkAsync(
        int postId,
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

        var postExists =
            await db.Posts
                .AsNoTracking()
                .AnyAsync(
                    item =>
                        item.Id == postId
                        && item.DeletedAt == null,
                    cancellationToken);

        if (!postExists)
        {
            return Results.NotFound();
        }

        var existing =
            await db.Bookmarks.FindAsync(
                new object[]
                {
                    currentUserId,
                    postId
                },
                cancellationToken);

        if (existing is null)
        {
            db.Bookmarks.Add(
                new Bookmark
                {
                    UserId = currentUserId,
                    PostId = postId,
                    CreatedAtUtc =
                        DateTimeOffset.UtcNow
                });

            try
            {
                await db.SaveChangesAsync(
                    cancellationToken);
            }
            catch (DbUpdateException)
            {
                db.ChangeTracker.Clear();
            }
        }

        return Results.NoContent();
    }

    private static async Task<IResult> DeleteBookmarkAsync(
        int postId,
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

        var bookmark =
            await db.Bookmarks.FindAsync(
                new object[]
                {
                    currentUserId,
                    postId
                },
                cancellationToken);

        if (bookmark is null)
        {
            return Results.NotFound();
        }

        db.Bookmarks.Remove(bookmark);
        await db.SaveChangesAsync(cancellationToken);

        return Results.NoContent();
    }

    private static async Task<IResult> GetBookmarksAsync(
        ClaimsPrincipal principal,
        PulseDbContext db,
        string? cursor,
        int? limit,
        CancellationToken cancellationToken)
    {
        if (!PostEndpoints.TryGetUserId(
                principal,
                out var currentUserId))
        {
            return Results.Unauthorized();
        }

        var pageSize = PageSize(limit);

        IQueryable<Bookmark> query =
            db.Bookmarks
                .AsNoTracking()
                .Where(
                    item =>
                        item.UserId == currentUserId
                        && item.Post.DeletedAt == null);

        if (int.TryParse(cursor, out var cursorPostId))
        {
            query =
                query.Where(
                    item =>
                        item.PostId < cursorPostId);
        }

        var bookmarks = await query
            .Include(item => item.Post)
                .ThenInclude(post => post.Author)
            .OrderByDescending(item => item.CreatedAtUtc)
            .ThenByDescending(item => item.PostId)
            .Take(pageSize + 1)
            .ToListAsync(cancellationToken);

        string? nextCursor = null;

        if (bookmarks.Count > pageSize)
        {
            bookmarks.RemoveAt(
                bookmarks.Count - 1);

            nextCursor =
                bookmarks[^1]
                    .PostId
                    .ToString();
        }

        var posts =
            bookmarks
                .Select(item => item.Post)
                .ToList();

        var items =
            await MapPostsAsync(
                db,
                posts,
                currentUserId,
                cancellationToken);

        return Results.Ok(
            new PagedResponse<PostResponse>(
                items,
                nextCursor));
    }
    private static async Task<IResult> GetNotificationsAsync(
        ClaimsPrincipal principal,
        PulseDbContext db,
        string? cursor,
        int? limit,
        CancellationToken cancellationToken)
    {
        if (!PostEndpoints.TryGetUserId(
                principal,
                out var currentUserId))
        {
            return Results.Unauthorized();
        }

        var pageSize = PageSize(limit);

        IQueryable<Notification> query =
            db.Notifications
                .AsNoTracking()
                .Include(item => item.ActorUser)
                .Where(
                    item =>
                        item.RecipientUserId
                        == currentUserId);

        if (int.TryParse(cursor, out var cursorId))
        {
            query =
                query.Where(item => item.Id < cursorId);
        }

        var notifications =
            await query
                .OrderByDescending(
                    item => item.CreatedAtUtc)
                .ThenByDescending(
                    item => item.Id)
                .Take(pageSize + 1)
                .ToListAsync(cancellationToken);

        string? nextCursor = null;

        if (notifications.Count > pageSize)
        {
            notifications.RemoveAt(
                notifications.Count - 1);

            nextCursor =
                notifications[^1]
                    .Id
                    .ToString();
        }

        var items =
            notifications
                .Select(ToNotificationResponse)
                .ToList();

        return Results.Ok(
            new NotificationListResponse(
                items,
                nextCursor));
    }

    private static async Task<IResult> SetNotificationReadAsync(
        int notificationId,
        SetNotificationReadRequest request,
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

        var notification =
            await db.Notifications
                .Include(item => item.ActorUser)
                .SingleOrDefaultAsync(
                    item =>
                        item.Id == notificationId
                        && item.RecipientUserId
                            == currentUserId,
                    cancellationToken);

        if (notification is null)
        {
            return Results.NotFound();
        }

        notification.IsRead = request.IsRead;
        await db.SaveChangesAsync(cancellationToken);

        return Results.Ok(
            ToNotificationResponse(
                notification));
    }

    private static async Task<IResult> GetHashtagPostsAsync(
        string tag,
        ClaimsPrincipal principal,
        PulseDbContext db,
        string? cursor,
        int? limit,
        CancellationToken cancellationToken)
    {
        if (!PostEndpoints.TryGetUserId(
                principal,
                out var currentUserId))
        {
            return Results.Unauthorized();
        }

        var normalizedTag =
            NormalizeTag(tag);

        if (string.IsNullOrWhiteSpace(
                normalizedTag))
        {
            return Results.Ok(
                new HashtagPostListResponse(
                    normalizedTag,
                    Array.Empty<PostResponse>(),
                    null));
        }

        var hashtagId =
            await db.Hashtags
                .AsNoTracking()
                .Where(
                    item =>
                        item.NormalizedTag
                        == normalizedTag)
                .Select(item => (int?)item.Id)
                .SingleOrDefaultAsync(
                    cancellationToken);

        if (!hashtagId.HasValue)
        {
            return Results.Ok(
                new HashtagPostListResponse(
                    normalizedTag,
                    Array.Empty<PostResponse>(),
                    null));
        }

        var pageSize = PageSize(limit);

        IQueryable<PostHashtag> query =
            db.PostHashtags
                .AsNoTracking()
                .Where(
                    item =>
                        item.HashtagId
                            == hashtagId.Value
                        && item.Post.DeletedAt
                            == null);

        if (int.TryParse(cursor, out var cursorPostId))
        {
            query =
                query.Where(
                    item =>
                        item.PostId < cursorPostId);
        }

        var relations =
            await query
                .Include(item => item.Post)
                    .ThenInclude(post => post.Author)
                .OrderByDescending(
                    item =>
                        item.Post.CreatedAtUtc)
                .ThenByDescending(
                    item => item.PostId)
                .Take(pageSize + 1)
                .ToListAsync(cancellationToken);

        string? nextCursor = null;

        if (relations.Count > pageSize)
        {
            relations.RemoveAt(
                relations.Count - 1);

            nextCursor =
                relations[^1]
                    .PostId
                    .ToString();
        }

        var items =
            await MapPostsAsync(
                db,
                relations
                    .Select(item => item.Post)
                    .ToList(),
                currentUserId,
                cancellationToken);

        return Results.Ok(
            new HashtagPostListResponse(
                normalizedTag,
                items,
                nextCursor));
    }

    private static async Task<IResult> UploadMediaAsync(
        IFormFile file,
        HttpContext httpContext,
        ClaimsPrincipal principal,
        PulseDbContext db,
        MinioObjectStore objectStore,
        CancellationToken cancellationToken)
    {
        if (!PostEndpoints.TryGetUserId(
                principal,
                out var currentUserId))
        {
            return Results.Unauthorized();
        }

        if (file.Length <= 0)
        {
            return ValidationError(
                "file is required.",
                "file");
        }

        if (file.Length > MaxMediaBytes)
        {
            return ValidationError(
                "Media cannot exceed 25 MB.",
                "file");
        }

        var contentType =
            file.ContentType?
                .Trim()
                .ToLowerInvariant()
            ?? string.Empty;

        MediaType mediaType;

        if (contentType.StartsWith(
                "image/",
                StringComparison.Ordinal))
        {
            mediaType = MediaType.Image;
        }
        else if (contentType.StartsWith(
                     "video/",
                     StringComparison.Ordinal))
        {
            mediaType = MediaType.Video;
        }
        else
        {
            return ValidationError(
                "Only image and video media are supported.",
                "file");
        }
        await using var stream =
            file.OpenReadStream();

        using var buffer =
            new MemoryStream();

        await stream.CopyToAsync(
            buffer,
            cancellationToken);

        var bytes = buffer.ToArray();

        int? width = null;
        int? height = null;

        if (mediaType == MediaType.Image)
        {
            (width, height) =
                TryReadImageDimensions(
                    bytes,
                    contentType);
        }

        var extension =
            Path.GetExtension(
                file.FileName);

        if (extension.Length > 16)
        {
            extension = string.Empty;
        }

        var objectKey =
            $"users/{currentUserId}/{Guid.NewGuid():N}{extension.ToLowerInvariant()}";

        await objectStore.PutAsync(
            objectKey,
            bytes,
            contentType,
            cancellationToken);

        var media = new PostMedia
        {
            OwnerUserId = currentUserId,
            ObjectKey = objectKey,
            MediaType = mediaType,
            ContentType = contentType,
            Width = width,
            Height = height,
            CreatedAtUtc =
                DateTimeOffset.UtcNow
        };

        db.PostMedia.Add(media);
        await db.SaveChangesAsync(cancellationToken);

        media.Url =
            $"{httpContext.Request.Scheme}://{httpContext.Request.Host}/api/v1/media/{media.Id}/content";

        await db.SaveChangesAsync(cancellationToken);

        return Results.Created(
            $"/api/v1/media/{media.Id}",
            new MediaUploadResponse(
                media.Id,
                media.Url,
                media.MediaType.ToString(),
                media.ContentType,
                media.Width,
                media.Height));
    }

    private static async Task<IResult> GetMediaContentAsync(
        int mediaId,
        PulseDbContext db,
        MinioObjectStore objectStore,
        CancellationToken cancellationToken)
    {
        var media =
            await db.PostMedia
                .AsNoTracking()
                .SingleOrDefaultAsync(
                    item => item.Id == mediaId,
                    cancellationToken);

        if (media is null)
        {
            return Results.NotFound();
        }

        var bytes =
            await objectStore.GetAsync(
                media.ObjectKey,
                cancellationToken);

        return Results.File(
            bytes,
            media.ContentType);
    }

    private static NotificationResponse ToNotificationResponse(
        Notification notification)
    {
        return new NotificationResponse(
            notification.Id,
            notification.Type.ToString(),
            notification.ActorUserId,
            notification.ActorUser.Username,
            notification.PostId,
            notification.IsRead,
            notification.CreatedAtUtc);
    }

    private static async Task<List<PostResponse>> MapPostsAsync(
        PulseDbContext db,
        IReadOnlyList<Post> posts,
        int currentUserId,
        CancellationToken cancellationToken)
    {
        var items =
            new List<PostResponse>(
                posts.Count);

        foreach (var post in posts)
        {
            items.Add(
                await PostEndpoints.ToResponseAsync(
                    db,
                    post,
                    currentUserId,
                    cancellationToken));
        }

        return items;
    }

    private static int PageSize(
        int? limit)
    {
        return Math.Clamp(
            limit ?? DefaultPageSize,
            1,
            MaxPageSize);
    }

    private static string? TrimPage(
        List<Post> posts,
        int pageSize)
    {
        if (posts.Count <= pageSize)
        {
            return null;
        }

        posts.RemoveAt(
            posts.Count - 1);

        return posts[^1]
            .Id
            .ToString();
    }

    private static string NormalizeTag(
        string tag)
    {
        return tag
            .Trim()
            .TrimStart('#')
            .ToLowerInvariant();
    }

    private static (int? Width, int? Height)
        TryReadImageDimensions(
            byte[] bytes,
            string contentType)
    {
        if (contentType == "image/png"
            && bytes.Length >= 24
            && bytes[0] == 0x89
            && bytes[1] == 0x50
            && bytes[2] == 0x4E
            && bytes[3] == 0x47)
        {
            return (
                ReadInt32BigEndian(
                    bytes,
                    16),
                ReadInt32BigEndian(
                    bytes,
                    20));
        }

        if ((contentType == "image/jpeg"
             || contentType == "image/jpg")
            && bytes.Length > 4
            && bytes[0] == 0xFF
            && bytes[1] == 0xD8)
        {
            var index = 2;

            while (index + 9 < bytes.Length)
            {
                if (bytes[index] != 0xFF)
                {
                    index++;
                    continue;
                }

                var marker =
                    bytes[index + 1];

                if (marker is 0xC0
                    or 0xC1
                    or 0xC2
                    or 0xC3
                    or 0xC5
                    or 0xC6
                    or 0xC7
                    or 0xC9
                    or 0xCA
                    or 0xCB
                    or 0xCD
                    or 0xCE
                    or 0xCF)
                {
                    var height =
                        (bytes[index + 5] << 8)
                        | bytes[index + 6];

                    var width =
                        (bytes[index + 7] << 8)
                        | bytes[index + 8];

                    return (
                        width,
                        height);
                }

                if (index + 3 >= bytes.Length)
                {
                    break;
                }

                var length =
                    (bytes[index + 2] << 8)
                    | bytes[index + 3];

                if (length < 2)
                {
                    break;
                }

                index +=
                    length + 2;
            }
        }

        return (null, null);
    }

    private static int ReadInt32BigEndian(
        byte[] bytes,
        int offset)
    {
        return (bytes[offset] << 24)
            | (bytes[offset + 1] << 16)
            | (bytes[offset + 2] << 8)
            | bytes[offset + 3];
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
}
internal static class SocialInteractionService
{
    private static readonly Regex MentionRegex =
        new(
            @"(?<![\p{L}\p{N}_@])@([\p{L}\p{N}_]{3,30})",
            RegexOptions.Compiled
            | RegexOptions.CultureInvariant);

    private static readonly Regex HashtagRegex =
        new(
            @"(?<![\p{L}\p{N}_#])#([\p{L}\p{N}_]{1,64})",
            RegexOptions.Compiled
            | RegexOptions.CultureInvariant);

    public static async Task IndexContentAsync(
        PulseDbContext db,
        Post post,
        int authorUserId,
        string content,
        CancellationToken cancellationToken)
    {
        var mentionNames =
            MentionRegex
                .Matches(content)
                .Select(
                    match =>
                        match.Groups[1]
                            .Value
                            .Trim()
                            .ToUpperInvariant())
                .Distinct(
                    StringComparer.Ordinal)
                .ToArray();

        if (mentionNames.Length > 0)
        {
            var mentionedUsers =
                await db.Users
                    .AsNoTracking()
                    .Where(
                        user =>
                            user.IsActive
                            && mentionNames.Contains(
                                user.NormalizedUsername))
                    .ToListAsync(
                        cancellationToken);

            foreach (var user in mentionedUsers)
            {
                var mentionExists =
                    await db.PostMentions
                        .AnyAsync(
                            mention =>
                                mention.PostId == post.Id
                                && mention.MentionedUserId
                                    == user.Id,
                            cancellationToken);

                if (!mentionExists)
                {
                    db.PostMentions.Add(
                        new PostMention
                        {
                            PostId = post.Id,
                            MentionedUserId =
                                user.Id,
                            CreatedAtUtc =
                                DateTimeOffset.UtcNow
                        });
                }

                await CreateNotificationAsync(
                    db,
                    user.Id,
                    authorUserId,
                    NotificationType.Mention,
                    post.Id,
                    $"mention:{post.Id}:{user.Id}",
                    cancellationToken);
            }
        }

        var tags =
            HashtagRegex
                .Matches(content)
                .Select(
                    match =>
                        match.Groups[1]
                            .Value
                            .Trim()
                            .ToLowerInvariant())
                .Where(
                    tag =>
                        !string.IsNullOrWhiteSpace(tag))
                .Distinct(
                    StringComparer.Ordinal)
                .ToArray();

        foreach (var tag in tags)
        {
            var hashtag =
                await db.Hashtags
                    .SingleOrDefaultAsync(
                        item =>
                            item.NormalizedTag
                            == tag,
                        cancellationToken);

            if (hashtag is null)
            {
                hashtag =
                    new Hashtag
                    {
                        Tag = tag,
                        NormalizedTag = tag
                    };

                db.Hashtags.Add(hashtag);
            }

            db.PostHashtags.Add(
                new PostHashtag
                {
                    Post = post,
                    Hashtag = hashtag
                });
        }
    }

    public static async Task CreateNotificationAsync(
        PulseDbContext db,
        int recipientUserId,
        int actorUserId,
        NotificationType type,
        int? postId,
        string sourceKey,
        CancellationToken cancellationToken)
    {
        if (recipientUserId == actorUserId)
        {
            return;
        }

        var exists =
            await db.Notifications
                .AnyAsync(
                    notification =>
                        notification.RecipientUserId
                            == recipientUserId
                        && notification.Type
                            == type
                        && notification.SourceKey
                            == sourceKey,
                    cancellationToken);

        if (exists)
        {
            return;
        }

        db.Notifications.Add(
            new Notification
            {
                RecipientUserId =
                    recipientUserId,
                ActorUserId =
                    actorUserId,
                Type = type,
                PostId = postId,
                SourceKey = sourceKey,
                IsRead = false,
                CreatedAtUtc =
                    DateTimeOffset.UtcNow
            });
    }
}