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

var builder = WebApplication.CreateBuilder(args);

var openapiMode = Environment.GetEnvironmentVariable("ORCHESTRATOR_OPENAPI_GENERATION") == "1"

|| builder.Environment.IsEnvironment("OpenApiGeneration");

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

builder.Services.AddControllers();

if (openapiMode || builder.Environment.IsEnvironment("Testing"))

{

builder.Services.AddDbContext<PulseDbContext>(

options => options.UseInMemoryDatabase("PulseOpenApiGeneration"));

}

else

{

builder.Services.AddDbContext<PulseDbContext>();

}

var jwtKey = builder.Configuration["Jwt:Key"];

if (string.IsNullOrWhiteSpace(jwtKey))

{

if (builder.Environment.IsDevelopment() ||

builder.Environment.IsEnvironment("Testing") ||

openapiMode)

{

jwtKey = "development-only-key-at-least-32-bytes";

}

else

{

throw new InvalidOperationException(

"Jwt:Key must be configured.");

}

}

if (Encoding.UTF8.GetByteCount(jwtKey) < 32)

{

throw new InvalidOperationException(

"Jwt:Key must be at least 32 bytes.");

}

var jwtIssuer =

builder.Configuration["Jwt:Issuer"]

?? "Pulse.Api";

var jwtAudience =

builder.Configuration["Jwt:Audience"]

?? "Pulse.Client";

builder.Services

.AddAuthentication(

JwtBearerDefaults.AuthenticationScheme)

.AddJwtBearer(options =>

{

options.TokenValidationParameters =

new TokenValidationParameters

{

ValidateIssuer = true,

ValidIssuer = jwtIssuer,

ValidateAudience = true,

ValidAudience = jwtAudience,

ValidateIssuerSigningKey = true,

IssuerSigningKey =

new SymmetricSecurityKey(

Encoding.UTF8.GetBytes(jwtKey)),

ValidateLifetime = true,

ClockSkew = TimeSpan.Zero

};

});

builder.Services.AddAuthorization();

builder.Services.Configure<JwtOptions>(

options =>

{

options.Key = jwtKey;

options.Issuer = jwtIssuer;

options.Audience = jwtAudience;

});

builder.Services.AddSingleton<PasswordService>();

builder.Services.AddSingleton<JwtTokenService>();

builder.Services.AddSingleton<AuthRateLimiter>();

builder.Services.AddEndpointsApiExplorer();

builder.Services.AddSwaggerGen(options =>

{

options.SwaggerDoc(

"v1",

new Microsoft.OpenApi.Models.OpenApiInfo

{

Title = "Pulse API",

Version = "v1",

});

options.AddSecurityDefinition(

"Bearer",

new Microsoft.OpenApi.Models.OpenApiSecurityScheme

{

Description = "JWT Authorization header using the Bearer scheme.",

Name = "Authorization",

In = Microsoft.OpenApi.Models.ParameterLocation.Header,

Type = Microsoft.OpenApi.Models.SecuritySchemeType.Http,

Scheme = "Bearer",

BearerFormat = "JWT",

});

options.OperationFilter<AuthorizeOperationFilter>();

});

builder.Services.AddCors(options =>

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

var app = builder.Build();

if (!app.Environment.IsEnvironment("Testing") &&

!app.Environment.IsEnvironment("OpenApiGeneration"))

{

using var scope = app.Services.CreateScope();

var db = scope.ServiceProvider

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

() => Results.Ok(new { status = "ok" }))

.AllowAnonymous();

app.MapControllers();

app.MapAuthEndpoints();

app.MapPostEndpoints();

app.MapFeedEndpoints();

app.MapMeEndpoints();

app.MapProfileEndpoints();

app.MapSocialGraphEndpoints();

app.MapFollowEndpoints(); // POST /api/v1/profiles/{username}/follow

app.MapSecurityModerationEndpoints();

app.Run();

public partial class Program

{

}