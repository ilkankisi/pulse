using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using Pulse.Api.Contracts;
using Pulse.Api.Data;
using Pulse.Api.Domain;

namespace Pulse.Api.Endpoints;

public static partial class PostEndpoints
{
    private static IEndpointRouteBuilder MapPostRoutes(
        IEndpointRouteBuilder endpoints)
    {
        endpoints.MapPost(
                "/api/v1/posts",
                CreatePostAsync)
            .RequireAuthorization();

        endpoints.MapDelete(
                "/api/v1/posts/{postId:int}",
                DeletePostAsync)
            .RequireAuthorization();

        endpoints.MapPost(
                "/api/v1/posts/{postId:int}/replies",
                CreateReplyAsync)
            .RequireAuthorization();

        endpoints.MapPost(
                "/api/v1/posts/{postId:int}/likes",
                LikePostAsync)
            .RequireAuthorization();

        endpoints.MapDelete(
                "/api/v1/posts/{postId:int}/likes",
                UnlikePostAsync)
            .RequireAuthorization();

        return endpoints;
    }

    private static async Task<IResult> CreatePostAsync(
        CreatePostRequest request,
        ClaimsPrincipal principal,
        PulseDbContext dbContext,
        CancellationToken cancellationToken)
    {
        if (!TryGetUserId(
                principal,
                out var currentUserId))
        {
            return Results.Unauthorized();
        }

        var content = request.Content?.Trim();

        if (string.IsNullOrWhiteSpace(content))
        {
            return Results.BadRequest(
                new ApiErrorResponse(
                    "Content is required.",
                    "content"));
        }

        if (content.Length > 280)
        {
            return Results.BadRequest(
                new ApiErrorResponse(
                    "Content must not exceed 280 characters.",
                    "content"));
        }

        var author = await dbContext.Users
            .SingleOrDefaultAsync(
                user =>
                    user.Id == currentUserId
                    && user.IsActive,
                cancellationToken);

        if (author is null)
        {
            return Results.NotFound(
                new ApiErrorResponse(
                    "User was not found."));
        }

        var post = new Post
        {
            AuthorId = currentUserId,
            Author = author,
            Content = content,
            CreatedAtUtc = DateTimeOffset.UtcNow
        };

        dbContext.Posts.Add(post);

        await dbContext.SaveChangesAsync(
            cancellationToken);

        var response = await ToResponseAsync(
            dbContext,
            post,
            currentUserId,
            cancellationToken);

        return Results.Created(
            $"/api/v1/posts/{post.Id}",
            response);
    }

    private static async Task<IResult> DeletePostAsync(
        int postId,
        ClaimsPrincipal principal,
        PulseDbContext dbContext,
        CancellationToken cancellationToken)
    {
        if (!TryGetUserId(
                principal,
                out var currentUserId))
        {
            return Results.Unauthorized();
        }

        var post = await dbContext.Posts
            .SingleOrDefaultAsync(
                candidate =>
                    candidate.Id == postId
                    && candidate.DeletedAt == null,
                cancellationToken);

        if (post is null)
        {
            return Results.NotFound(
                new ApiErrorResponse(
                    "Post was not found."));
        }

        if (post.AuthorId != currentUserId)
        {
            return Results.StatusCode(
                StatusCodes.Status403Forbidden);
        }

        post.DeletedAt = DateTime.UtcNow;

        await dbContext.SaveChangesAsync(
            cancellationToken);

        return Results.NoContent();
    }

