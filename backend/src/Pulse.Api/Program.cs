using System.Text;

using Microsoft.AspNetCore.Authentication.JwtBearer;

using Microsoft.EntityFrameworkCore;

using Microsoft.IdentityModel.Tokens;

using Pulse.Api.Auth;

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

app.MapPostEndpoints();

app.MapFeedEndpoints();

app.MapMeEndpoints();

app.MapProfileEndpoints();

app.MapFollowEndpoints();

app.MapSecurityModerationEndpoints();
app.MapSocialGraphEndpoints();

app.MapAccountExportEndpoints();
app.Run();

public partial class Program
{
}