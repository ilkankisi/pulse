using System.Security.Claims;

using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;
using Microsoft.EntityFrameworkCore;

using Pulse.Api.Contracts;
using Pulse.Api.Data;

namespace Pulse.Api.Endpoints;

public static class PostEndpointRoutes
{
    public static IEndpointRouteBuilder MapPostEndpoints(
        this IEndpointRouteBuilder app)
    {
        app.MapPost(
                "/api/v1/posts",
                PostEndpoints.CreatePostAsync)
            .RequireAuthorization()
            .WithName("CreatePost");

        app.MapDelete(
                "/api/v1/posts/{postId}",
                PostEndpoints.DeletePostAsync)
            .RequireAuthorization()
            .WithName("DeletePost");

        app.MapPost(
                "/api/v1/posts/{postId}/replies",
                PostEndpoints.CreateReplyAsync)
            .RequireAuthorization()
            .WithName("CreatePostReply");

        app.MapGet(
                "/api/v1/posts/{postId}/replies",
                PostEndpoints.GetRepliesAsync)
            .RequireAuthorization()
            .WithName("GetPostReplies");

        app.MapPost(
        "/api/v1/posts/{postId}/likes",
        PostEndpoints.LikePostAsync)
        .RequireAuthorization()
        .WithName("LikePost");
        app.MapGet(
                "/api/v1/posts/{postId}/likes",
                GetPostLikesAsync)
            .RequireAuthorization()
            .WithName("GetPostLikes");
        
        app.MapDelete(
        "/api/v1/posts/{postId}/likes",
        PostEndpoints.UnlikePostAsync)
        .RequireAuthorization()
        .WithName("UnlikePost");

        return app;
        }
    private static async Task<IResult> GetPostLikesAsync(
        int postId,
        ClaimsPrincipal principal,
        PulseDbContext dbContext,
        CancellationToken cancellationToken)
    {
        var userIdValue =
            principal.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? principal.FindFirst("sub")?.Value;
        
        if (!int.TryParse(userIdValue, out var userId))
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
        
        var likeCount = await dbContext.PostLikes
            .AsNoTracking()
            .CountAsync(
                like => like.PostId == postId,
                cancellationToken);
        
        var isLiked = await dbContext.PostLikes
            .AsNoTracking()
            .AnyAsync(
                like =>
                    like.PostId == postId
                    && like.UserId == userId,
                cancellationToken);
        
        return Results.Ok(
            new LikeResponse(
                postId,
                isLiked,
                likeCount));
    }
        
}