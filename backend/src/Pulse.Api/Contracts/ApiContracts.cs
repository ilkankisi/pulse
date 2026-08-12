namespace Pulse.Api.Contracts;

public sealed record RegisterRequest(
    string Username,
    string Email,
    string Password,
    string DisplayName);

public sealed record LoginRequest(
    string Login,
    string Password);

public sealed record AuthUserResponse(
    int Id,
    string Username,
    string DisplayName,
    string? AvatarUrl);

public sealed record AuthResponse(
    string AccessToken,
    string TokenType,
    long ExpiresIn,
    AuthUserResponse User);

public sealed record UpdateProfileRequest(
    string DisplayName,
    string? Bio,
    string? AvatarUrl);

public sealed record CreatePostRequest(
    string Content);

public sealed record CreateReplyRequest(
    string Content);

public sealed record PostAuthorResponse(
    int Id,
    string Username,
    string DisplayName,
    string? AvatarUrl);

public sealed record PostResponse(
    int Id,
    PostAuthorResponse Author,
    string Content,
    int? ParentPostId,
    DateTimeOffset CreatedAt,
    int LikeCount,
    int ReplyCount,
    bool IsLikedByMe);

public sealed record ProfileResponse(
    int Id,
    string Username,
    string DisplayName,
    string? Bio,
    string? AvatarUrl,
    DateTimeOffset CreatedAt,
    int PostCount,
    int FollowerCount,
    int FollowingCount,
    bool IsFollowedByCurrentUser);

public sealed record FollowResponse(
    string Username,
    bool IsFollowing);

public sealed record FeedListResponse(
    IReadOnlyList<PostResponse> Items);

public sealed record LikeResponse(
    int PostId,
    bool IsLiked,
    int LikeCount);

public sealed record PagedResponse<T>(
    IReadOnlyList<T> Items,
    string? NextCursor);

public sealed record ApiErrorResponse(
    string Error,
    string? Field = null);

public sealed record SocialGraphUserResponse(
    int Id,
    string Username,
    string DisplayName,
    string? AvatarUrl,
    bool IsFollowedByCurrentUser);