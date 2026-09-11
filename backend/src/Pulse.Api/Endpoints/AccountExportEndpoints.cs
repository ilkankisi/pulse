using System.Security.Claims;

using Microsoft.EntityFrameworkCore;

using Pulse.Api.Contracts;

using Pulse.Api.Data;

namespace Pulse.Api.Endpoints;

public static class AccountExportEndpoints

{

public static IEndpointRouteBuilder MapAccountExportEndpoints(
this IEndpointRouteBuilder endpoints)
{
var group = endpoints
.MapGroup("/api/v1/me")
.RequireAuthorization();
group.MapGet(
"/export",
ExportAccountDataAsync);
return endpoints;
}

private static async Task<IResult> ExportAccountDataAsync(

ClaimsPrincipal principal,

PulseDbContext db,

CancellationToken cancellationToken)

{

if (!PostEndpoints.TryGetUserId(principal, out var currentUserId))

{

return Results.Unauthorized();

}

var user = await db.Users
    .AsNoTracking()
    .Where(candidate => candidate.Id == currentUserId)
    .Select(candidate => new
    {
        candidate.Id,
        candidate.Username,
        candidate.DisplayName,
        candidate.Email,
        candidate.AvatarUrl,
        candidate.Bio,
        candidate.CreatedAtUtc,
    })
    .SingleOrDefaultAsync(cancellationToken);

if (user is null)
{
    return Results.NotFound(
        new ApiErrorResponse("User was not found."));
}

var posts = await db.Posts
    .AsNoTracking()
    .Where(post => post.AuthorId == currentUserId)
    .OrderBy(post => post.CreatedAtUtc)
    .Select(post => new
    {
        post.Id,
        post.Content,
        post.ParentPostId,
        post.CreatedAtUtc,
    })
    .ToListAsync(cancellationToken);

var likes = await db.PostLikes
    .AsNoTracking()
    .Where(like => like.UserId == currentUserId)
    .OrderBy(like => like.CreatedAtUtc)
    .Select(like => new
    {
        like.PostId,
        like.CreatedAtUtc,
    })
    .ToListAsync(cancellationToken);

var following = await db.Follows
    .AsNoTracking()
    .Where(follow => follow.FollowerId == currentUserId)
    .OrderBy(follow => follow.CreatedAtUtc)
    .Select(follow => new
    {
        userId = follow.FollowingId,
        follow.CreatedAtUtc,
    })
    .ToListAsync(cancellationToken);

var followers = await db.Follows
    .AsNoTracking()
    .Where(follow => follow.FollowingId == currentUserId)
    .OrderBy(follow => follow.CreatedAtUtc)
    .Select(follow => new
    {
        userId = follow.FollowerId,
        follow.CreatedAtUtc,
    })
    .ToListAsync(cancellationToken);

var blocks = await db.Blocks
    .AsNoTracking()
    .Where(block => block.BlockerId == currentUserId)
    .OrderBy(block => block.CreatedAt)
    .Select(block => new
    {
        userId = block.BlockedUserId,
        CreatedAtUtc = block.CreatedAt,
    })
    .ToListAsync(cancellationToken);

var reports = await db.Reports
    .AsNoTracking()
    .Where(report => report.ReporterId == currentUserId)
    .OrderBy(report => report.CreatedAt)
    .Select(report => new
    {
        report.Id,
        PostId = report.TargetId,
        report.Reason,
        report.Status,
        CreatedAtUtc = report.CreatedAt,
    })
    .ToListAsync(cancellationToken);

return Results.Ok(
    new
    {
        exportedAtUtc = DateTimeOffset.UtcNow,
        user,
        posts,
        likes,
        following,
        followers,
        blocks,
        reports,
    });

}

}