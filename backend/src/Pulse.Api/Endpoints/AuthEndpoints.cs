using Microsoft.EntityFrameworkCore;

using Pulse.Api.Auth;

using Pulse.Api.Contracts;

using Pulse.Api.Data;

using Pulse.Api.Domain;

using Pulse.Api.RateLimiting;

namespace Pulse.Api.Endpoints;

public static class AuthEndpoints

{

public static IEndpointRouteBuilder MapAuthEndpoints(

this IEndpointRouteBuilder endpoints)

{

var group = endpoints.MapGroup("/api/v1/auth");

    group.MapPost("/register", RegisterAsync)
        .AllowAnonymous()
        .Produces(StatusCodes.Status201Created)
        .Produces(StatusCodes.Status400BadRequest)
        .Produces(StatusCodes.Status409Conflict);

    group.MapPost("/login", LoginAsync)
        .AllowAnonymous()
        .Produces(StatusCodes.Status200OK)
        .Produces(StatusCodes.Status400BadRequest)
        .Produces(StatusCodes.Status401Unauthorized);

    return endpoints;
}

private static async Task<IResult> RegisterAsync(
    RegisterBody request,
    HttpContext httpContext,
    PulseDbContext dbContext,
    PasswordService passwordService,
    JwtTokenService tokenService,
    AuthRateLimiter rateLimiter,
    CancellationToken cancellationToken)
{
    var partition =
        httpContext.Connection.RemoteIpAddress?.ToString()
        ?? "unknown";

    if (!await rateLimiter.CheckRegisterAsync(
            partition,
            cancellationToken))
    {
        return Results.Json(
            new ApiErrorResponse(
                "Too many registration attempts."),
            statusCode: StatusCodes.Status429TooManyRequests);
    }

    var username = request.Username?.Trim();
    var displayName = request.DisplayName?.Trim();
    var password = request.Password;

    if (string.IsNullOrWhiteSpace(username)
        || username.Length is < 3 or > 30
        || username.Any(
            character =>
                !char.IsLetterOrDigit(character)
                && character != '_'))
    {
        return ValidationError(
            "Username must contain 3 to 30 letters, numbers, or underscores.",
            "username");
    }

    if (string.IsNullOrWhiteSpace(displayName)
        || displayName.Length > 80)
    {
        return ValidationError(
            "Display name is required and cannot exceed 80 characters.",
            "displayName");
    }

    if (string.IsNullOrWhiteSpace(password)
        || password.Length < 8)
    {
        return ValidationError(
            "Password must contain at least 8 characters.",
            "password");
    }

    var normalizedUsername = Normalize(username);

    var usernameExists = await dbContext.Users.AnyAsync(
        user =>
            user.NormalizedUsername
            == normalizedUsername,
        cancellationToken);

    if (usernameExists)
    {
        return Results.Conflict(
            new ApiErrorResponse(
                "Username is already in use.",
                "username"));
    }

    var internalEmail = CreateInternalEmail(username);
    var normalizedEmail = Normalize(internalEmail);

    var user = new User
    {
        Username = username,
        NormalizedUsername = normalizedUsername,
        Email = internalEmail,
        NormalizedEmail = normalizedEmail,
        DisplayName = displayName,
        PasswordHash =
            passwordService.HashPassword(password),
        CreatedAtUtc = DateTimeOffset.UtcNow
    };

    dbContext.Users.Add(user);
    await dbContext.SaveChangesAsync(cancellationToken);

    var token = tokenService.CreateToken(user);

    return Results.Created(
        $"/api/v1/profiles/{user.Username}",
        CreateAuthResponse(user, token));
}

private static async Task<IResult> LoginAsync(
    LoginBody request,
    HttpContext httpContext,
    PulseDbContext dbContext,
    PasswordService passwordService,
    JwtTokenService tokenService,
    AuthRateLimiter rateLimiter,
    CancellationToken cancellationToken)
{
    var login =
        (request.Login ?? request.Username)?.Trim();

    if (string.IsNullOrWhiteSpace(login)
        || string.IsNullOrWhiteSpace(request.Password))
    {
        return ValidationError(
            "Login and password are required.",
            null);
    }

    var normalizedLogin = Normalize(login);

    var partition =
        $"{httpContext.Connection.RemoteIpAddress}:{normalizedLogin}";

    if (!await rateLimiter.CheckLoginAsync(
            partition,
            cancellationToken))
    {
        return Results.Json(
            new ApiErrorResponse(
                "Too many login attempts."),
            statusCode: StatusCodes.Status429TooManyRequests);
    }

    var user = await dbContext.Users
        .SingleOrDefaultAsync(
            candidate =>
                candidate.NormalizedUsername
                    == normalizedLogin
                || candidate.NormalizedEmail
                    == normalizedLogin,
            cancellationToken);

    if (user is null
        || !passwordService.VerifyPassword(
            request.Password,
            user.PasswordHash))
    {
        return Results.Unauthorized();
    }

    var token = tokenService.CreateToken(user);

    return Results.Ok(
        CreateAuthResponse(user, token));
}

private static object CreateAuthResponse(
    User user,
    JwtTokenResult token)
{
    return new
    {
        accessToken = token.AccessToken,
        tokenType = "Bearer",
        expiresIn = token.ExpiresIn,
        user = new AuthUserResponse(
            user.Id,
            user.Username,
            user.DisplayName,
            user.AvatarUrl)
    };
}

private static string CreateInternalEmail(
    string username)
{
    return $"{username}@pulse.local";
}

private static string Normalize(
    string value)
{
    return value.Trim().ToUpperInvariant();
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

private sealed record RegisterBody(
    string? Username,
    string? Password,
    string? DisplayName);

private sealed record LoginBody(
    string? Login,
    string? Username,
    string? Password);

}