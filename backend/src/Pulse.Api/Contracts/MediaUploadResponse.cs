namespace Pulse.Api.Contracts;

public sealed record MediaUploadResponse(
    int Id,
    string Url,
    string MediaType,
    string ContentType,
    int? Width,
    int? Height);