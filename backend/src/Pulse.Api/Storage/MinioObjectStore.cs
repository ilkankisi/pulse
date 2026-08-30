using System.Globalization;
using System.Net;
using System.Security.Cryptography;
using System.Text;

namespace Pulse.Api.Storage;

public sealed class MinioObjectStore
{
    private static readonly byte[] EmptyPayloadHash =
        SHA256.HashData(Array.Empty<byte>());

    private readonly HttpClient _httpClient;
    private readonly Uri _endpoint;
    private readonly string _accessKey;
    private readonly string _secretKey;
    private readonly string _bucket;
    private readonly string _region;
    private readonly SemaphoreSlim _bucketGate =
        new(1, 1);

    private bool _bucketReady;

    public MinioObjectStore(
        HttpClient httpClient,
        IConfiguration configuration)
    {
        _httpClient = httpClient;

        _endpoint = new Uri(
            configuration["Minio:Endpoint"]
            ?? "http://127.0.0.1:9000");

        _accessKey =
            configuration["Minio:AccessKey"]
            ?? "minioadmin";

        _secretKey =
            configuration["Minio:SecretKey"]
            ?? "minioadmin";

        _bucket =
            configuration["Minio:Bucket"]
            ?? "pulse-media";

        _region =
            configuration["Minio:Region"]
            ?? "us-east-1";
    }

    public async Task PutAsync(
        string objectKey,
        byte[] content,
        string contentType,
        CancellationToken cancellationToken)
    {
        await EnsureBucketAsync(cancellationToken);

        using var request =
            CreateSignedRequest(
                HttpMethod.Put,
                ObjectPath(objectKey),
                content);

        request.Content =
            new ByteArrayContent(content);

        request.Content.Headers.ContentType =
            new System.Net.Http.Headers.MediaTypeHeaderValue(
                contentType);

        using var response =
            await _httpClient.SendAsync(
                request,
                cancellationToken);

        await EnsureSuccessAsync(
            response,
            cancellationToken);
    }

    public async Task<byte[]> GetAsync(
        string objectKey,
        CancellationToken cancellationToken)
    {
        await EnsureBucketAsync(cancellationToken);

        using var request =
            CreateSignedRequest(
                HttpMethod.Get,
                ObjectPath(objectKey),
                null);

        using var response =
            await _httpClient.SendAsync(
                request,
                cancellationToken);

        await EnsureSuccessAsync(
            response,
            cancellationToken);

        return await response.Content.ReadAsByteArrayAsync(
            cancellationToken);
    }

    private async Task EnsureBucketAsync(
        CancellationToken cancellationToken)
    {
        if (_bucketReady)
        {
            return;
        }

        await _bucketGate.WaitAsync(cancellationToken);

        try
        {
            if (_bucketReady)
            {
                return;
            }

            using var head =
                CreateSignedRequest(
                    HttpMethod.Head,
                    BucketPath(),
                    null);

            using var headResponse =
                await _httpClient.SendAsync(
                    head,
                    cancellationToken);

            if (headResponse.IsSuccessStatusCode)
            {
                _bucketReady = true;
                return;
            }

            if (headResponse.StatusCode
                != HttpStatusCode.NotFound)
            {
                await EnsureSuccessAsync(
                    headResponse,
                    cancellationToken);
            }

            using var create =
                CreateSignedRequest(
                    HttpMethod.Put,
                    BucketPath(),
                    Array.Empty<byte>());

            create.Content =
                new ByteArrayContent(
                    Array.Empty<byte>());

            using var createResponse =
                await _httpClient.SendAsync(
                    create,
                    cancellationToken);

            if (!createResponse.IsSuccessStatusCode
                && createResponse.StatusCode
                    != HttpStatusCode.Conflict)
            {
                await EnsureSuccessAsync(
                    createResponse,
                    cancellationToken);
            }

            _bucketReady = true;
        }
        finally
        {
            _bucketGate.Release();
        }
    }

