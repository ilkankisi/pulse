using System.Text;

using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Pulse.Api.Auth;
using Pulse.Api.Data;
using Pulse.Api.Endpoints;
using Pulse.Api.OpenApi;
using Pulse.Api.RateLimiting;

namespace Pulse.Api;

public sealed class Startup
{
    private const string OpenApiDatabaseName =
        "PulseSwaggerOpenApiGeneration";

    private readonly IConfiguration _configuration;

    public Startup(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public void ConfigureServices(IServiceCollection services)
    {
        services.AddControllers();

        services.AddDbContext<PulseDbContext>(
            options =>
                options.UseInMemoryDatabase(OpenApiDatabaseName));

        var jwtKey =
            _configuration["Jwt:Key"]
            ?? "development-only-key-at-least-32-bytes";

        var jwtIssuer =
            _configuration["Jwt:Issuer"]
            ?? "Pulse.Api";

        var jwtAudience =
            _configuration["Jwt:Audience"]
            ?? "Pulse.Client";

        services
            .AddAuthentication(
                JwtBearerDefaults.AuthenticationScheme)
            .AddJwtBearer(
                options =>
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
                            ClockSkew = TimeSpan.Zero,
                        };
                });

        services.AddAuthorization();

        services.Configure<JwtOptions>(
            options =>
            {
                options.Key = jwtKey;
                options.Issuer = jwtIssuer;
                options.Audience = jwtAudience;
            });

        services.AddSingleton<PasswordService>();
        services.AddSingleton<JwtTokenService>();
        services.AddSingleton<AuthRateLimiter>();

        services.AddEndpointsApiExplorer();

        services.AddSwaggerGen(
            options =>
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
                        Description =
                            "JWT Authorization header using the Bearer scheme.",
                        Name = "Authorization",
                        In =
                            Microsoft.OpenApi.Models.ParameterLocation.Header,
                        Type =
                            Microsoft.OpenApi.Models
                                .SecuritySchemeType.Http,
                        Scheme = "Bearer",
                        BearerFormat = "JWT",
                    });

                options.OperationFilter<AuthorizeOperationFilter>();
            });
    }

    public void Configure(IApplicationBuilder app)
    {
        app.UseRouting();
        app.UseAuthentication();
        app.UseAuthorization();

        app.UseEndpoints(
            endpoints =>
            {
                endpoints.MapGet(
                        "/health",
                        () => Results.Ok(new { status = "ok" }))
                    .AllowAnonymous();

                endpoints.MapControllers();
                endpoints.MapAuthEndpoints();
                endpoints.MapPostEndpoints();
                endpoints.MapFeedEndpoints();
                endpoints.MapMeEndpoints();
                endpoints.MapProfileEndpoints();
                endpoints.MapSocialGraphEndpoints();
                endpoints.MapFollowEndpoints();
                endpoints.MapSecurityModerationEndpoints();
            });
    }
}