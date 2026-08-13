using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Pulse.Api.Auth;
using Pulse.Api.Data;
using Pulse.Api.Endpoints;
using Pulse.Api.RateLimiting;

const string FlutterWebCorsPolicy = "FlutterWeb";

var builder = WebApplication.CreateBuilder(args);

var connectionString =
    builder.Configuration.GetConnectionString("Postgres")
    ?? "Host=127.0.0.1;Port=5432;Database=pulse;Username=pulse;Password=pulse";

builder.Services.AddDbContext<PulseDbContext>(
    options => options.UseNpgsql(connectionString));

var jwtKey = builder.Configuration["Jwt:Key"];

if (string.IsNullOrWhiteSpace(jwtKey)
    && (builder.Environment.IsDevelopment()
        || builder.Environment.IsEnvironment("Testing")))
{
    jwtKey = "development-only-key-at-least-32-bytes";
}

if (string.IsNullOrWhiteSpace(jwtKey))
{
    throw new InvalidOperationException("Jwt:Key configuration is required.");
}

if (Encoding.UTF8.GetByteCount(jwtKey) < 32)
{
    throw new InvalidOperationException(
        "Jwt:Key must be at least 32 bytes.");
}

var jwtIssuer = builder.Configuration["Jwt:Issuer"] ?? "Pulse.Api";
var jwtAudience = builder.Configuration["Jwt:Audience"] ?? "Pulse.Client";
var jwtExpirationMinutes =
    builder.Configuration.GetValue<int?>("Jwt:ExpirationMinutes") ?? 60;

builder.Services.Configure<JwtOptions>(
    options =>
    {
        options.Key = jwtKey;
        options.Issuer = jwtIssuer;
        options.Audience = jwtAudience;
        options.ExpirationMinutes = jwtExpirationMinutes;
    });

builder.Services.AddSingleton<JwtTokenService>();
builder.Services.AddSingleton<PasswordService>();
builder.Services.AddSingleton<AuthRateLimiter>();

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(
        options =>
        {
            options.MapInboundClaims = false;
            options.TokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidateAudience = true,
                ValidateIssuerSigningKey = true,
                ValidateLifetime = true,
                ValidIssuer = jwtIssuer,
                ValidAudience = jwtAudience,
                IssuerSigningKey = new SymmetricSecurityKey(
                    Encoding.UTF8.GetBytes(jwtKey)),
                ClockSkew = TimeSpan.Zero,
                NameClaimType = ClaimTypes.NameIdentifier,
                RoleClaimType = ClaimTypes.Role,
            };
        });

builder.Services.AddAuthorization();
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddCors(
    options =>
    {
        options.AddPolicy(
            FlutterWebCorsPolicy,
            policy =>
                policy
                    .WithOrigins(
                        "http://127.0.0.1:8080",
                        "http://localhost:8080")
                    .AllowAnyHeader()
                    .AllowAnyMethod());
    });

var app = builder.Build();

if (!app.Environment.IsEnvironment("Testing"))
{
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<PulseDbContext>();
    db.Database.Migrate();
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseRouting();
app.UseCors(FlutterWebCorsPolicy);
app.UseAuthentication();
app.UseAuthorization();

app.MapGet(
    "/health",
    () => Results.Ok(new { status = "ok" }));

app.MapControllers();
app.MapAuthEndpoints();
app.MapPostEndpoints();
app.MapFeedEndpoints();
app.MapMeEndpoints();
app.MapProfileEndpoints();
app.MapSocialGraphEndpoints();
app.MapFollowEndpoints();
app.MapSecurityModerationEndpoints();

app.Run();

public partial class Program
{
}