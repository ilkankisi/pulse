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

    public string Role { get; set; } = "user";

    public bool IsActive { get; set; } = true;

    public DateTimeOffset CreatedAtUtc { get; set; }

    public ICollection<Post> Posts { get; set; } =
        new List<Post>();

    public ICollection<PostLike> PostLikes { get; set; } =
        new List<PostLike>();

    public ICollection<Follow> Followers { get; set; } =
        new List<Follow>();

    public ICollection<Follow> Following { get; set; } =
        new List<Follow>();

    public ICollection<Block> BlocksCreated { get; set; } =
        new List<Block>();

    public ICollection<Block> BlocksReceived { get; set; } =
        new List<Block>();

    public ICollection<Report> ReportsCreated { get; set; } =
        new List<Report>();

    public ICollection<Report> ReportsReviewed { get; set; } =
        new List<Report>();

    public ICollection<ModerationActionRecord> ModerationActions { get; set; } =
        new List<ModerationActionRecord>();
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

    public DateTime? DeletedAt { get; set; }

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

public sealed class Block
{
    public int Id { get; set; }

    public int BlockerId { get; set; }

    public User Blocker { get; set; } = null!;

    public int BlockedUserId { get; set; }

    public User BlockedUser { get; set; } = null!;

    public DateTime CreatedAt { get; set; }
}

public sealed class Report
{
    public int Id { get; set; }

    public int ReporterId { get; set; }

    public User Reporter { get; set; } = null!;

    public ReportTargetType TargetType { get; set; }

    public int TargetId { get; set; }

    public ReportReason Reason { get; set; }

    public string? Details { get; set; }

    public ReportStatus Status { get; set; } =
        ReportStatus.Pending;

    public int? ReviewedByUserId { get; set; }

    public User? ReviewedByUser { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? ReviewedAt { get; set; }

    public ICollection<ModerationActionRecord> ModerationActions { get; set; } =
        new List<ModerationActionRecord>();
}

public sealed class ModerationActionRecord
{
    public int Id { get; set; }

    public int ReportId { get; set; }

    public Report Report { get; set; } = null!;

    public int ModeratorUserId { get; set; }

    public User ModeratorUser { get; set; } = null!;

    public ModerationAction Action { get; set; }

    public string? Note { get; set; }

    public DateTime CreatedAt { get; set; }
}