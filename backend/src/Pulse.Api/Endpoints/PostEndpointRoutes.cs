using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using Pulse.Api.Contracts;
using Pulse.Api.Data;
using Pulse.Api.Domain;

namespace Pulse.Api.Endpoints;

public static class PostEndpointRoutes
{
    public static IEndpointRouteBuilder MapPostEndpoints(
        this IEndpointRouteBuilder endpoints)
    {
        var group = endpoints
            .MapGroup("/api/v1/posts")
            .RequireAuthorization();

        group.MapPost(string.Empty, CreatePostAsync);
        group.MapDelete("/{postId:int}", DeletePostAsync);

        group.MapPost(
            "/{postId:int}/likes",
            LikePostAsync);

        group.MapDelete(
            "/{postId:int}/likes",
            UnlikePostAsync);

        group.MapPost(
            "/{postId:int}/replies",
            CreateReplyAsync);

        return endpoints;
    }

    private static async Task<IResult> CreatePostAsync(
        CreatePostRequest request,
        ClaimsPrincipal principal,
        PulseDbContext dbContext,
        CancellationToken cancellationToken)
    {
        if (!PostEndpoints.TryGetUserId(
                principal,
                out var userId))
        {
            return Results.Unauthorized();
        }

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

        var response = await PostEndpoints.ToResponseAsync(
            dbContext,
            post,
            userId,
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
        if (!PostEndpoints.TryGetUserId(
                principal,
                out var userId))
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
            return Results.NotFound();
        }

        if (post.AuthorId != userId)
        {
            return Results.Forbid();
        }

        post.DeletedAt = DateTime.UtcNow;
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
        if (!PostEndpoints.TryGetUserId(
                principal,
                out var userId))
        {
            return Results.Unauthorized();
        }

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
                post =>
                    post.Id == postId
                    && post.DeletedAt == null,
                cancellationToken);

        if (parentPost is null)
        {
            return Results.NotFound();
        }

        if (parentPost.ParentPostId.HasValue)
        {
            return ValidationError(
                "Replies cannot have replies.",
                "parentPostId");
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

        var response = await PostEndpoints.ToResponseAsync(
            dbContext,
            reply,
            userId,
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
        if (!PostEndpoints.TryGetUserId(
                principal,
                out var userId))
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
            candidate => candidate.PostId == postId,
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
        if (!PostEndpoints.TryGetUserId(
                principal,
                out var userId))
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
            return Results.NotFound();
        }

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

        var likeCount = await dbContext.PostLikes.CountAsync(
            candidate => candidate.PostId == postId,
            cancellationToken);

        return Results.Ok(
            new LikeResponse(
                postId,
                false,
                likeCount));
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