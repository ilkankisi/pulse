using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Pulse.Api.Data;

namespace Pulse.Api.Endpoints;

[NonController]
[Authorize]
public sealed class ProfilePostsController : ControllerBase
{
    private readonly PulseDbContext _dbContext;

    public ProfilePostsController(PulseDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    [HttpGet("/api/v1/profiles/{username}/posts")]
    public async Task<IActionResult> GetProfilePosts(
        string username,
        CancellationToken cancellationToken)
    {
        if (!int.TryParse(
                User.FindFirstValue(ClaimTypes.NameIdentifier),
                out var currentUserId))
        {
            return Unauthorized();
        }

        var normalizedUsername =
            username.Trim().ToUpperInvariant();

        var profile = await _dbContext.Users
            .AsNoTracking()
            .SingleOrDefaultAsync(
                user =>
                    user.NormalizedUsername ==
                    normalizedUsername,
                cancellationToken);

        if (profile is null)
        {
            return NotFound();
        }

        var isBlocked = await _dbContext.Blocks
            .AsNoTracking()
            .AnyAsync(
                block =>
                    (block.BlockerId == currentUserId &&
                     block.BlockedUserId == profile.Id) ||
                    (block.BlockerId == profile.Id &&
                     block.BlockedUserId == currentUserId),
                cancellationToken);

        if (isBlocked)
        {
            return NotFound();
        }

        var posts = await _dbContext.Posts
            .AsNoTracking()
            .Where(
                post =>
                    post.AuthorId == profile.Id &&
                    post.ParentPostId == null &&
                    post.DeletedAt == null)
            .ToListAsync(cancellationToken);

        var orderedPosts = posts
            .OrderByDescending(
                post => post.CreatedAtUtc)
            .ThenByDescending(
                post => post.Id)
            .ToList();

        var items =
            new List<object>(
                orderedPosts.Count);

        foreach (var post in orderedPosts)
        {
            items.Add(
                await PostEndpoints.ToResponseAsync(
                    _dbContext,
                    post,
                    currentUserId,
                    cancellationToken));
        }

        return Ok(new { items });
    }
}