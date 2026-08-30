namespace Pulse.Api.Domain;

public enum PostKind
{
    Post = 0,
    Repost = 1,
    Quote = 2
}

public enum MediaType
{
    Image = 0,
    Video = 1
}

public sealed class Bookmark
{
    public int UserId { get; set; }

    public int PostId { get; set; }

    public Post Post { get; set; } = null!;

    public DateTimeOffset CreatedAtUtc { get; set; }
}

public sealed class PostMedia
{
    public int Id { get; set; }

    public int OwnerUserId { get; set; }

    public int? PostId { get; set; }

    public Post? Post { get; set; }

    public string ObjectKey { get; set; } = string.Empty;

    public string Url { get; set; } = string.Empty;

    public MediaType MediaType { get; set; }

    public string ContentType { get; set; } = string.Empty;

    public int? Width { get; set; }

    public int? Height { get; set; }

    public DateTimeOffset CreatedAtUtc { get; set; }
}

public sealed class PostMention
{
    public int PostId { get; set; }

    public Post Post { get; set; } = null!;

    public int MentionedUserId { get; set; }

    public User MentionedUser { get; set; } = null!;

    public DateTimeOffset CreatedAtUtc { get; set; }
}

public sealed class Hashtag
{
    public int Id { get; set; }

    public string Tag { get; set; } = string.Empty;

    public string NormalizedTag { get; set; } = string.Empty;
}

public sealed class PostHashtag
{
    public int PostId { get; set; }

    public Post Post { get; set; } = null!;

    public int HashtagId { get; set; }

    public Hashtag Hashtag { get; set; } = null!;
}