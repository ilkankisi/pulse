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
            .Produces<IReadOnlyList<PostLikeUserResponse>>(
        StatusCodes.Status200OK,
        contentType: "application/json")
        .Produces(
        StatusCodes.Status401Unauthorized)
        .Produces(
                StatusCodes.Status404NotFound)
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
        
        var likerIds = await dbContext.PostLikes
        .AsNoTracking()
            .Where(like => like.PostId == postId)
            .Select(like => like.UserId)
            .Distinct()
            .ToListAsync(cancellationToken);
        
        var userEntityType = dbContext.Model
            .GetEntityTypes()
            .SingleOrDefault(
                candidate => candidate.ClrType.Name == "User");
        
        var idProperty =
            userEntityType?.FindPrimaryKey()?.Properties.SingleOrDefault();
        var usernameProperty =
            userEntityType?.FindProperty("Username");
        
        if (userEntityType is null
            || idProperty is null
            || usernameProperty is null)
        {
            return Results.StatusCode(
                StatusCodes.Status500InternalServerError);
        }
        
        var displayNameProperty =
            userEntityType.FindProperty("DisplayName");
        var avatarUrlProperty =
            userEntityType.FindProperty("AvatarUrl");
        
        var users = new List<PostLikeUserResponse>();
        
        foreach (var likerId in likerIds)
        {
            var user = await dbContext.FindAsync(
                userEntityType.ClrType,
                new object?[] { likerId },
                cancellationToken);
        
            if (user is null)
            {
                continue;
            }
        
            var entry = dbContext.Entry(user);
            var username = Convert.ToString(
                entry.Property(usernameProperty.Name).CurrentValue);
        
            if (string.IsNullOrWhiteSpace(username))
            {
                continue;
            }
        
            users.Add(
                new PostLikeUserResponse(
                    Convert.ToInt32(
                        entry.Property(idProperty.Name).CurrentValue),
                    username,
                    displayNameProperty is null
                        ? null
                        : Convert.ToString(
                            entry.Property(displayNameProperty.Name)
                                .CurrentValue),
                    avatarUrlProperty is null
                        ? null
                        : Convert.ToString(
                            entry.Property(avatarUrlProperty.Name)
                                .CurrentValue)));
        }
        
        return Results.Ok(
            users
                .OrderBy(user => user.Username)
                .ToArray());
        }
        }
        
        public sealed record PostLikeUserResponse(
    int Id,
    string Username,
    string? DisplayName,
    string? AvatarUrl);