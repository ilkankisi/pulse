using System.Collections.Generic;

namespace Pulse.Api.Contracts;

public sealed record HashtagPostListResponse(
    string Tag,
    IReadOnlyList<PostResponse> Items,
    string? NextCursor);