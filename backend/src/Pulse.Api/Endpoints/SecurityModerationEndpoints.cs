using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using Pulse.Api.Data;
using Pulse.Api.Domain;

namespace Pulse.Api.Endpoints;

public static class SecurityModerationEndpoints
{
    private const int postTargetValue = 0;
    private const int userTargetValue = 1;

    private const int spamReasonValue = 0;
    private const int harassmentReasonValue = 1;
    private const int hateSpeechReasonValue = 2;
    private const int violenceReasonValue = 3;
    private const int sexualContentReasonValue = 4;
    private const int fakeAccountReasonValue = 5;
    private const int otherReasonValue = 6;

    private const int pendingStatusValue = 0;
    private const int resolvedStatusValue = 1;
    private const int dismissedStatusValue = 2;

    private const int noActionValue = 0;
    private const int removePostActionValue = 1;

    public static IEndpointRouteBuilder MapSecurityModerationEndpoints(
        this IEndpointRouteBuilder endpoints)
    {
        endpoints.MapPost(
                "/api/v1/profiles/{username}/block",
                BlockUserAsync)
            .RequireAuthorization();

        endpoints.MapDelete(
                "/api/v1/profiles/{username}/block",
                UnblockUserAsync)
            .RequireAuthorization();

        endpoints.MapGet(
                "/api/v1/blocks",
                GetBlocksAsync)
            .RequireAuthorization();

        endpoints.MapPost(
                "/api/v1/reports",
                CreateReportAsync)
            .RequireAuthorization();

        endpoints.MapGet(
                "/api/v1/moderation/reports",
                GetModerationReportsAsync)
            .RequireAuthorization(
                policy => policy.RequireRole("moderator"));

        endpoints.MapGet(
                "/api/v1/moderation/reports/{reportId:int}",
                GetModerationReportAsync)
            .RequireAuthorization(
                policy => policy.RequireRole("moderator"));

        endpoints.MapPost(
                "/api/v1/moderation/reports/{reportId:int}/resolve",
                ResolveReportAsync)
            .RequireAuthorization(
                policy => policy.RequireRole("moderator"));

        endpoints.MapPost(
                "/api/v1/moderation/reports/{reportId:int}/dismiss",
                DismissReportAsync)
            .RequireAuthorization(
                policy => policy.RequireRole("moderator"));

        return endpoints;
    }

    private static async Task<IResult> BlockUserAsync(
        string username,
        ClaimsPrincipal principal,
        PulseDbContext dbContext,
        CancellationToken cancellationToken)
    {
        var currentUserId = GetCurrentUserId(principal);

        if (currentUserId is null)
        {
            return Results.Unauthorized();
        }

        var normalizedUsername =
            username.Trim().ToUpperInvariant();

        var targetUser = await dbContext.Users
            .SingleOrDefaultAsync(
                user =>
                    user.NormalizedUsername == normalizedUsername &&
                    user.IsActive,
                cancellationToken);

        if (targetUser is null)
        {
            return Error(
                StatusCodes.Status404NotFound,
                "User not found.");
        }

        if (targetUser.Id == currentUserId.Value)
        {
            return Error(
                StatusCodes.Status400BadRequest,
                "You cannot block yourself.",
                "username");
        }

        var existingBlock = await dbContext.Blocks
            .SingleOrDefaultAsync(
                block =>
                    block.BlockerId == currentUserId.Value &&
                    block.BlockedUserId == targetUser.Id,
                cancellationToken);

        if (existingBlock is null)
        {
            dbContext.Blocks.Add(
                new Block
                {
                    BlockerId = currentUserId.Value,
                    BlockedUserId = targetUser.Id,
                    CreatedAt = DateTime.UtcNow
                });

            var follows = await dbContext.Follows
                .Where(
                    follow =>
                        (follow.FollowerId == currentUserId.Value &&
                         follow.FollowingId == targetUser.Id) ||
                        (follow.FollowerId == targetUser.Id &&
                         follow.FollowingId == currentUserId.Value))
                .ToListAsync(cancellationToken);

            if (follows.Count > 0)
            {
                dbContext.Follows.RemoveRange(follows);
            }

            await dbContext.SaveChangesAsync(cancellationToken);
        }

        return Results.Ok(
            new BlockResponse(
                targetUser.Id,
                targetUser.Username,
                true));
    }

