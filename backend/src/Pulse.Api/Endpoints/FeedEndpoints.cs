using System.Globalization;
using System.Security.Claims;
using System.Text;
using Microsoft.EntityFrameworkCore;
using Pulse.Api.Contracts;
using Pulse.Api.Data;

namespace Pulse.Api.Endpoints;

public static class FeedEndpoints
{
    private const int PageSize = 20;

    public static IEndpointRouteBuilder MapFeedEndpoints(
        this IEndpointRouteBuilder endpoints)
    {
        endpoints.MapGet(
                "/api/v1/feed",
                GetFeedAsync)
            .RequireAuthorization();

        return endpoints;
    }

    private static async Task<IResult> GetFeedAsync(
        string? cursor,
        ClaimsPrincipal principal,
        PulseDbContext db,
        CancellationToken cancellationToken)
    {
        if (!PostEndpoints.TryGetUserId(principal, out var userId))
        {
            return Results.Unauthorized();
        }

        if (!TryDecodeCursor(cursor, out var beforeId))
        {
            return Results.BadRequest(
                new ApiErrorResponse(
                    "Cursor is invalid.",
                    "cursor"));
        }

        var followingIds = await db.Follows
            .AsNoTracking()
            .Where(x => x.FollowerId == userId)
            .Select(x => x.FollowingId)
            .ToListAsync(cancellationToken);

        var blockedIds = await db.Blocks
            .AsNoTracking()
            .Where(x =>
                x.BlockerId == userId ||
                x.BlockedUserId == userId)
            .Select(x =>
                x.BlockerId == userId
                    ? x.BlockedUserId
                    : x.BlockerId)
            .ToListAsync(cancellationToken);

        var query = db.Posts
            .AsNoTracking()
            .Include(x => x.Author)
            .Where(x =>
                x.ParentPostId == null &&
                x.DeletedAt == null &&
                x.Author.IsActive &&
                !blockedIds.Contains(x.AuthorId));

        if (followingIds.Count > 0)
        {
            query = query.Where(x =>
                x.AuthorId == userId ||
                followingIds.Contains(x.AuthorId));
        }

        if (beforeId.HasValue)
        {
            var id = beforeId.Value;
            query = query.Where(x => x.Id < id);
        }

        var posts = await query
            .OrderByDescending(x => x.Id)
            .Take(PageSize + 1)
            .ToListAsync(cancellationToken);

        var hasMore = posts.Count > PageSize;
        var page = posts.Take(PageSize).ToList();
        var items = new List<PostResponse>(page.Count);

        foreach (var post in page)
        {
            items.Add(
                await PostEndpoints.ToResponseAsync(
                    db,
                    post,
                    userId,
                    cancellationToken));
        }

        var nextCursor =
            hasMore && page.Count > 0
                ? EncodeCursor(page[^1].Id)
                : null;

        return Results.Ok(
            new PagedResponse<PostResponse>(
                items,
                nextCursor));
    }

    private static string EncodeCursor(int postId)
    {
        var value = postId.ToString(
            CultureInfo.InvariantCulture);

        return Convert.ToBase64String(
                Encoding.UTF8.GetBytes(value))
            .TrimEnd('=')
            .Replace('+', '-')
            .Replace('/', '_');
    }

    private static bool TryDecodeCursor(
        string? cursor,
        out int? postId)
    {
        postId = null;

        if (string.IsNullOrWhiteSpace(cursor))
        {
            return true;
        }

        try
        {
            var encoded = cursor
                .Replace('-', '+')
                .Replace('_', '/');

            var padding =
                (4 - encoded.Length % 4) % 4;

            encoded = encoded.PadRight(
                encoded.Length + padding,
                '=');

            var value = Encoding.UTF8.GetString(
                Convert.FromBase64String(encoded));

            if (!int.TryParse(
                    value,
                    NumberStyles.None,
                    CultureInfo.InvariantCulture,
                    out var parsedId) ||
                parsedId <= 0)
            {
                return false;
            }

            postId = parsedId;
            return true;
        }
        catch (FormatException)
        {
            return false;
        }
    }
}