using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Pulse.Api.Auth;
using Pulse.Api.Data;
using Pulse.Api.Domain;
using Xunit;

namespace Pulse.Api.Tests;

public sealed class SecurityModerationIntegrationTests
{
    private const int postTargetValue = 0;
    private const int userTargetValue = 1;

    private const int spamReasonValue = 0;

    private const int pendingStatusValue = 0;
    private const int resolvedStatusValue = 1;
    private const int dismissedStatusValue = 2;

    private const int noActionValue = 0;
    private const int removePostActionValue = 1;

    [Fact]
    public async Task Block_requires_authentication()
    {
        using var factory =
            new SecurityModerationWebApplicationFactory();

        await factory.SeedAsync();

        using var client = factory.CreateClient();

        var response = await client.PostAsync(
            "/api/v1/profiles/bob/block",
            content: null);

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            response.StatusCode);
    }

    [Fact]
    public async Task User_can_block_list_and_unblock_user()
    {
        using var factory =
            new SecurityModerationWebApplicationFactory();

        await factory.SeedAsync();

        using var client =
            factory.CreateAuthenticatedClient(
                userId: 1,
                role: "user");

        var blockResponse = await client.PostAsync(
            "/api/v1/profiles/bob/block",
            content: null);

        Assert.Equal(
            HttpStatusCode.OK,
            blockResponse.StatusCode);

        var blockBody =
            await blockResponse.Content
                .ReadFromJsonAsync<JsonElement>();

        Assert.Equal(
            2,
            blockBody.GetProperty("id").GetInt32());

        Assert.Equal(
            "bob",
            blockBody.GetProperty("username").GetString());

        Assert.True(
            blockBody.GetProperty("isBlocked").GetBoolean());

        using (var scope = factory.Services.CreateScope())
        {
            var dbContext =
                scope.ServiceProvider
                    .GetRequiredService<PulseDbContext>();

            Assert.True(
                await dbContext.Blocks.AnyAsync(
                    block =>
                        block.BlockerId == 1 &&
                        block.BlockedUserId == 2));

            Assert.False(
                await dbContext.Follows.AnyAsync(
                    follow =>
                        (follow.FollowerId == 1 &&
                         follow.FollowingId == 2) ||
                        (follow.FollowerId == 2 &&
                         follow.FollowingId == 1)));
        }

        var listResponse =
            await client.GetAsync("/api/v1/blocks");

        Assert.Equal(
            HttpStatusCode.OK,
            listResponse.StatusCode);

        var listBody =
            await listResponse.Content
                .ReadFromJsonAsync<JsonElement>();

        var items =
            listBody.GetProperty("items");

        Assert.Equal(
            JsonValueKind.Array,
            items.ValueKind);

        Assert.Equal(
            1,
            items.GetArrayLength());

        Assert.Equal(
            "bob",
            items[0]
                .GetProperty("username")
                .GetString());

        var unblockResponse = await client.DeleteAsync(
            "/api/v1/profiles/bob/block");

        Assert.Equal(
            HttpStatusCode.NoContent,
            unblockResponse.StatusCode);

        var secondUnblockResponse =
            await client.DeleteAsync(
                "/api/v1/profiles/bob/block");

        Assert.Equal(
            HttpStatusCode.NoContent,
            secondUnblockResponse.StatusCode);

        var emptyListResponse =
            await client.GetAsync("/api/v1/blocks");

        Assert.Equal(
            HttpStatusCode.OK,
            emptyListResponse.StatusCode);

        var emptyListBody =
            await emptyListResponse.Content
                .ReadFromJsonAsync<JsonElement>();

        Assert.Equal(
            0,
            emptyListBody
                .GetProperty("items")
                .GetArrayLength());
    }

    [Fact]
    public async Task Authenticated_user_can_create_user_report()
    {
        using var factory =
            new SecurityModerationWebApplicationFactory();

        await factory.SeedAsync();

        using var client =
            factory.CreateAuthenticatedClient(
                userId: 1,
                role: "user");

        var response = await client.PostAsJsonAsync(
            "/api/v1/reports",
            new
            {
                targetType = "user",
                targetId = 2,
                reason = "spam",
                details = "Repeated unwanted messages."
            });

        Assert.Equal(
            HttpStatusCode.Created,
            response.StatusCode);

        var body =
            await response.Content
                .ReadFromJsonAsync<JsonElement>();

        Assert.Equal(
            "user",
            body.GetProperty("targetType").GetString());

        Assert.Equal(
            2,
            body.GetProperty("targetId").GetInt32());

        Assert.Equal(
            "spam",
            body.GetProperty("reason").GetString());

        Assert.Equal(
            "pending",
            body.GetProperty("status").GetString());

        var reportId =
            body.GetProperty("id").GetInt32();

        using var scope = factory.Services.CreateScope();

        var dbContext =
            scope.ServiceProvider
                .GetRequiredService<PulseDbContext>();

        var report = await dbContext.Reports
            .SingleAsync(
                item => item.Id == reportId);

        Assert.Equal(1, report.ReporterId);

        Assert.Equal(
            (ReportTargetType)userTargetValue,
            report.TargetType);

        Assert.Equal(2, report.TargetId);

        Assert.Equal(
            (ReportReason)spamReasonValue,
            report.Reason);

        Assert.Equal(
            (ReportStatus)pendingStatusValue,
            report.Status);
    }

    [Fact]
    public async Task Authenticated_user_can_create_fake_account_report()
    {
        using var factory =
            new SecurityModerationWebApplicationFactory();

        await factory.SeedAsync();

        using var client =
            factory.CreateAuthenticatedClient(
                userId: 1,
                role: "user");

        var response = await client.PostAsJsonAsync(
            "/api/v1/reports",
            new
            {
                targetType = "user",
                targetId = 2,
                reason = "fakeAccount",
                details = "Account identity report."
            });

        Assert.Equal(
            HttpStatusCode.Created,
            response.StatusCode);

        var body =
            await response.Content
                .ReadFromJsonAsync<JsonElement>();

        Assert.Equal(
            "user",
            body.GetProperty("targetType").GetString());

        Assert.Equal(
            "fakeAccount",
            body.GetProperty("reason").GetString());

        Assert.Equal(
            "pending",
            body.GetProperty("status").GetString());
    }

    [Fact]
    public async Task Moderation_routes_require_moderator_role()
    {
        using var factory =
            new SecurityModerationWebApplicationFactory();

        await factory.SeedAsync();

        using var regularClient =
            factory.CreateAuthenticatedClient(
                userId: 1,
                role: "user");

        var forbiddenResponse =
            await regularClient.GetAsync(
                "/api/v1/moderation/reports");

        Assert.Equal(
            HttpStatusCode.Forbidden,
            forbiddenResponse.StatusCode);

        using var moderatorClient =
            factory.CreateAuthenticatedClient(
                userId: 3,
                role: "moderator");

        var moderatorResponse =
            await moderatorClient.GetAsync(
                "/api/v1/moderation/reports");

        Assert.Equal(
            HttpStatusCode.OK,
            moderatorResponse.StatusCode);

        var body =
            await moderatorResponse.Content
                .ReadFromJsonAsync<JsonElement>();

        Assert.Equal(
            JsonValueKind.Array,
            body.GetProperty("items").ValueKind);
    }

    [Fact]
    public async Task moderator_can_resolve_post_report_with_remove_post()
    {
        using var factory =
            new SecurityModerationWebApplicationFactory();

        await factory.SeedAsync();

        const int reportId = 100;

        using (var scope = factory.Services.CreateScope())
        {
            var dbContext =
                scope.ServiceProvider
                    .GetRequiredService<PulseDbContext>();

            dbContext.Reports.Add(
                new Report
                {
                    Id = reportId,
                    ReporterId = 1,
                    TargetType =
                        (ReportTargetType)postTargetValue,
                    TargetId = 10,
                    Reason =
                        (ReportReason)spamReasonValue,
                    Details = "Reported post.",
                    Status =
                        (ReportStatus)pendingStatusValue,
                    CreatedAt = DateTime.UtcNow
                });

            await dbContext.SaveChangesAsync();
        }

        using var client =
            factory.CreateAuthenticatedClient(
                userId: 3,
                role: "moderator");

        var response = await client.PostAsJsonAsync(
            $"/api/v1/moderation/reports/{reportId}/resolve",
            new
            {
                action = "removePost",
                note = "Removed after review."
            });

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var body =
            await response.Content
                .ReadFromJsonAsync<JsonElement>();

        Assert.Equal(
            "resolved",
            body.GetProperty("status").GetString());

        Assert.Equal(
            "removePost",
            body.GetProperty("action").GetString());

        Assert.Equal(
            3,
            body.GetProperty("resolvedByUserId").GetInt32());

        using var verificationScope =
            factory.Services.CreateScope();

        var verificationDb =
            verificationScope.ServiceProvider
                .GetRequiredService<PulseDbContext>();

        var report =
            await verificationDb.Reports
                .SingleAsync(
                    item => item.Id == reportId);

        Assert.Equal(
            (ReportStatus)resolvedStatusValue,
            report.Status);

        Assert.Equal(
            3,
            report.ReviewedByUserId);

        Assert.NotNull(report.ReviewedAt);

        var post =
            await verificationDb.Posts
                .SingleAsync(
                    item => item.Id == 10);

        Assert.NotNull(post.DeletedAt);

        var moderationAction =
            await verificationDb.ModerationActions
                .SingleAsync(
                    item =>
                        item.ReportId == reportId);

        Assert.Equal(
            3,
            moderationAction.ModeratorUserId);

        Assert.Equal(
            (ModerationAction)removePostActionValue,
            moderationAction.Action);
    }

    [Fact]
    public async Task moderator_can_dismiss_pending_report()
    {
        using var factory =
            new SecurityModerationWebApplicationFactory();

        await factory.SeedAsync();

        const int reportId = 101;

        using (var scope = factory.Services.CreateScope())
        {
            var dbContext =
                scope.ServiceProvider
                    .GetRequiredService<PulseDbContext>();

            dbContext.Reports.Add(
                new Report
                {
                    Id = reportId,
                    ReporterId = 1,
                    TargetType =
                        (ReportTargetType)userTargetValue,
                    TargetId = 2,
                    Reason =
                        (ReportReason)spamReasonValue,
                    Details = "Reported user.",
                    Status =
                        (ReportStatus)pendingStatusValue,
                    CreatedAt = DateTime.UtcNow
                });

            await dbContext.SaveChangesAsync();
        }

        using var client =
            factory.CreateAuthenticatedClient(
                userId: 3,
                role: "moderator");

        var response = await client.PostAsync(
            $"/api/v1/moderation/reports/{reportId}/dismiss",
            content: null);

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var body =
            await response.Content
                .ReadFromJsonAsync<JsonElement>();

        Assert.Equal(
            "dismissed",
            body.GetProperty("status").GetString());

        Assert.Equal(
            "noAction",
            body.GetProperty("action").GetString());

        Assert.Equal(
            3,
            body.GetProperty("resolvedByUserId").GetInt32());

        using var verificationScope =
            factory.Services.CreateScope();

        var verificationDb =
            verificationScope.ServiceProvider
                .GetRequiredService<PulseDbContext>();

        var report =
            await verificationDb.Reports
                .SingleAsync(
                    item => item.Id == reportId);

        Assert.Equal(
            (ReportStatus)dismissedStatusValue,
            report.Status);

        Assert.Equal(
            3,
            report.ReviewedByUserId);

        Assert.NotNull(report.ReviewedAt);

        var moderationAction =
            await verificationDb.ModerationActions
                .SingleAsync(
                    item =>
                        item.ReportId == reportId);

        Assert.Equal(
            (ModerationAction)noActionValue,
            moderationAction.Action);

        Assert.Equal(
            3,
            moderationAction.ModeratorUserId);
    }

    private sealed class SecurityModerationWebApplicationFactory
        : WebApplicationFactory<Program>
    {
        private const string JwtKey =
            "testing-only-key-at-least-32-bytes-long";

        private const string JwtIssuer =
            "Pulse.Api";

        private const string JwtAudience =
            "Pulse.Client";

        private readonly string _databaseName =
            $"security-moderation-{Guid.NewGuid():N}";

        private readonly InMemoryDatabaseRoot _databaseRoot =
            new();

        protected override void ConfigureWebHost(
            IWebHostBuilder builder)
        {
            builder.UseEnvironment("Testing");

            builder.ConfigureAppConfiguration(
                (_, configurationBuilder) =>
                {
                    configurationBuilder.AddInMemoryCollection(
                        new Dictionary<string, string?>
                        {
                            ["Jwt:Key"] = JwtKey,
                            ["Jwt:Issuer"] = JwtIssuer,
                            ["Jwt:Audience"] = JwtAudience,
                            ["Jwt:ExpirationMinutes"] = "60"
                        });
                });

            builder.ConfigureServices(
                services =>
                {
                    services.RemoveAll<
                        DbContextOptions<PulseDbContext>>();

                    services.RemoveAll<PulseDbContext>();

                    services.AddDbContext<PulseDbContext>(
                        options =>
                            options.UseInMemoryDatabase(
                                _databaseName,
                                _databaseRoot));
                });
        }

        public async Task SeedAsync()
        {
            using var scope = Services.CreateScope();

            var dbContext =
                scope.ServiceProvider
                    .GetRequiredService<PulseDbContext>();

            await dbContext.Database.EnsureDeletedAsync();
            await dbContext.Database.EnsureCreatedAsync();

            dbContext.Users.AddRange(
                new User
                {
                    Id = 1,
                    Username = "alice",
                    NormalizedUsername =
                        "alice".ToUpperInvariant(),
                    Email = "alice@example.com",
                    NormalizedEmail =
                        "alice@example.com".ToUpperInvariant(),
                    DisplayName = "alice",
                    PasswordHash = "test",
                    Role = "user",
                    IsActive = true,
                    CreatedAtUtc =
                        DateTimeOffset.UtcNow
                            .AddMinutes(-10)
                },
                new User
                {
                    Id = 2,
                    Username = "bob",
                    NormalizedUsername =
                        "bob".ToUpperInvariant(),
                    Email = "bob@example.com",
                    NormalizedEmail =
                        "bob@example.com".ToUpperInvariant(),
                    DisplayName = "bob",
                    PasswordHash = "test",
                    Role = "user",
                    IsActive = true,
                    CreatedAtUtc =
                        DateTimeOffset.UtcNow
                            .AddMinutes(-9)
                },
                new User
                {
                    Id = 3,
                    Username = "moderator",
                    NormalizedUsername =
                        "moderator".ToUpperInvariant(),
                    Email = "moderator@example.com",
                    NormalizedEmail =
                        "moderator@example.com"
                            .ToUpperInvariant(),
                    DisplayName = "moderator",
                    PasswordHash = "test",
                    Role = "moderator",
                    IsActive = true,
                    CreatedAtUtc =
                        DateTimeOffset.UtcNow
                            .AddMinutes(-8)
                });

            dbContext.Follows.AddRange(
                new Follow
                {
                    FollowerId = 1,
                    FollowingId = 2,
                    CreatedAtUtc =
                        DateTimeOffset.UtcNow
                            .AddMinutes(-5)
                },
                new Follow
                {
                    FollowerId = 2,
                    FollowingId = 1,
                    CreatedAtUtc =
                        DateTimeOffset.UtcNow
                            .AddMinutes(-4)
                });

            dbContext.Posts.Add(
                new Post
                {
                    Id = 10,
                    AuthorId = 2,
                    Content = "Reported post",
                    CreatedAtUtc =
                        DateTimeOffset.UtcNow
                            .AddMinutes(-3)
                });

            await dbContext.SaveChangesAsync();
        }

        public HttpClient CreateAuthenticatedClient(
            int userId,
            string role)
        {
            var client = CreateClient();

            using var scope = Services.CreateScope();

            var dbContext =
                scope.ServiceProvider
                    .GetRequiredService<PulseDbContext>();

            var user = dbContext.Users
                .Single(
                    candidate =>
                        candidate.Id == userId);

            user.Role = role;
            dbContext.SaveChanges();

            var tokenService =
                scope.ServiceProvider
                    .GetRequiredService<JwtTokenService>();

            var accessToken =
                tokenService
                    .CreateToken(user)
                    .AccessToken;

            client.DefaultRequestHeaders.Authorization =
                new AuthenticationHeaderValue(
                    "Bearer",
                    accessToken);

            return client;
        }
    }
}