    private static async Task<IResult> UnblockUserAsync(
        string username,
        ClaimsPrincipal principal,
        PulseDbContext dbContext,
        CancellationToken cancellationToken)
    {
        var currentUserId = GetCurrentUserId(principal);

        if (currentUserId is null)
        {
            return Results.Unauthorized();
        }

        var normalizedUsername =
            username.Trim().ToUpperInvariant();

        var targetUser = await dbContext.Users
            .AsNoTracking()
            .SingleOrDefaultAsync(
                user =>
                    user.NormalizedUsername == normalizedUsername &&
                    user.IsActive,
                cancellationToken);

        if (targetUser is null)
        {
            return Error(
                StatusCodes.Status404NotFound,
                "User not found.");
        }

        var block = await dbContext.Blocks
            .SingleOrDefaultAsync(
                item =>
                    item.BlockerId == currentUserId.Value &&
                    item.BlockedUserId == targetUser.Id,
                cancellationToken);

        if (block is not null)
        {
            dbContext.Blocks.Remove(block);
            await dbContext.SaveChangesAsync(cancellationToken);
        }

        return Results.NoContent();
    }

    private static async Task<IResult> GetBlocksAsync(
        ClaimsPrincipal principal,
        PulseDbContext dbContext,
        CancellationToken cancellationToken)
    {
        var currentUserId = GetCurrentUserId(principal);

        if (currentUserId is null)
        {
            return Results.Unauthorized();
        }

        var blocks = await dbContext.Blocks
            .AsNoTracking()
            .Include(block => block.BlockedUser)
            .Where(
                block =>
                    block.BlockerId == currentUserId.Value)
            .OrderByDescending(block => block.CreatedAt)
            .ThenByDescending(block => block.Id)
            .ToListAsync(cancellationToken);

        var items = blocks
            .Select(
                block =>
                    new BlockListItemResponse(
                        block.BlockedUserId,
                        block.BlockedUser.Username,
                        block.BlockedUser.DisplayName,
                        block.BlockedUser.AvatarUrl,
                        block.CreatedAt))
            .ToList();

        return Results.Ok(
            new BlockListResponse(items));
    }

    private static async Task<IResult> CreateReportAsync(
        CreateReportRequest request,
        ClaimsPrincipal principal,
        PulseDbContext dbContext,
        CancellationToken cancellationToken)
    {
        var currentUserId = GetCurrentUserId(principal);

        if (currentUserId is null)
        {
            return Results.Unauthorized();
        }

        if (!TryParseApiToken(
                request.TargetType,
                out ReportTargetType targetType))
        {
            return Error(
                StatusCodes.Status400BadRequest,
                "Invalid report target type.",
                "targetType");
        }

        if (request.TargetId <= 0)
        {
            return Error(
                StatusCodes.Status400BadRequest,
                "Target id must be greater than zero.",
                "targetId");
        }

        if (!TryParseApiToken(
                request.Reason,
                out ReportReason reason))
        {
            return Error(
                StatusCodes.Status400BadRequest,
                "Invalid report reason.",
                "reason");
        }

        var details = NormalizeOptional(request.Details);

        if (details?.Length > 500)
        {
            return Error(
                StatusCodes.Status400BadRequest,
                "Details cannot exceed 500 characters.",
                "details");
        }

        var targetExists = (int)targetType switch
        {
            userTargetValue =>
                await dbContext.Users
                    .AsNoTracking()
                    .AnyAsync(
                        user =>
                            user.Id == request.TargetId &&
                            user.IsActive,
                        cancellationToken),

            postTargetValue =>
                await dbContext.Posts
                    .AsNoTracking()
                    .AnyAsync(
                        post =>
                            post.Id == request.TargetId &&
                            post.DeletedAt == null,
                        cancellationToken),

            _ => false
        };

        if (!targetExists)
        {
            return Error(
                StatusCodes.Status404NotFound,
                "Report target not found.");
        }

        var duplicateExists = await dbContext.Reports
            .AsNoTracking()
            .AnyAsync(
                report =>
                    report.ReporterId == currentUserId.Value &&
                    report.TargetType == targetType &&
                    report.TargetId == request.TargetId &&
                    (int)report.Status == pendingStatusValue,
                cancellationToken);

        if (duplicateExists)
        {
            return Error(
                StatusCodes.Status409Conflict,
                "A Pending report already exists for this target.");
        }

        var report = new Report
        {
            ReporterId = currentUserId.Value,
            TargetType = targetType,
            TargetId = request.TargetId,
            Reason = reason,
            Details = details,
            Status = (ReportStatus)pendingStatusValue,
            CreatedAt = DateTime.UtcNow
        };

        dbContext.Reports.Add(report);
        await dbContext.SaveChangesAsync(cancellationToken);

        return Results.Created(
            $"/api/v1/moderation/reports/{report.Id}",
            ToReportResponse(report));
    }

