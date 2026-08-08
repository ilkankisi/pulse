namespace Pulse.Api.Domain;

public sealed class User
{
    public int Id { get; set; }

    public string Username { get; set; } = string.Empty;

    public string NormalizedUsername { get; set; } = string.Empty;

    public string Email { get; set; } = string.Empty;

    public string NormalizedEmail { get; set; } = string.Empty;

    public string DisplayName { get; set; } = string.Empty;

    public string? Bio { get; set; }

    public string? AvatarUrl { get; set; }

    public string PasswordHash { get; set; } = string.Empty;

    public DateTimeOffset CreatedAtUtc { get; set; }

    public ICollection<Post> Posts { get; set; } = new List<Post>();

    public ICollection<PostLike> PostLikes { get; set; } =
        new List<PostLike>();

    public ICollection<Follow> Followers { get; set; } =
        new List<Follow>();

    public ICollection<Follow> Following { get; set; } =
        new List<Follow>();
}

public sealed class Post
{
    public int Id { get; set; }

    public int AuthorId { get; set; }

    public User Author { get; set; } = null!;

    public string Content { get; set; } = string.Empty;

    public int? ParentPostId { get; set; }

    public Post? ParentPost { get; set; }

    public DateTimeOffset CreatedAtUtc { get; set; }

    public ICollection<Post> Replies { get; set; } =
        new List<Post>();

    public ICollection<PostLike> Likes { get; set; } =
        new List<PostLike>();
}

public sealed class PostLike
{
    public int PostId { get; set; }

    public Post Post { get; set; } = null!;

    public int UserId { get; set; }

    public User User { get; set; } = null!;

    public DateTimeOffset CreatedAtUtc { get; set; }
}

public sealed class Follow
{
    public int FollowerId { get; set; }

    public User Follower { get; set; } = null!;

    public int FollowingId { get; set; }

    public User FollowingUser { get; set; } = null!;

    public DateTimeOffset CreatedAtUtc { get; set; }
}