using System.Security.Claims;
using Pulse.Api.Contracts;
using Pulse.Api.Data;

namespace Pulse.Api.Endpoints;

public static class MeEndpoints
{
    public static IEndpointRouteBuilder MapMeEndpoints(
        this IEndpointRouteBuilder endpoints)
    {
        endpoints.MapGet(
                "/api/v1/me",
                GetCurrentProfileAsync)
            .RequireAuthorization()
            .WithTags("Profile");

        endpoints.MapPut(
                "/api/v1/me",
                UpdateCurrentProfileAsync)
            .RequireAuthorization()
            .WithTags("Profile");

        return endpoints;
    }

    private static Task<IResult> GetCurrentProfileAsync(
        ClaimsPrincipal principal,
        PulseDbContext db,
        CancellationToken cancellationToken)
    {
        return ProfileEndpoints.GetCurrentProfileContractAsync(
            principal,
            db,
            cancellationToken);
    }

    private static Task<IResult> UpdateCurrentProfileAsync(
        UpdateProfileRequest request,
        ClaimsPrincipal principal,
        PulseDbContext db,
        CancellationToken cancellationToken)
    {
        return ProfileEndpoints.UpdateCurrentProfileContractAsync(
            request,
            principal,
            db,
            cancellationToken);
    }
}