    private HttpRequestMessage CreateSignedRequest(
        HttpMethod method,
        string canonicalPath,
        byte[]? payload)
    {
        var now = DateTimeOffset.UtcNow;
        var amzDate =
            now.ToString(
                "yyyyMMdd'T'HHmmss'Z'",
                CultureInfo.InvariantCulture);

        var dateStamp =
            now.ToString(
                "yyyyMMdd",
                CultureInfo.InvariantCulture);

        var payloadHash =
            Convert.ToHexString(
                    payload is null
                        ? EmptyPayloadHash
                        : SHA256.HashData(payload))
                .ToLowerInvariant();

        var requestUri =
            new Uri(
                _endpoint,
                canonicalPath);

        var host =
            requestUri.IsDefaultPort
                ? requestUri.Host
                : $"{requestUri.Host}:{requestUri.Port}";

        const string signedHeaders =
            "host;x-amz-content-sha256;x-amz-date";

        var canonicalHeaders =
            $"host:{host}\n"
            + $"x-amz-content-sha256:{payloadHash}\n"
            + $"x-amz-date:{amzDate}\n";

        var canonicalRequest =
            $"{method.Method}\n"
            + $"{canonicalPath}\n"
            + "\n"
            + canonicalHeaders
            + $"{signedHeaders}\n"
            + payloadHash;

        var credentialScope =
            $"{dateStamp}/{_region}/s3/aws4_request";

        var stringToSign =
            "AWS4-HMAC-SHA256\n"
            + $"{amzDate}\n"
            + $"{credentialScope}\n"
            + HexSha256(canonicalRequest);

        var signingKey =
            GetSignatureKey(
                _secretKey,
                dateStamp,
                _region,
                "s3");

        var signature =
            Convert.ToHexString(
                    Hmac(
                        signingKey,
                        stringToSign))
                .ToLowerInvariant();

        var authorization =
            "AWS4-HMAC-SHA256 "
            + $"Credential={_accessKey}/{credentialScope}, "
            + $"SignedHeaders={signedHeaders}, "
            + $"Signature={signature}";

        var request =
            new HttpRequestMessage(
                method,
                requestUri);

        request.Headers.TryAddWithoutValidation(
            "x-amz-date",
            amzDate);

        request.Headers.TryAddWithoutValidation(
            "x-amz-content-sha256",
            payloadHash);

        request.Headers.TryAddWithoutValidation(
            "Authorization",
            authorization);

        return request;
    }

    private string BucketPath()
    {
        return $"/{EncodeSegment(_bucket)}";
    }

    private string ObjectPath(
        string objectKey)
    {
        var encodedKey =
            string.Join(
                "/",
                objectKey
                    .Split(
                        '/',
                        StringSplitOptions.RemoveEmptyEntries)
                    .Select(EncodeSegment));

        return $"{BucketPath()}/{encodedKey}";
    }

    private static string EncodeSegment(
        string value)
    {
        return Uri.EscapeDataString(value)
            .Replace(
                "%7E",
                "~",
                StringComparison.OrdinalIgnoreCase);
    }

    private static string HexSha256(
        string value)
    {
        return Convert.ToHexString(
                SHA256.HashData(
                    Encoding.UTF8.GetBytes(value)))
            .ToLowerInvariant();
    }

    private static byte[] Hmac(
        byte[] key,
        string value)
    {
        using var hmac =
            new HMACSHA256(key);

        return hmac.ComputeHash(
            Encoding.UTF8.GetBytes(value));
    }

    private static byte[] GetSignatureKey(
        string secret,
        string dateStamp,
        string region,
        string service)
    {
        var kSecret =
            Encoding.UTF8.GetBytes(
                $"AWS4{secret}");

        var kDate =
            Hmac(
                kSecret,
                dateStamp);

        var kRegion =
            Hmac(
                kDate,
                region);

        var kService =
            Hmac(
                kRegion,
                service);

        return Hmac(
            kService,
            "aws4_request");
    }

    private static async Task EnsureSuccessAsync(
        HttpResponseMessage response,
        CancellationToken cancellationToken)
    {
        if (response.IsSuccessStatusCode)
        {
            return;
        }

        var body =
            await response.Content.ReadAsStringAsync(
                cancellationToken);

        throw new InvalidOperationException(
            $"MinIO request failed with {(int)response.StatusCode}: {body}");
    }
}