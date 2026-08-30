namespace Pulse.Api.Domain;

public enum NotificationType
{
    Like = 0,
    Reply = 1,
    Follow = 2,
    Mention = 3
}

public sealed class Notification
{
    public int Id { get; set; }

    public int RecipientUserId { get; set; }

    public User RecipientUser { get; set; } = null!;

    public int ActorUserId { get; set; }

    public User ActorUser { get; set; } = null!;

    public NotificationType Type { get; set; }

    public int? PostId { get; set; }

    public Post? Post { get; set; }

    public string SourceKey { get; set; } = string.Empty;

    public bool IsRead { get; set; }

    public DateTimeOffset CreatedAtUtc { get; set; }
}