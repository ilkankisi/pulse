using System.IdentityModel.Tokens.Jwt;
using System.Net;
using System.Net.Http.Headers;
using System.Security.Claims;
using System.Text;
using System.Text.Json;

using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.IdentityModel.Tokens;

using Pulse.Api.Data;

using Xunit;

namespace Pulse.Api.Tests;
[CollectionDefinition(
    "PostDetailLikesEndpoint",
    DisableParallelization = true)]
public sealed class PostDetailLikesEndpointCollection;

[Collection("PostDetailLikesEndpoint")]
public sealed class PostDetailLikesEndpointTests
{
private const string JwtKey =
"development-signing-key-at-least-32-bytes-long-2026";

    [Fact]
    public async Task Get_post_likes_returns_liker_user_collection()
    {
        await using var factory =
        new WebApplicationFactory<Program>()
        .WithWebHostBuilder(
                    builder =>
                    {
                        builder.UseEnvironment("Testing");
                        builder.ConfigureAppConfiguration(
                            (_, configuration) =>
                            {
                                configuration.AddInMemoryCollection(
                                    new Dictionary<string, string?>
                                    {
                                        ["Jwt:Key"] = JwtKey,
                                        ["Jwt:Issuer"] = "Pulse.Api",
                                        ["Jwt:Audience"] = "Pulse.Client",
                                    });
                            });
                    });

        int userId;
        int postId;

        await using (var scope = factory.Services.CreateAsyncScope())
        {
            var dbContext =
                scope.ServiceProvider.GetRequiredService<PulseDbContext>();

            await dbContext.Database.EnsureDeletedAsync();
            await dbContext.Database.EnsureCreatedAsync();

            var user = CreateEntity(
                dbContext,
                "User",
                seed: 1);

            SetIfPresent(dbContext, user, "Username", "liker");
            SetIfPresent(dbContext, user, "NormalizedUsername", "LIKER");
            SetIfPresent(
                dbContext,
                user,
                "Email",
                "liker@example.com");
            SetIfPresent(
                dbContext,
                user,
                "NormalizedEmail",
                "LIKER@EXAMPLE.COM");
            SetIfPresent(
                dbContext,
                user,
                "DisplayName",
                "Liker User");
            SetIfPresent(
                dbContext,
                user,
                "AvatarUrl",
                "https://example.test/avatar.png");
            SetIfPresent(dbContext, user, "IsActive", true);

            dbContext.Add(user);
            await dbContext.SaveChangesAsync();

            userId = GetPrimaryKey(dbContext, user);

            var post = CreateEntity(
                dbContext,
                "Post",
                seed: 2);

            SetIfPresent(dbContext, post, "AuthorId", userId);
            SetIfPresent(dbContext, post, "UserId", userId);
            SetIfPresent(dbContext, post, "Content", "Post detail");
            SetIfPresent(
                dbContext,
                post,
                "CreatedAt",
                DateTime.UtcNow);

            dbContext.Add(post);
            await dbContext.SaveChangesAsync();

            postId = GetPrimaryKey(dbContext, post);

            var like = CreateEntity(
                dbContext,
                "PostLike",
                seed: 3);

            SetIfPresent(dbContext, like, "PostId", postId);
            SetIfPresent(dbContext, like, "UserId", userId);
            SetIfPresent(
                dbContext,
                like,
                "CreatedAt",
                DateTime.UtcNow);

            dbContext.Add(like);
            await dbContext.SaveChangesAsync();
        }

        using var client = factory.CreateClient();

        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue(
                "Bearer",
                CreateToken(userId));

        using var response =
            await client.GetAsync(
                $"/api/v1/posts/{postId}/likes");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        await using var stream =
            await response.Content.ReadAsStreamAsync();

        using var document =
            await JsonDocument.ParseAsync(stream);

        Assert.Equal(
            JsonValueKind.Array,
            document.RootElement.ValueKind);

        var users = document.RootElement
            .EnumerateArray()
            .ToArray();

        var liker = Assert.Single(users);

        Assert.Equal(
            userId,
            liker.GetProperty("id").GetInt32());
        Assert.Equal(
            "liker",
            liker.GetProperty("username").GetString());
        Assert.Equal(
            "Liker User",
            liker.GetProperty("displayName").GetString());
        Assert.Equal(
            "https://example.test/avatar.png",
            liker.GetProperty("avatarUrl").GetString());
    }

    private static string CreateToken(int userId)
    {
        var signingKey =
            new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(JwtKey));

        var token =
            new JwtSecurityToken(
                issuer: "Pulse.Api",
                audience: "Pulse.Client",
                claims:
                [
                    new Claim(
                        JwtRegisteredClaimNames.Sub,
                        userId.ToString()),
                    new Claim(
                        ClaimTypes.NameIdentifier,
                        userId.ToString()),
                ],
                expires: DateTime.UtcNow.AddMinutes(15),
                signingCredentials:
                    new SigningCredentials(
                        signingKey,
                        SecurityAlgorithms.HmacSha256));

        return new JwtSecurityTokenHandler()
            .WriteToken(token);
    }

    private static object CreateEntity(
        PulseDbContext dbContext,
        string entityName,
        int seed)
    {
        var entityType = dbContext.Model
            .GetEntityTypes()
            .Single(
                candidate =>
                    candidate.ClrType.Name == entityName);

        var entity =
            Activator.CreateInstance(entityType.ClrType)
            ?? throw new InvalidOperationException(
                $"Could not create {entityName}.");

        var entry = dbContext.Entry(entity);

        foreach (var property in entityType.GetProperties())
        {
            if (property.IsNullable
                || property.IsPrimaryKey())
            {
                continue;
            }

            var type =
                Nullable.GetUnderlyingType(property.ClrType)
                ?? property.ClrType;

            object? value =
                type == typeof(string)
                    ? $"{property.Name}-{seed}"
                    : type == typeof(bool)
                        ? true
                        : type == typeof(int)
                            ? 0
                            : type == typeof(long)
                                ? 0L
                                : type == typeof(DateTime)
                                    ? DateTime.UtcNow
                                    : type == typeof(DateTimeOffset)
                                        ? DateTimeOffset.UtcNow
                                        : type == typeof(Guid)
                                            ? Guid.NewGuid()
                                            : type.IsEnum
                                                ? Enum.GetValues(type)
                                                    .GetValue(0)
                                                : null;

            if (value is not null)
            {
                entry.Property(property.Name).CurrentValue =
                    value;
            }
        }

        return entity;
    }

    private static void SetIfPresent(
        PulseDbContext dbContext,
        object entity,
        string propertyName,
        object? value)
    {
        var entry = dbContext.Entry(entity);

        if (entry.Metadata.FindProperty(propertyName) is not null)
        {
            entry.Property(propertyName).CurrentValue = value;
        }
    }

    private static int GetPrimaryKey(
        PulseDbContext dbContext,
        object entity)
    {
        var entry = dbContext.Entry(entity);

        var keyProperty =
            entry.Metadata.FindPrimaryKey()
                ?.Properties.SingleOrDefault()
            ?? throw new InvalidOperationException(
                "Expected a single primary key.");

        return Convert.ToInt32(
            entry.Property(keyProperty.Name).CurrentValue);
    }
}