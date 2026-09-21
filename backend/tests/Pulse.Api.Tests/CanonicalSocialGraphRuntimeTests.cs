using System.Net;
using System.Net.Http.Json;
using System.Reflection;
using System.Security.Claims;
using System.Text.Encodings.Web;
using System.Text.Json;

using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

using Pulse.Api.Data;
using Pulse.Api.Domain;

namespace Pulse.Api.Tests;

public sealed class CanonicalSocialGraphRuntimeTests
{
    [Fact]
    public async Task Reply_create_is_immediately_visible_from_canonical_get()
    {
        await using var factory = new AuthenticatedFactory();
        await SeedAsync(
            factory,
            db =>
            {
                db.Users.Add(CreateUser(1, "viewer"));
                db.Posts.Add(
                    CreateEntity<Post>(
                        ("Id", 100),
                        ("AuthorId", 1),
                        ("Content", "root post"),
                        ("CreatedAtUtc", DateTimeOffset.UtcNow)));
            });

        using var client = factory.CreateClient();

        var createResponse = await client.PostAsJsonAsync(
            "/api/v1/posts/100/replies",
            new
            {
                content = "runtime reply",
            });

        Assert.Equal(
            HttpStatusCode.Created,
            createResponse.StatusCode);

        using var createJson = JsonDocument.Parse(
            await createResponse.Content.ReadAsStringAsync());

        var createdId =
            createJson.RootElement.GetProperty("id").GetInt32();

        var readResponse = await client.GetAsync(
            "/api/v1/posts/100/replies");

        Assert.Equal(
            HttpStatusCode.OK,
            readResponse.StatusCode);

        using var readJson = JsonDocument.Parse(
            await readResponse.Content.ReadAsStringAsync());

        Assert.Equal(
        JsonValueKind.Array,
            readJson.RootElement.ValueKind);
        var createdReply = readJson.RootElement
        .EnumerateArray()
        .Single(
        item =>
        item.GetProperty("id").GetInt32()
        == createdId);

        Assert.Equal(
            "runtime reply",
            createdReply.GetProperty("content").GetString());
    }

    [Fact]
    public async Task Followers_and_following_return_empty_items_for_empty_graph()
    {
        await using var factory = new AuthenticatedFactory();
        await SeedAsync(
            factory,
            db =>
            {
                db.Users.Add(CreateUser(1, "viewer"));
            });

        using var client = factory.CreateClient();

        foreach (var path in new[]
                 {
                     "/api/v1/profiles/viewer/followers",
                     "/api/v1/profiles/viewer/following",
                 })
        {
            var response = await client.GetAsync(path);

            Assert.Equal(
                HttpStatusCode.OK,
                response.StatusCode);

            using var json = JsonDocument.Parse(
                await response.Content.ReadAsStringAsync());

            var items =
                json.RootElement.GetProperty("items");

            Assert.Equal(
                JsonValueKind.Array,
                items.ValueKind);

            Assert.Empty(items.EnumerateArray());
        }
    }

    [Fact]
    public async Task Social_graph_gets_hide_missing_blocked_and_inactive_profiles()
    {
        await using var factory = new AuthenticatedFactory();
        await SeedAsync(
            factory,
            db =>
            {
                var viewer = CreateUser(1, "viewer");
                var blocked = CreateUser(2, "blocked");
                var inactive = CreateUser(
                    3,
                    "inactive",
                    active: false);

                db.Users.AddRange(
                    viewer,
                    blocked,
                    inactive);

                db.Blocks.Add(
                    CreateEntity<Block>(
                        ("BlockerId", 1),
                        ("BlockedUserId", 2),
                        ("CreatedAtUtc", DateTimeOffset.UtcNow)));
            });

        using var client = factory.CreateClient();

        foreach (var suffix in new[]
                 {
                     "followers",
                     "following",
                 })
        {
            Assert.Equal(
                HttpStatusCode.NotFound,
                (await client.GetAsync(
                    $"/api/v1/profiles/missing/{suffix}"))
                .StatusCode);

            Assert.Equal(
                HttpStatusCode.NotFound,
                (await client.GetAsync(
                    $"/api/v1/profiles/blocked/{suffix}"))
                .StatusCode);

            Assert.Equal(
                HttpStatusCode.NotFound,
                (await client.GetAsync(
                    $"/api/v1/profiles/inactive/{suffix}"))
                .StatusCode);
        }
    }

