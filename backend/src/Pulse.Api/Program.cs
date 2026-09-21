using System.Security.Claims;
using System.Text;

using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

using Pulse.Api.Auth;
using Pulse.Api.Contracts;
using Pulse.Api.Data;
using Pulse.Api.Endpoints;
using Pulse.Api.OpenApi;
using Pulse.Api.RateLimiting;

const string flutterWebCorsPolicy = "FlutterWeb";

const string developmentJwtKey =
    "development-signing-key-at-least-32-bytes-long-2026";

var builder = WebApplication.CreateBuilder(args);

var openapiMode =
    Environment.GetEnvironmentVariable(
        "ORCHESTRATOR_OPENAPI_GENERATION") == "1"
    || builder.Environment.IsEnvironment(
        "OpenApiGeneration");

if (openapiMode)
{
    builder.Configuration.AddInMemoryCollection(
        new Dictionary<string, string?>
        {
            ["RateLimiting:Register:PermitLimit"] = "1000",
            ["RateLimiting:Register:WindowSeconds"] = "60",
            ["RateLimiting:Login:PermitLimit"] = "1000",
            ["RateLimiting:Login:WindowSeconds"] = "60",
        });
}

var configuredJwtKey = builder.Configuration["Jwt:Key"];
var jwtKey = configuredJwtKey;

if (string.IsNullOrWhiteSpace(jwtKey)
    || Encoding.UTF8.GetByteCount(jwtKey) < 32)
{
    if (builder.Environment.IsProduction())
    {
        throw new InvalidOperationException(
            "Jwt:Key must be configured with at least 32 bytes in production.");
    }

    jwtKey = developmentJwtKey;
}

builder.Configuration.AddInMemoryCollection(
    new Dictionary<string, string?>
    {
        ["Jwt:Key"] = jwtKey,
    });

if (openapiMode
    || builder.Environment.IsEnvironment("Testing"))
{
    builder.Services.AddDbContext<PulseDbContext>(
        options =>
            options.UseInMemoryDatabase(
                "PulseOpenApiGeneration"));
}
else
{
    builder.Services.AddDbContext<PulseDbContext>(
        options =>
            options.UseSqlite(
                builder.Configuration.GetConnectionString(
                    "DefaultConnection")
                ?? "Data Source=pulse.db"));
}

builder.Services.Configure<JwtOptions>(
    builder.Configuration.GetSection("Jwt"));

builder.Services.AddSingleton<PasswordService>();
builder.Services.AddSingleton<JwtTokenService>();
builder.Services.AddSingleton<AuthRateLimiter>();

builder.Services
    .AddAuthentication(
        options =>
        {
            options.DefaultAuthenticateScheme =
                JwtBearerDefaults.AuthenticationScheme;
            options.DefaultChallengeScheme =
                JwtBearerDefaults.AuthenticationScheme;
        })
    .AddJwtBearer();

builder.Services
    .AddOptions<JwtBearerOptions>(
        JwtBearerDefaults.AuthenticationScheme)
    .Configure<IConfiguration>(
        (options, configuration) =>
        {
            var validationKey = configuration["Jwt:Key"];

            if (string.IsNullOrWhiteSpace(validationKey)
                || Encoding.UTF8.GetByteCount(validationKey) < 32)
            {
                throw new InvalidOperationException(
                    "Jwt:Key must contain at least 32 bytes.");
            }

            options.TokenValidationParameters =
                new TokenValidationParameters
                {
                    ValidateIssuer = true,
                    ValidIssuer =
                        configuration["Jwt:Issuer"]
                        ?? "Pulse.Api",
                    ValidateAudience = true,
                    ValidAudience =
                        configuration["Jwt:Audience"]
                        ?? "Pulse.Client",
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey =
                        new SymmetricSecurityKey(
                            Encoding.UTF8.GetBytes(
                                validationKey)),
                    ValidateLifetime = true,
                    ClockSkew = TimeSpan.Zero,
                };
        });

builder.Services.AddAuthorization();

builder.Services.AddCors(
    options =>
    {
        options.AddPolicy(
            flutterWebCorsPolicy,
            policy =>
            {
                policy
                    .WithOrigins(
                        "http://127.0.0.1:8080",
                        "http://localhost:8080")
                    .AllowAnyHeader()
                    .AllowAnyMethod();
            });
    });

builder.Services.AddEndpointsApiExplorer();
builder.Services.ConfigureHttpJsonOptions(
    options =>
    {
        options.SerializerOptions.ReferenceHandler =
            System.Text.Json.Serialization.ReferenceHandler.IgnoreCycles;
    });

builder.Services.AddSwaggerGen(
options =>
{
options.OperationFilter<AuthorizeOperationFilter>();
});

var app = builder.Build();

