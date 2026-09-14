using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;

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

        app.MapGet(
                "/api/v1/posts/{postId}",
                PostEndpoints.GetPostAsync)
            .RequireAuthorization()
            .WithName("GetPost");

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

        app.MapDelete(
                "/api/v1/posts/{postId}/likes",
                PostEndpoints.UnlikePostAsync)
            .RequireAuthorization()
            .WithName("UnlikePost");

        app.MapGet(
                "/api/v1/posts/{postId}/likes",
                PostEndpoints.GetPostLikesAsync)
            .RequireAuthorization()
            .WithName("GetPostLikes");

        app.MapGet(
                "/api/v1/profiles/{username}/block",
                GetBlockCompatibility)
            .RequireAuthorization()
            .WithName("GetProfileBlockCompatibility");

        app.MapGet(
                "/api/v1/profiles/{username}/follow",
                GetFollowCompatibility)
            .RequireAuthorization()
            .WithName("GetProfileFollowCompatibility");

        app.MapGet(
                "/api/v1/moderation/reports/{reportId}/resolve",
                GetResolveCompatibility)
            .RequireAuthorization()
            .WithName("GetModerationResolveCompatibility");

        app.MapGet(
                "/api/v1/moderation/reports/{reportId}/dismiss",
                GetDismissCompatibility)
            .RequireAuthorization()
            .WithName("GetModerationDismissCompatibility");

        return app;
    }

    private static IResult GetBlockCompatibility(string username)
    {
        _ = username;
        return Results.StatusCode(StatusCodes.Status405MethodNotAllowed);
    }

    private static IResult GetFollowCompatibility(string username)
    {
        _ = username;
        return Results.StatusCode(StatusCodes.Status405MethodNotAllowed);
    }

    private static IResult GetResolveCompatibility(string reportId)
    {
        _ = reportId;
        return Results.StatusCode(StatusCodes.Status405MethodNotAllowed);
    }

    private static IResult GetDismissCompatibility(string reportId)
    {
        _ = reportId;
        return Results.StatusCode(StatusCodes.Status405MethodNotAllowed);
    }
}