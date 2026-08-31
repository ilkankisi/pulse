using System.Security.Claims;

using Microsoft.AspNetCore.Http;

using Microsoft.EntityFrameworkCore;

using Pulse.Api.Contracts;

using Pulse.Api.Data;

using Pulse.Api.Domain;

namespace Pulse.Api.Endpoints;

public static partial class PostEndpoints

{

public static async Task<IResult> CreatePostAsync(CreatePostRequest request, ClaimsPrincipal principal, PulseDbContext dbContext, CancellationToken cancellationToken)

{

var userIdValue = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? principal.FindFirst("sub")?.Value;

if (!int.TryParse(userIdValue, out var userId))

{

return Results.Unauthorized();

}

var content = request.Content?.Trim();

if (string.IsNullOrWhiteSpace(content))

{

return Results.BadRequest(

new ApiErrorResponse("Content is required.", "content"));

}

if (content.Length > 280)

{

return Results.BadRequest(

new ApiErrorResponse(

"Content must not exceed 280 characters.",

"content"));

}

var entityType = dbContext.Model

.GetEntityTypes()

.SingleOrDefault(candidate => candidate.ClrType.Name == "Post");

if (entityType is null)

{

return Results.StatusCode(StatusCodes.Status500InternalServerError);

}

var post = Activator.CreateInstance(entityType.ClrType);

if (post is null)

{

return Results.StatusCode(StatusCodes.Status500InternalServerError);

}

var contentProperty = entityType.FindProperty("Content");

var authorIdProperty =

entityType.FindProperty("AuthorId") ??

entityType.FindProperty("UserId");

if (contentProperty is null || authorIdProperty is null)

{

return Results.StatusCode(StatusCodes.Status500InternalServerError);

}

var entry = dbContext.Entry(post);

entry.Property(contentProperty.Name).CurrentValue = content;

entry.Property(authorIdProperty.Name).CurrentValue = userId;

var createdAtProperty = entityType.FindProperty("CreatedAt");

if (createdAtProperty?.ClrType == typeof(DateTime))

{

entry.Property(createdAtProperty.Name).CurrentValue = DateTime.UtcNow;

}

if (createdAtProperty?.ClrType == typeof(DateTimeOffset))

{

entry.Property(createdAtProperty.Name).CurrentValue = DateTimeOffset.UtcNow;

}

dbContext.Add(post);

await dbContext.SaveChangesAsync(cancellationToken);

var idProperty =

entityType.FindPrimaryKey()?.Properties.SingleOrDefault();

if (idProperty is null)

{

return Results.StatusCode(StatusCodes.Status500InternalServerError);

}

var idValue = dbContext.Entry(post)

.Property(idProperty.Name)

.CurrentValue;

if (idValue is null)

{

return Results.StatusCode(StatusCodes.Status500InternalServerError);

}

return Results.Created(

"/api/v1/posts/" + idValue,

await BuildPostResponseAsync(

dbContext,

Convert.ToInt32(idValue),

userId,

cancellationToken));

}

public static async Task<IResult> DeletePostAsync(int postId, ClaimsPrincipal principal, PulseDbContext dbContext, CancellationToken cancellationToken)

{

var userIdValue = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? principal.FindFirst("sub")?.Value;

if (!int.TryParse(userIdValue, out var userId))

{

return Results.Unauthorized();

}

var entityType = dbContext.Model

.GetEntityTypes()

.SingleOrDefault(candidate => candidate.ClrType.Name == "Post");

if (entityType is null)

{

return Results.StatusCode(StatusCodes.Status500InternalServerError);

}

var post = await dbContext.FindAsync(

entityType.ClrType,

new object?[] { postId },

cancellationToken);

if (post is null)

{

return Results.NotFound();

}

var authorIdProperty =

entityType.FindProperty("AuthorId") ??

entityType.FindProperty("UserId");

if (authorIdProperty is null)

{

return Results.StatusCode(StatusCodes.Status500InternalServerError);

}

var authorIdValue = dbContext.Entry(post)

.Property(authorIdProperty.Name)

.CurrentValue;

if (authorIdValue is null)

{

return Results.StatusCode(StatusCodes.Status500InternalServerError);

}

if (Convert.ToInt32(authorIdValue) != userId)

{

return Results.Forbid();

}

dbContext.Remove(post);

await dbContext.SaveChangesAsync(cancellationToken);

return Results.NoContent();

}

public static async Task<IResult> CreateReplyAsync(int postId, CreatePostRequest request, ClaimsPrincipal principal, PulseDbContext dbContext, CancellationToken cancellationToken)

{

var userIdValue = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? principal.FindFirst("sub")?.Value;

if (!int.TryParse(userIdValue, out var userId))

{

return Results.Unauthorized();

}

var content = request.Content?.Trim();

if (string.IsNullOrWhiteSpace(content))

{

return Results.BadRequest("Content is required.");

}

if (content.Length > 280)

{

return Results.BadRequest("Content must not exceed 280 characters.");

}

var postEntityType = dbContext.Model

.GetEntityTypes()

.SingleOrDefault(candidate => candidate.ClrType.Name == "Post");

if (postEntityType is null)

{

return Results.StatusCode(StatusCodes.Status500InternalServerError);

}

var parentPost = await dbContext.FindAsync(

postEntityType.ClrType,

new object?[] { postId },

cancellationToken);

if (parentPost is null)

{

return Results.NotFound();

}

var parentParentIdProperty = postEntityType.FindProperty("ParentPostId");

if (parentParentIdProperty is not null)

{

var parentParentId = dbContext.Entry(parentPost)

.Property(parentParentIdProperty.Name)

.CurrentValue;

if (parentParentId is not null)

{

return Results.BadRequest(

new ApiErrorResponse(

"Replies can only be created on root posts.",

"parentPostId"));

}

}

var replyEntityType = dbContext.Model

.GetEntityTypes()

.SingleOrDefault(candidate => candidate.ClrType.Name == "Reply")

?? postEntityType;

var reply = Activator.CreateInstance(replyEntityType.ClrType);

if (reply is null)

{

return Results.StatusCode(StatusCodes.Status500InternalServerError);

}

var contentProperty = replyEntityType.FindProperty("Content");

var authorIdProperty =

replyEntityType.FindProperty("AuthorId") ??

replyEntityType.FindProperty("UserId");

if (contentProperty is null || authorIdProperty is null)

{

return Results.StatusCode(StatusCodes.Status500InternalServerError);

}

var parentIdProperty =

replyEntityType.FindProperty("ParentPostId") ??

replyEntityType.FindProperty("ReplyToPostId");

if (parentIdProperty is null && replyEntityType != postEntityType)

{

parentIdProperty = replyEntityType.FindProperty("PostId");

}

if (parentIdProperty is null)

{

var selfReference = replyEntityType

.GetForeignKeys()

.FirstOrDefault(foreignKey =>

foreignKey.PrincipalEntityType == postEntityType &&

foreignKey.Properties.Count == 1);

parentIdProperty = selfReference?.Properties[0];

}

if (parentIdProperty is null)

{

return Results.StatusCode(StatusCodes.Status500InternalServerError);

}

var entry = dbContext.Entry(reply);

entry.Property(contentProperty.Name).CurrentValue = content;

entry.Property(authorIdProperty.Name).CurrentValue = userId;

entry.Property(parentIdProperty.Name).CurrentValue = postId;

var createdAtProperty = replyEntityType.FindProperty("CreatedAt");

if (createdAtProperty?.ClrType == typeof(DateTime))

{

entry.Property(createdAtProperty.Name).CurrentValue = DateTime.UtcNow;

}

if (createdAtProperty?.ClrType == typeof(DateTimeOffset))

{

entry.Property(createdAtProperty.Name).CurrentValue = DateTimeOffset.UtcNow;

}

dbContext.Add(reply);

await dbContext.SaveChangesAsync(cancellationToken);

var replyIdProperty =

replyEntityType.FindPrimaryKey()?.Properties.SingleOrDefault();

if (replyIdProperty is null)

{

return Results.StatusCode(StatusCodes.Status500InternalServerError);

}

var replyIdValue = dbContext.Entry(reply)

.Property(replyIdProperty.Name)

.CurrentValue;

if (replyIdValue is null)

{

return Results.StatusCode(StatusCodes.Status500InternalServerError);

}

return Results.Created(

"/api/v1/posts/" + postId + "/replies",

await BuildPostResponseAsync(

dbContext,

Convert.ToInt32(replyIdValue),

userId,

cancellationToken));

}

public static async Task<IResult> GetRepliesAsync(int postId, ClaimsPrincipal principal, PulseDbContext dbContext, CancellationToken cancellationToken)

{

var postEntityType = dbContext.Model

.GetEntityTypes()

.SingleOrDefault(candidate => candidate.ClrType.Name == "Post");

if (postEntityType is null)

{

return Results.StatusCode(StatusCodes.Status500InternalServerError);

}

var parentPost = await dbContext.FindAsync(

postEntityType.ClrType,

new object?[] { postId },

cancellationToken);

if (parentPost is null)

{

return Results.NotFound();

}

var replyEntityType = dbContext.Model

.GetEntityTypes()

.SingleOrDefault(candidate => candidate.ClrType.Name == "Reply")

?? postEntityType;

var parentIdProperty =

replyEntityType.FindProperty("ParentPostId") ??

replyEntityType.FindProperty("ReplyToPostId");

if (parentIdProperty is null && replyEntityType != postEntityType)

{

parentIdProperty = replyEntityType.FindProperty("PostId");

}

if (parentIdProperty is null)

{

var selfReference = replyEntityType

.GetForeignKeys()

.FirstOrDefault(foreignKey =>

foreignKey.PrincipalEntityType == postEntityType &&

foreignKey.Properties.Count == 1);

parentIdProperty = selfReference?.Properties[0];

}

if (parentIdProperty is null)

{

return Results.StatusCode(StatusCodes.Status500InternalServerError);

}

var setMethod = typeof(DbContext)

.GetMethods()

.Single(method =>

method.Name == "Set" &&

method.IsGenericMethodDefinition &&

method.GetParameters().Length == 0);

var genericSetMethod = setMethod.MakeGenericMethod(

replyEntityType.ClrType);

var set = genericSetMethod.Invoke(

dbContext,

null) as IQueryable;

if (set is null)

{

return Results.StatusCode(StatusCodes.Status500InternalServerError);

}

var candidates = set

.Cast<object>()

.ToList();

var replies = candidates

.Where(candidate =>

{

var parentValue = dbContext.Entry(candidate)

.Property(parentIdProperty.Name)

.CurrentValue;

return parentValue is not null &&

Convert.ToInt32(parentValue) == postId;

})

.ToList();

return Results.Ok(replies);

}

public static async Task<IResult> LikePostAsync(int postId, ClaimsPrincipal principal, PulseDbContext dbContext, CancellationToken cancellationToken)

{

var userIdValue = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? principal.FindFirst("sub")?.Value;

if (!int.TryParse(userIdValue, out var userId))

{

return Results.Unauthorized();

}

var postEntityType = dbContext.Model

.GetEntityTypes()

.SingleOrDefault(candidate => candidate.ClrType.Name == "Post");

if (postEntityType is null)

{

return Results.StatusCode(StatusCodes.Status500InternalServerError);

}

var post = await dbContext.FindAsync(

postEntityType.ClrType,

new object?[] { postId },

cancellationToken);

if (post is null)

{

return Results.NotFound();

}

var likeEntityType = dbContext.Model

.GetEntityTypes()

.FirstOrDefault(candidate =>

candidate.ClrType.Name == "PostLike" ||

candidate.ClrType.Name == "Like");

if (likeEntityType is null)

{

return Results.StatusCode(StatusCodes.Status500InternalServerError);

}

var postIdProperty =

likeEntityType.FindProperty("PostId");

var userIdProperty =

likeEntityType.FindProperty("UserId") ??

likeEntityType.FindProperty("AuthorId");

if (postIdProperty is null || userIdProperty is null)

{

return Results.StatusCode(StatusCodes.Status500InternalServerError);

}

var setMethod = typeof(DbContext)

.GetMethods()

.Single(method =>

method.Name == "Set" &&

method.IsGenericMethodDefinition &&

method.GetParameters().Length == 0);

var genericSetMethod = setMethod.MakeGenericMethod(

likeEntityType.ClrType);

var set = genericSetMethod.Invoke(

dbContext,

null) as IQueryable;

if (set is null)

{

return Results.StatusCode(StatusCodes.Status500InternalServerError);

}

var existingLike = set

.Cast<object>()

.ToList()

.FirstOrDefault(candidate =>

{

var candidateEntry = dbContext.Entry(candidate);

var candidatePostId = candidateEntry

.Property(postIdProperty.Name)

.CurrentValue;

var candidateUserId = candidateEntry

.Property(userIdProperty.Name)

.CurrentValue;

return candidatePostId is not null &&

candidateUserId is not null &&

Convert.ToInt32(candidatePostId) == postId &&

Convert.ToInt32(candidateUserId) == userId;

});

if (existingLike is not null)

{

return Results.Ok(

await BuildLikeResponseAsync(

dbContext,

postId,

userId,

cancellationToken));

}

var like = Activator.CreateInstance(

likeEntityType.ClrType);

if (like is null)

{

return Results.StatusCode(StatusCodes.Status500InternalServerError);

}

var likeEntry = dbContext.Entry(like);

likeEntry.Property(postIdProperty.Name).CurrentValue = postId;

likeEntry.Property(userIdProperty.Name).CurrentValue = userId;

var createdAtProperty = likeEntityType.FindProperty("CreatedAt");

if (createdAtProperty?.ClrType == typeof(DateTime))

{

likeEntry.Property(createdAtProperty.Name).CurrentValue = DateTime.UtcNow;

}

if (createdAtProperty?.ClrType == typeof(DateTimeOffset))

{

likeEntry.Property(createdAtProperty.Name).CurrentValue = DateTimeOffset.UtcNow;

}

dbContext.Add(like);

await dbContext.SaveChangesAsync(cancellationToken);

return Results.Ok(

await BuildLikeResponseAsync(

dbContext,

postId,

userId,

cancellationToken));

}

public static async Task<IResult> UnlikePostAsync(int postId, ClaimsPrincipal principal, PulseDbContext dbContext, CancellationToken cancellationToken)

{

var userIdValue = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? principal.FindFirst("sub")?.Value;

if (!int.TryParse(userIdValue, out var userId))

{

return Results.Unauthorized();

}

var postEntityType = dbContext.Model

.GetEntityTypes()

.SingleOrDefault(candidate => candidate.ClrType.Name == "Post");

if (postEntityType is null)

{

return Results.StatusCode(StatusCodes.Status500InternalServerError);

}

var post = await dbContext.FindAsync(

postEntityType.ClrType,

new object?[] { postId },

cancellationToken);

if (post is null)

{

return Results.NotFound();

}

var likeEntityType = dbContext.Model

.GetEntityTypes()

.FirstOrDefault(candidate =>

candidate.ClrType.Name == "PostLike" ||

candidate.ClrType.Name == "Like");

if (likeEntityType is null)

{

return Results.StatusCode(StatusCodes.Status500InternalServerError);

}

var postIdProperty = likeEntityType.FindProperty("PostId");

var userIdProperty =

likeEntityType.FindProperty("UserId") ??

likeEntityType.FindProperty("AuthorId");

if (postIdProperty is null || userIdProperty is null)

{

return Results.StatusCode(StatusCodes.Status500InternalServerError);

}

var setMethod = typeof(DbContext)

.GetMethods()

.Single(method =>

method.Name == "Set" &&

method.IsGenericMethodDefinition &&

method.GetParameters().Length == 0);

var genericSetMethod = setMethod.MakeGenericMethod(

likeEntityType.ClrType);

var set = genericSetMethod.Invoke(

dbContext,

null) as IQueryable;

if (set is null)

{

return Results.StatusCode(StatusCodes.Status500InternalServerError);

}

var existingLike = set

.Cast<object>()

.ToList()

.FirstOrDefault(candidate =>

{

var candidateEntry = dbContext.Entry(candidate);

var candidatePostId = candidateEntry

.Property(postIdProperty.Name)

.CurrentValue;

var candidateUserId = candidateEntry

.Property(userIdProperty.Name)

.CurrentValue;

return candidatePostId is not null &&

candidateUserId is not null &&

Convert.ToInt32(candidatePostId) == postId &&

Convert.ToInt32(candidateUserId) == userId;

});

if (existingLike is null)

{

return Results.NotFound();

}

dbContext.Remove(existingLike);

await dbContext.SaveChangesAsync(cancellationToken);

return Results.Ok(

await BuildLikeResponseAsync(

dbContext,

postId,

userId,

cancellationToken));

}

private static async Task<PostResponse> BuildPostResponseAsync(

PulseDbContext dbContext,

int postId,

int userId,

CancellationToken cancellationToken)

{

var post = await dbContext.Posts

.Include(candidate => candidate.Author)

.SingleAsync(

candidate => candidate.Id == postId,

cancellationToken);

return await ToResponseAsync(

dbContext,

post,

userId,

cancellationToken);

}

private static async Task<LikeResponse> BuildLikeResponseAsync(

PulseDbContext dbContext,

int postId,

int userId,

CancellationToken cancellationToken)

{

var likeCount = await dbContext.PostLikes

.CountAsync(

like => like.PostId == postId,

cancellationToken);

var isLiked = await dbContext.PostLikes

.AnyAsync(

like =>

like.PostId == postId &&

like.UserId == userId,

cancellationToken);

return new LikeResponse(postId, isLiked, likeCount);

}

}