if (!openapiMode
    && !app.Environment.IsEnvironment("Testing"))
{
    using var scope = app.Services.CreateScope();

    var db =
        scope.ServiceProvider
            .GetRequiredService<PulseDbContext>();

    db.Database.Migrate();
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseRouting();
app.UseCors(flutterWebCorsPolicy);
app.UseAuthentication();
app.UseAuthorization();

app.MapGet(
        "/health",
        () => Results.Ok(
            new
            {
                status = "ok",
            }))
    .AllowAnonymous()
    .WithName("Health");

app.MapAuthEndpoints();

app.MapPost(
        "/api/v1/posts",
        PostEndpoints.CreatePostAsync)
    .Accepts<CreatePostRequest>("application/json")
    .Produces<PostResponse>(StatusCodes.Status201Created)
    .Produces<ApiErrorResponse>(StatusCodes.Status400BadRequest)
    .RequireAuthorization()
    .WithName("CreatePost");

app.MapDelete(
        "/api/v1/posts/{postId}",
        PostEndpoints.DeletePostAsync)
    .RequireAuthorization();

app.MapPost(
"/api/v1/posts/{postId}/replies",
PostEndpoints.CreateReplyAsync)
.Accepts<CreateReplyRequest>("application/json")
.Produces<PostResponse>(StatusCodes.Status201Created)
.Produces<ApiErrorResponse>(StatusCodes.Status400BadRequest)
.RequireAuthorization()
.WithName("CreatePostReply");
app.MapGet(
"/api/v1/posts/{postId}/replies",
PostEndpoints.GetRepliesAsync)
.RequireAuthorization();
app.MapPost(
"/api/v1/posts/{postId}/likes",
PostEndpoints.LikePostAsync)
.RequireAuthorization();

app.MapDelete(
        "/api/v1/posts/{postId}/likes",
        PostEndpoints.UnlikePostAsync)
    .RequireAuthorization();

app.MapFeedEndpoints();
app.MapMeEndpoints();
app.MapProfileEndpoints();
app.MapFollowEndpoints();
app.MapSecurityModerationEndpoints();
app.MapAccountExportEndpoints();

app.Run();

static async Task<IResult> GetPostAsync(
    int postId,
    ClaimsPrincipal principal,
    PulseDbContext dbContext,
    CancellationToken cancellationToken)
{
    if (!PostEndpoints.TryGetUserId(
            principal,
            out var userId))
    {
        return Results.Unauthorized();
    }

    var post = await dbContext.Posts
        .AsNoTracking()
        .Include(candidate => candidate.Author)
        .SingleOrDefaultAsync(
            candidate =>
                candidate.Id == postId
                && candidate.DeletedAt == null,
            cancellationToken);

    if (post is null)
    {
        return Results.NotFound();
    }

    return Results.Ok(
        await PostEndpoints.ToResponseAsync(
            dbContext,
            post,
            userId,
            cancellationToken));
}

static async Task<IResult> GetPostLikesAsync(
    int postId,
    ClaimsPrincipal principal,
    PulseDbContext dbContext,
    CancellationToken cancellationToken)
{
    if (!PostEndpoints.TryGetUserId(
            principal,
            out var userId))
    {
        return Results.Unauthorized();
    }

    var postExists = await dbContext.Posts
        .AsNoTracking()
        .AnyAsync(
            post =>
                post.Id == postId
                && post.DeletedAt == null,
            cancellationToken);

    if (!postExists)
    {
        return Results.NotFound();
    }

    var likeCount = await dbContext.PostLikes
        .AsNoTracking()
        .CountAsync(
            like => like.PostId == postId,
            cancellationToken);

    var isLiked = await dbContext.PostLikes
        .AsNoTracking()
        .AnyAsync(
            like =>
                like.PostId == postId
                && like.UserId == userId,
            cancellationToken);

    return Results.Ok(
        new LikeResponse(
            postId,
            isLiked,
            likeCount));
}

static Task<IResult> GetProfileBlockCompatibilityAsync(
    string username)
{
    return Task.FromResult<IResult>(
        Results.StatusCode(
            StatusCodes.Status405MethodNotAllowed));
}

static Task<IResult> GetProfileFollowCompatibilityAsync(
    string username)
{
    return Task.FromResult<IResult>(
        Results.StatusCode(
            StatusCodes.Status405MethodNotAllowed));
}

static Task<IResult> GetResolveReportCompatibilityAsync(
    int reportId)
{
    return Task.FromResult<IResult>(
        Results.StatusCode(
            StatusCodes.Status405MethodNotAllowed));
}

static Task<IResult> GetDismissReportCompatibilityAsync(
    int reportId)
{
    return Task.FromResult<IResult>(
        Results.StatusCode(
            StatusCodes.Status405MethodNotAllowed));
}

public partial class Program
{
}