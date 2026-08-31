using System.Collections.Concurrent;
using StackExchange.Redis;

namespace Pulse.Api.RateLimiting;

public sealed class AuthRateLimiter
{
    private readonly IConfiguration _configuration;
    private readonly IHostEnvironment _environment;
    private readonly ILogger<AuthRateLimiter> _logger;
    private readonly ConcurrentDictionary<string, LocalWindow> _localWindows =
        new(StringComparer.Ordinal);
    private readonly SemaphoreSlim _redisLock = new(1, 1);

    private IConnectionMultiplexer? _redis;
    private bool _redisInitializationAttempted;

    public AuthRateLimiter(
        IConfiguration configuration,
        IHostEnvironment environment,
        ILogger<AuthRateLimiter> logger)
    {
        _configuration = configuration;
        _environment = environment;
        _logger = logger;
    }

    public Task<bool> CheckRegisterAsync(
        string partition,
        CancellationToken cancellationToken = default)
    {
        return CheckAsync(
            operation: "register",
            partition: partition,
            permitLimit: GetPositiveInt(
                "RateLimiting:Register:PermitLimit",
                5),
            windowSeconds: GetPositiveInt(
                "RateLimiting:Register:WindowSeconds",
                60),
            cancellationToken: cancellationToken);
    }

    public Task<bool> CheckLoginAsync(
        string partition,
        CancellationToken cancellationToken = default)
    {
        return CheckAsync(
            operation: "login",
            partition: partition,
            permitLimit: GetPositiveInt(
                "RateLimiting:Login:PermitLimit",
                10),
            windowSeconds: GetPositiveInt(
                "RateLimiting:Login:WindowSeconds",
                60),
            cancellationToken: cancellationToken);
    }

    public Task<bool> IsRegisterAllowedAsync(
        string partition,
        CancellationToken cancellationToken = default)
    {
        return CheckRegisterAsync(
            partition,
            cancellationToken);
    }

    public Task<bool> IsLoginAllowedAsync(
        string partition,
        CancellationToken cancellationToken = default)
    {
        return CheckLoginAsync(
            partition,
            cancellationToken);
    }

    public async Task<bool> CheckAsync(
        string operation,
        string partition,
        int permitLimit,
        int windowSeconds,
        CancellationToken cancellationToken = default)
    {
        if (permitLimit <= 0 || windowSeconds <= 0)
        {
            return true;
        }

        var normalizedPartition =
            string.IsNullOrWhiteSpace(partition)
                ? "unknown"
                : partition.Trim().ToLowerInvariant();

        var redis = await GetRedisAsync(cancellationToken);

        if (redis is not null)
        {
            try
            {
                return await CheckRedisAsync(
                    redis,
                    operation,
                    normalizedPartition,
                    permitLimit,
                    windowSeconds);
            }
            catch (RedisException exception)
            {
                _logger.LogWarning(
                    exception,
                    "Redis rate limit check failed; local fallback will be used.");
            }
        }

        return CheckLocal(
            operation,
            normalizedPartition,
            permitLimit,
            windowSeconds);
    }

    private async Task<IConnectionMultiplexer?> GetRedisAsync(
        CancellationToken cancellationToken)
    {
        if (_redisInitializationAttempted)
        {
            return _redis;
        }

        await _redisLock.WaitAsync(cancellationToken);

        try
        {
            if (_redisInitializationAttempted)
            {
                return _redis;
            }

            _redisInitializationAttempted = true;

            var connectionString =
                _configuration.GetConnectionString("Redis")
                ?? _configuration["Redis:ConnectionString"];

            if (string.IsNullOrWhiteSpace(connectionString))
            {
                return null;
            }

            try
            {
                _redis = await ConnectionMultiplexer.ConnectAsync(
                    connectionString);
            }
            catch (RedisException exception)
            {
                _logger.LogWarning(
                    exception,
                    "Redis connection could not be established; local rate limit fallback will be used.");
            }

            return _redis;
        }
        finally
        {
            _redisLock.Release();
        }
    }

    private static async Task<bool> CheckRedisAsync(
        IConnectionMultiplexer redis,
        string operation,
        string partition,
        int permitLimit,
        int windowSeconds)
    {
        var database = redis.GetDatabase();
        var window = DateTimeOffset.UtcNow.ToUnixTimeSeconds()
            / windowSeconds;
        var key =
            $"pulse:rate-limit:auth:{operation}:{partition}:{window}";

        var count = await database.StringIncrementAsync(key);

        if (count == 1)
        {
            await database.KeyExpireAsync(
                key,
                TimeSpan.FromSeconds(windowSeconds + 1));
        }

        return count <= permitLimit;
    }

    private bool CheckLocal(
        string operation,
        string partition,
        int permitLimit,
        int windowSeconds)
    {
        var key = $"{operation}:{partition}";
        var now = DateTimeOffset.UtcNow;

        var window = _localWindows.AddOrUpdate(
            key,
            _ => new LocalWindow(now, 1),
            (_, current) =>
            {
                if (now - current.StartedAt
                    >= TimeSpan.FromSeconds(windowSeconds))
                {
                    return new LocalWindow(now, 1);
                }

                return current with
                {
                    Count = current.Count + 1
                };
            });

        if (_localWindows.Count > 10_000)
        {
            RemoveExpiredWindows(
                now,
                windowSeconds);
        }

        return window.Count <= permitLimit;
    }

    private void RemoveExpiredWindows(
        DateTimeOffset now,
        int windowSeconds)
    {
        foreach (var entry in _localWindows)
        {
            if (now - entry.Value.StartedAt
                >= TimeSpan.FromSeconds(windowSeconds * 2))
            {
                _localWindows.TryRemove(
                    entry.Key,
                    out _);
            }
        }
    }

    private int GetPositiveInt(
        string key,
        int fallback)
    {
        return int.TryParse(
                _configuration[key],
                out var configured)
            && configured > 0
                ? configured
                : fallback;
    }

    private sealed record LocalWindow(
        DateTimeOffset StartedAt,
        int Count);
}