    private static async Task<IResult> GetModerationReportsAsync(
        PulseDbContext dbContext,
        CancellationToken cancellationToken)
    {
        var reports = await dbContext.Reports
            .AsNoTracking()
            .OrderBy(report => report.Status)
            .ThenByDescending(report => report.CreatedAt)
            .ThenByDescending(report => report.Id)
            .ToListAsync(cancellationToken);

        var items = reports
            .Select(ToModerationReportResponse)
            .ToList();

        return Results.Ok(
            new ModerationReportListResponse(items));
    }

    private static async Task<IResult> GetModerationReportAsync(
        int reportId,
        PulseDbContext dbContext,
        CancellationToken cancellationToken)
    {
        var report = await dbContext.Reports
            .AsNoTracking()
            .SingleOrDefaultAsync(
                item => item.Id == reportId,
                cancellationToken);

        if (report is null)
        {
            return Error(
                StatusCodes.Status404NotFound,
                "Report not found.");
        }

        return Results.Ok(
            ToModerationReportResponse(report));
    }

    private static async Task<IResult> ResolveReportAsync(
        int reportId,
        ResolveReportRequest request,
        ClaimsPrincipal principal,
        PulseDbContext dbContext,
        CancellationToken cancellationToken)
    {
        var moderatorUserId = GetCurrentUserId(principal);

        if (moderatorUserId is null)
        {
            return Results.Unauthorized();
        }

        if (!TryParseApiToken(
                request.Action,
                out ModerationAction action))
        {
            return Error(
                StatusCodes.Status400BadRequest,
                "Invalid moderation action.",
                "action");
        }

        var note = NormalizeOptional(request.Note);

        if (note?.Length > 500)
        {
            return Error(
                StatusCodes.Status400BadRequest,
                "Note cannot exceed 500 characters.",
                "note");
        }

        var report = await dbContext.Reports
            .SingleOrDefaultAsync(
                item => item.Id == reportId,
                cancellationToken);

        if (report is null)
        {
            return Error(
                StatusCodes.Status404NotFound,
                "Report not found.");
        }

        if ((int)report.Status != pendingStatusValue)
        {
            return Error(
                StatusCodes.Status409Conflict,
                "Only Pending reports can be resolved.");
        }

        if ((int)action == removePostActionValue)
        {
            if ((int)report.TargetType != postTargetValue)
            {
                return Error(
                    StatusCodes.Status400BadRequest,
                    "RemovePost can only be used for Post reports.",
                    "action");
            }

            var post = await dbContext.Posts
                .SingleOrDefaultAsync(
                    item =>
                        item.Id == report.TargetId &&
                        item.DeletedAt == null,
                    cancellationToken);

            if (post is null)
            {
                return Error(
                    StatusCodes.Status404NotFound,
                    "Post not found.");
            }

            post.DeletedAt = DateTime.UtcNow;
        }

        var reviewedAt = DateTime.UtcNow;

        report.Status =
            (ReportStatus)resolvedStatusValue;
        report.ReviewedByUserId = moderatorUserId.Value;
        report.ReviewedAt = reviewedAt;

        dbContext.ModerationActions.Add(
            new ModerationActionRecord
            {
                ReportId = report.Id,
                ModeratorUserId = moderatorUserId.Value,
                Action = action,
                Note = note,
                CreatedAt = reviewedAt
            });

        await dbContext.SaveChangesAsync(cancellationToken);

        return Results.Ok(
            new ResolveReportResponse(
                report.Id,
                ToApiToken(report.Status),
                ToApiToken(action),
                reviewedAt,
                moderatorUserId.Value));
    }

