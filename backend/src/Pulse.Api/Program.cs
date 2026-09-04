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

var openapiMode =

Environment.GetEnvironmentVariable("ORCHESTRATOR_OPENAPI_GENERATION") == "1"

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

builder.Services

.AddControllers()

.AddApplicationPart(typeof(Program).Assembly);

if (openapiMode || builder.Environment.IsEnvironment("Testing"))

{

builder.Services.AddDbContext<PulseDbContext>(

options =>

options.UseInMemoryDatabase(

"PulseOpenApiGeneration"));

}

else

{

builder.Services.AddDbContext<PulseDbContext>();

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

var jwtKey =

configuration["Jwt:Key"]

?? "Pulse.Api.OpenApiGeneration.SigningKey.32Bytes.Minimum";

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

Encoding.UTF8.GetBytes(jwtKey)),

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

using var scope =

app.Services.CreateScope();

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

public partial class Program;