    private static async Task<IResult> CreateReplyAsync(
        int postId,
        CreateReplyRequest request,
        ClaimsPrincipal principal,
        PulseDbContext dbContext,
        CancellationToken cancellationToken)
    {
        if (!TryGetUserId(
                principal,
                out var currentUserId))
        {
            return Results.Unauthorized();
        }

        var content = request.Content?.Trim();

        if (string.IsNullOrWhiteSpace(content))
        {
            return Results.BadRequest(
                new ApiErrorResponse(
                    "Content is required.",
                    "content"));
        }

        if (content.Length > 280)
        {
            return Results.BadRequest(
                new ApiErrorResponse(
                    "Content must not exceed 280 characters.",
                    "content"));
        }

        var parentPost = await dbContext.Posts
            .AsNoTracking()
            .SingleOrDefaultAsync(
                post =>
                    post.Id == postId
                    && post.DeletedAt == null,
                cancellationToken);

        if (parentPost is null)
        {
            return Results.NotFound(
                new ApiErrorResponse(
                    "Post was not found."));
        }

        if (parentPost.ParentPostId is not null)
        {
            return Results.BadRequest(
                new ApiErrorResponse(
                    "Replies cannot have nested replies.",
                    "postId"));
        }

        var author = await dbContext.Users
            .SingleOrDefaultAsync(
                user =>
                    user.Id == currentUserId
                    && user.IsActive,
                cancellationToken);

        if (author is null)
        {
            return Results.NotFound(
                new ApiErrorResponse(
                    "User was not found."));
        }

        var reply = new Post
        {
            AuthorId = currentUserId,
            Author = author,
            Content = content,
            ParentPostId = parentPost.Id,
            CreatedAtUtc = DateTimeOffset.UtcNow
        };

        dbContext.Posts.Add(reply);

        await dbContext.SaveChangesAsync(
            cancellationToken);

        var response = await ToResponseAsync(
            dbContext,
            reply,
            currentUserId,
            cancellationToken);

        return Results.Created(
            $"/api/v1/posts/{reply.Id}",
            response);
    }

    private static async Task<IResult> LikePostAsync(
        int postId,
        ClaimsPrincipal principal,
        PulseDbContext dbContext,
        CancellationToken cancellationToken)
    {
        if (!TryGetUserId(
                principal,
                out var currentUserId))
        {
            return Results.Unauthorized();
        }

        var postExists = await dbContext.Posts
            .AsNoTracking()
            .AnyAsync(
                post =>
                    post.Id == postId
                    && post.DeletedAt == null,
                cancellationToken);

        if (!postExists)
        {
            return Results.NotFound(
                new ApiErrorResponse(
                    "Post was not found."));
        }

        var existingLike = await dbContext.PostLikes
            .SingleOrDefaultAsync(
                like =>
                    like.PostId == postId
                    && like.UserId == currentUserId,
                cancellationToken);

        if (existingLike is null)
        {
            dbContext.PostLikes.Add(
                new PostLike
                {
                    PostId = postId,
                    UserId = currentUserId,
                    CreatedAtUtc = DateTimeOffset.UtcNow
                });

            await dbContext.SaveChangesAsync(
                cancellationToken);
        }

        var likeCount = await dbContext.PostLikes
            .AsNoTracking()
            .CountAsync(
                like => like.PostId == postId,
                cancellationToken);

        return Results.Ok(
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
        if (!TryGetUserId(
                principal,
                out var currentUserId))
        {
            return Results.Unauthorized();
        }

        var postExists = await dbContext.Posts
            .AsNoTracking()
            .AnyAsync(
                post =>
                    post.Id == postId
                    && post.DeletedAt == null,
                cancellationToken);

        if (!postExists)
        {
            return Results.NotFound(
                new ApiErrorResponse(
                    "Post was not found."));
        }

        var existingLike = await dbContext.PostLikes
            .SingleOrDefaultAsync(
                like =>
                    like.PostId == postId
                    && like.UserId == currentUserId,
                cancellationToken);

        if (existingLike is not null)
        {
            dbContext.PostLikes.Remove(existingLike);

            await dbContext.SaveChangesAsync(
                cancellationToken);
        }

        var likeCount = await dbContext.PostLikes
            .AsNoTracking()
            .CountAsync(
                like => like.PostId == postId,
                cancellationToken);

        return Results.Ok(
            new LikeResponse(
                postId,
                false,
                likeCount));
    }
}