    private static async Task<IResult> DismissReportAsync(
        int reportId,
        ClaimsPrincipal principal,
        PulseDbContext dbContext,
        CancellationToken cancellationToken)
    {
        var moderatorUserId = GetCurrentUserId(principal);

        if (moderatorUserId is null)
        {
            return Results.Unauthorized();
        }

        var report = await dbContext.Reports
            .SingleOrDefaultAsync(
                item => item.Id == reportId,
                cancellationToken);

        if (report is null)
        {
            return Error(
                StatusCodes.Status404NotFound,
                "Report not found.");
        }

        if ((int)report.Status != pendingStatusValue)
        {
            return Error(
                StatusCodes.Status409Conflict,
                "Only Pending reports can be dismissed.");
        }

        var reviewedAt = DateTime.UtcNow;

        report.Status =
            (ReportStatus)dismissedStatusValue;
        report.ReviewedByUserId = moderatorUserId.Value;
        report.ReviewedAt = reviewedAt;

        dbContext.ModerationActions.Add(
            new ModerationActionRecord
            {
                ReportId = report.Id,
                ModeratorUserId = moderatorUserId.Value,
                Action =
                    (ModerationAction)noActionValue,
                CreatedAt = reviewedAt
            });

        await dbContext.SaveChangesAsync(cancellationToken);

        return Results.Ok(
            new ResolveReportResponse(
                report.Id,
                ToApiToken(report.Status),
                ToApiToken(
                    (ModerationAction)noActionValue),
                reviewedAt,
                moderatorUserId.Value));
    }

    private static int? GetCurrentUserId(
        ClaimsPrincipal principal)
    {
        return PostEndpoints.TryGetUserId(
            principal,
            out var userId)
            ? userId
            : null;
    }

    private static ReportResponse ToReportResponse(
        Report report)
    {
        return new ReportResponse(
            report.Id,
            ToApiToken(report.TargetType),
            report.TargetId,
            ToApiToken(report.Reason),
            report.Details,
            ToApiToken(report.Status),
            report.CreatedAt);
    }

    private static ModerationReportResponse
        ToModerationReportResponse(
            Report report)
    {
        return new ModerationReportResponse(
            report.Id,
            report.ReporterId,
            ToApiToken(report.TargetType),
            report.TargetId,
            ToApiToken(report.Reason),
            report.Details,
            ToApiToken(report.Status),
            report.CreatedAt,
            report.ReviewedAt,
            report.ReviewedByUserId);
    }

    private static bool TryParseApiToken(
        string? token,
        out ReportTargetType value)
    {
        switch (token)
        {
            case "Post":
                value =
                    (ReportTargetType)postTargetValue;
                return true;

            case "User":
                value =
                    (ReportTargetType)userTargetValue;
                return true;

            default:
                value = default;
                return false;
        }
    }

