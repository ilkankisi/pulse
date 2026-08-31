namespace Pulse.Api.Endpoints;

public static partial class PostEndpoints
{
    public static IEndpointRouteBuilder MapPostEndpoints(
        this IEndpointRouteBuilder endpoints)
    {
        endpoints.MapPost(
                "/api/v1/posts",
                CreatePostAsync)
            .RequireAuthorization()
            .Produces(StatusCodes.Status201Created)
            .Produces(StatusCodes.Status400BadRequest)
            .Produces(StatusCodes.Status401Unauthorized);

        endpoints.MapDelete(
                "/api/v1/posts/{postId}",
                DeletePostAsync)
            .RequireAuthorization()
            .Produces(StatusCodes.Status204NoContent)
            .Produces(StatusCodes.Status401Unauthorized)
            .Produces(StatusCodes.Status403Forbidden)
            .Produces(StatusCodes.Status404NotFound);

        endpoints.MapPost(
                "/api/v1/posts/{postId}/replies",
                CreateReplyAsync)
            .RequireAuthorization()
            .Produces(StatusCodes.Status201Created)
            .Produces(StatusCodes.Status400BadRequest)
            .Produces(StatusCodes.Status401Unauthorized)
            .Produces(StatusCodes.Status404NotFound);

        endpoints.MapPost(
                "/api/v1/posts/{postId}/likes",
                LikePostAsync)
            .RequireAuthorization();

        endpoints.MapDelete(
                "/api/v1/posts/{postId}/likes",
                UnlikePostAsync)
            .RequireAuthorization();

        return endpoints;
    }
}
