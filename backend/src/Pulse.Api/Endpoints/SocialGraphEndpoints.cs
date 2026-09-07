using Microsoft.EntityFrameworkCore;

using Pulse.Api.Data;

namespace Pulse.Api.Endpoints;

public static class SocialGraphEndpoints

{

public static IEndpointRouteBuilder MapSocialGraphEndpoints(

this IEndpointRouteBuilder endpoints)

{

endpoints.MapGet(

"/api/v1/profiles/{username}/followers",

async (

string username,

PulseDbContext db,

CancellationToken cancellationToken) =>

{

var profile = await db.Users

.AsNoTracking()

.SingleOrDefaultAsync(

user => user.Username == username,

cancellationToken);

            if (profile is null)
            {
                return Results.NotFound();
            }

            var followers = await (
                from follow in db.Follows.AsNoTracking()
                join user in db.Users.AsNoTracking()
                    on follow.FollowerId equals user.Id
                where follow.FollowingId == profile.Id
                orderby user.Username, user.Id
                select new
                {
                    id = user.Id,
                    username = user.Username,
                    displayName = user.DisplayName,
                })
                .ToListAsync(cancellationToken);

            return Results.Ok(followers);
        })
        .AllowAnonymous()
        .WithName("GetProfileFollowers");

    endpoints.MapGet(
        "/api/v1/profiles/{username}/following",
        async (
            string username,
            PulseDbContext db,
            CancellationToken cancellationToken) =>
        {
            var profile = await db.Users
                .AsNoTracking()
                .SingleOrDefaultAsync(
                    user => user.Username == username,
                    cancellationToken);

            if (profile is null)
            {
                return Results.NotFound();
            }

            var following = await (
                from follow in db.Follows.AsNoTracking()
                join user in db.Users.AsNoTracking()
                    on follow.FollowingId equals user.Id
                where follow.FollowerId == profile.Id
                orderby user.Username, user.Id
                select new
                {
                    id = user.Id,
                    username = user.Username,
                    displayName = user.DisplayName,
                })
                .ToListAsync(cancellationToken);

            return Results.Ok(following);
        })
        .AllowAnonymous()
        .WithName("GetProfileFollowing");

    return endpoints;
}

}