    private static bool TryParseApiToken(
        string? token,
        out ReportReason value)
    {
        switch (token)
        {
            case "Spam":
                value =
                    (ReportReason)spamReasonValue;
                return true;

            case "Harassment":
                value =
                    (ReportReason)harassmentReasonValue;
                return true;

            case "HateSpeech":
                value =
                    (ReportReason)hateSpeechReasonValue;
                return true;

            case "Violence":
                value =
                    (ReportReason)violenceReasonValue;
                return true;

            case "SexualContent":
                value =
                    (ReportReason)sexualContentReasonValue;
                return true;

            case "Impersonation":
                value =
                    (ReportReason)fakeAccountReasonValue;
                return true;

            case "Other":
                value =
                    (ReportReason)otherReasonValue;
                return true;

            default:
                value = default;
                return false;
        }
    }

    private static bool TryParseApiToken(
        string? token,
        out ModerationAction value)
    {
        switch (token)
        {
            case "NoAction":
                value =
                    (ModerationAction)noActionValue;
                return true;

            case "RemovePost":
                value =
                    (ModerationAction)removePostActionValue;
                return true;

            default:
                value = default;
                return false;
        }
    }

    private static string ToApiToken(
        ReportTargetType value)
    {
        return (int)value switch
        {
            postTargetValue => "Post",
            userTargetValue => "User",
            _ => throw new ArgumentOutOfRangeException(
                nameof(value))
        };
    }

    private static string ToApiToken(
        ReportReason value)
    {
        return (int)value switch
        {
            spamReasonValue => "Spam",
            harassmentReasonValue => "Harassment",
            hateSpeechReasonValue => "HateSpeech",
            violenceReasonValue => "Violence",
            sexualContentReasonValue => "SexualContent",
            fakeAccountReasonValue => "Impersonation",
            otherReasonValue => "Other",
            _ => throw new ArgumentOutOfRangeException(
                nameof(value))
        };
    }

    private static string ToApiToken(
        ReportStatus value)
    {
        return (int)value switch
        {
            pendingStatusValue => "Pending",
            resolvedStatusValue => "Resolved",
            dismissedStatusValue => "Dismissed",
            _ => throw new ArgumentOutOfRangeException(
                nameof(value))
        };
    }

    private static string ToApiToken(
        ModerationAction value)
    {
        return (int)value switch
        {
            noActionValue => "NoAction",
            removePostActionValue => "RemovePost",
            _ => throw new ArgumentOutOfRangeException(
                nameof(value))
        };
    }

    private static string? NormalizeOptional(
        string? value)
    {
        var normalized = value?.Trim();

        return string.IsNullOrEmpty(normalized)
            ? null
            : normalized;
    }

    private static IResult Error(
        int statusCode,
        string error,
        string? field = null)
    {
        return Results.Json(
            new ErrorResponse(
                error,
                field),
            statusCode: statusCode);
    }

    public sealed record CreateReportRequest(
        string TargetType,
        int TargetId,
        string Reason,
        string? Details);

    public sealed record ResolveReportRequest(
        string Action,
        string? Note);

    public sealed record BlockResponse(
        int Id,
        string Username,
        bool IsBlocked);

    public sealed record BlockListItemResponse(
        int Id,
        string Username,
        string DisplayName,
        string? AvatarUrl,
        DateTime BlockedAt);

    public sealed record BlockListResponse(
        IReadOnlyList<BlockListItemResponse> Items);

    public sealed record ReportResponse(
        int Id,
        string TargetType,
        int TargetId,
        string Reason,
        string? Details,
        string Status,
        DateTime CreatedAt);

    public sealed record ModerationReportResponse(
        int Id,
        int ReporterUserId,
        string TargetType,
        int TargetId,
        string Reason,
        string? Details,
        string Status,
        DateTime CreatedAt,
        DateTime? ResolvedAt,
        int? ResolvedByUserId);

    public sealed record ModerationReportListResponse(
        IReadOnlyList<ModerationReportResponse> Items);

    public sealed record ResolveReportResponse(
        int Id,
        string Status,
        string Action,
        DateTime ResolvedAt,
        int ResolvedByUserId);

    public sealed record ErrorResponse(
        string Error,
        string? Field);
}