    private static async Task SeedAsync(
        AuthenticatedFactory factory,
        Action<PulseDbContext> seed)
    {
        using var scope =
            factory.Services.CreateScope();

        var db =
            scope.ServiceProvider
                .GetRequiredService<PulseDbContext>();

        await db.Database.EnsureDeletedAsync();
        await db.Database.EnsureCreatedAsync();

        seed(db);

        await db.SaveChangesAsync();
    }

    private static User CreateUser(
        int id,
        string username,
        bool active = true)
    {
        var user =
            CreateEntity<User>(
                ("Id", id),
                ("Username", username),
                ("NormalizedUsername", username.ToUpperInvariant()),
                ("DisplayName", username),
                ("Email", $"{username}@example.test"),
                ("NormalizedEmail", $"{username}@example.test".ToUpperInvariant()),
                ("PasswordHash", "integration-test"),
                ("CreatedAtUtc", DateTimeOffset.UtcNow),
                ("JoinedAtUtc", DateTimeOffset.UtcNow));

        SetIfPresent(user, "IsActive", active);
        SetIfPresent(user, "IsDisabled", !active);
        SetIfPresent(user, "IsDeleted", !active);

        if (!active)
        {
            SetIfPresent(
                user,
                "DeactivatedAtUtc",
                DateTimeOffset.UtcNow);

            SetIfPresent(
                user,
                "DeactivatedAt",
                DateTimeOffset.UtcNow);
        }

        return user;
    }

    private static T CreateEntity<T>(
        params (string Name, object? Value)[] values)
        where T : class
    {
        var entity =
            (T)(Activator.CreateInstance(
                    typeof(T),
                    nonPublic: true)
                ?? throw new InvalidOperationException(
                    $"Could not create {typeof(T).Name}."));

        foreach (var (name, value) in values)
        {
            SetIfPresent(entity, name, value);
        }

        return entity;
    }

    private static void SetIfPresent(
        object instance,
        string propertyName,
        object? value)
    {
        var property =
            instance.GetType().GetProperty(
                propertyName,
                BindingFlags.Instance
                | BindingFlags.Public
                | BindingFlags.NonPublic);

        if (property?.CanWrite != true)
        {
            return;
        }

        if (value is not null
            && !property.PropertyType.IsInstanceOfType(value))
        {
            return;
        }

        property.SetValue(instance, value);
    }

    private sealed class AuthenticatedFactory
        : WebApplicationFactory<Program>
    {
        protected override void ConfigureWebHost(
            IWebHostBuilder builder)
        {
            builder.UseEnvironment("Testing");

            builder.ConfigureServices(
                services =>
                {
                    services
                        .AddAuthentication(
                            options =>
                            {
                                options.DefaultAuthenticateScheme =
                                    TestAuthenticationHandler.Scheme;
                                options.DefaultChallengeScheme =
                                    TestAuthenticationHandler.Scheme;
                            })
                        .AddScheme<
                            AuthenticationSchemeOptions,
                            TestAuthenticationHandler>(
                            TestAuthenticationHandler.Scheme,
                            _ =>
                            {
                            });
                });
        }
    }

    private sealed class TestAuthenticationHandler
        : AuthenticationHandler<AuthenticationSchemeOptions>
    {
        public const string Scheme = "CanonicalRuntimeTest";

        public TestAuthenticationHandler(
            IOptionsMonitor<AuthenticationSchemeOptions> options,
            ILoggerFactory logger,
            UrlEncoder encoder)
            : base(
                options,
                logger,
                encoder)
        {
        }

        protected override Task<AuthenticateResult>
            HandleAuthenticateAsync()
        {
            var identity =
                new ClaimsIdentity(
                    new[]
                    {
                        new Claim(
                            ClaimTypes.NameIdentifier,
                            "1"),
                        new Claim(
                            ClaimTypes.Name,
                            "viewer"),
                    },
                    Scheme);

            var principal =
                new ClaimsPrincipal(identity);

            var ticket =
                new AuthenticationTicket(
                    principal,
                    Scheme);

            return Task.FromResult(
                AuthenticateResult.Success(ticket));
        }
    }
}