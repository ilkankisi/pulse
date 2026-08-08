using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using Pulse.Api.Domain;

namespace Pulse.Api.Auth;

public sealed class JwtOptions
{
    public string Key { get; set; } = string.Empty;

    public string Issuer { get; set; } = "Pulse.Api";

    public string Audience { get; set; } = "Pulse.Client";

    public int ExpirationMinutes { get; set; } = 60;
}

public sealed record JwtTokenResult(
    string AccessToken,
    long ExpiresIn,
    DateTimeOffset ExpiresAtUtc)
{
    public string Token => AccessToken;

    public static implicit operator string(
        JwtTokenResult result)
    {
        return result.AccessToken;
    }
}

public sealed class JwtTokenService
{
    private readonly JwtOptions _options;

    public JwtTokenService(
        IOptions<JwtOptions> options)
    {
        _options = options.Value;
    }

    public JwtTokenResult CreateToken(
        User user)
    {
        return Create(user);
    }

    public JwtTokenResult Create(
        User user)
    {
        if (Encoding.UTF8.GetByteCount(_options.Key) < 32)
        {
            throw new InvalidOperationException(
                "Jwt:Key must be at least 32 bytes.");
        }

        var now = DateTimeOffset.UtcNow;
        var expirationMinutes =
            _options.ExpirationMinutes > 0
                ? _options.ExpirationMinutes
                : 60;
        var expiresAt = now.AddMinutes(expirationMinutes);

        var claims = new[]
        {
            new Claim(
                JwtRegisteredClaimNames.Sub,
                user.Id.ToString()),
            new Claim(
                ClaimTypes.NameIdentifier,
                user.Id.ToString()),
            new Claim(
                JwtRegisteredClaimNames.UniqueName,
                user.Username),
            new Claim(
                ClaimTypes.Name,
                user.Username),
            new Claim(
                JwtRegisteredClaimNames.Email,
                user.Email),
            new Claim(
                JwtRegisteredClaimNames.Jti,
                Guid.NewGuid().ToString("N"))
        };

        var signingKey = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(_options.Key));

        var credentials = new SigningCredentials(
            signingKey,
            SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: _options.Issuer,
            audience: _options.Audience,
            claims: claims,
            notBefore: now.UtcDateTime,
            expires: expiresAt.UtcDateTime,
            signingCredentials: credentials);

        var accessToken =
            new JwtSecurityTokenHandler().WriteToken(token);

        return new JwtTokenResult(
            accessToken,
            (long)(expiresAt - now).TotalSeconds,
            expiresAt);
    }

    public string GenerateToken(
        User user)
    {
        return Create(user).AccessToken;
    }
}

public sealed class PasswordService
{
    private readonly PasswordHasher<User> _hasher = new();

    public string HashPassword(
        string password)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(password);

        return _hasher.HashPassword(
            new User(),
            password);
    }

    public string Hash(
        string password)
    {
        return HashPassword(password);
    }

    public bool VerifyPassword(
        string password,
        string passwordHash)
    {
        if (string.IsNullOrWhiteSpace(password)
            || string.IsNullOrWhiteSpace(passwordHash))
        {
            return false;
        }

        var result = _hasher.VerifyHashedPassword(
            new User(),
            passwordHash,
            password);

        return result is PasswordVerificationResult.Success
            or PasswordVerificationResult.SuccessRehashNeeded;
    }

    public bool Verify(
        string password,
        string passwordHash)
    {
        return VerifyPassword(password, passwordHash);
    }
}