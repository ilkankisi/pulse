using Microsoft.EntityFrameworkCore;

using Pulse.Api.Domain;

namespace Pulse.Api.Data;

public sealed class PulseDbContext : DbContext
{
    public PulseDbContext(DbContextOptions<PulseDbContext> options)
        : base(options)
    {
    }

    public DbSet<User> Users => Set<User>();
    public DbSet<User> User => Set<User>();
    public DbSet<Post> Posts => Set<Post>();
    public DbSet<PostLike> PostLikes => Set<PostLike>();
    public DbSet<Follow> Follows => Set<Follow>();
    public DbSet<Block> Blocks => Set<Block>();
    public DbSet<Report> Reports => Set<Report>();
    public DbSet<ApiDescription> ApiDescription => Set<ApiDescription>();
    public DbSet<ModerationActionRecord> ModerationActions =>
        Set<ModerationActionRecord>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<User>(entity =>
        {
            entity.ToTable("Users");
            entity.HasKey(user => user.Id);

            entity.Property(user => user.Username)
                .IsRequired()
                .HasMaxLength(30);
            entity.Property(user => user.NormalizedUsername)
                .IsRequired()
                .HasMaxLength(30);
            entity.Property(user => user.Email)
                .IsRequired()
                .HasMaxLength(254);
            entity.Property(user => user.NormalizedEmail)
                .IsRequired()
                .HasMaxLength(254);
            entity.Property(user => user.DisplayName)
                .IsRequired()
                .HasMaxLength(80);
            entity.Property(user => user.Bio)
                .HasMaxLength(160);
            entity.Property(user => user.AvatarUrl)
                .HasMaxLength(2048);
            entity.Property(user => user.PasswordHash)
                .IsRequired()
                .HasMaxLength(512);
            entity.Property(user => user.Role)
                .IsRequired()
                .HasMaxLength(32)
                .HasDefaultValue("user");
            entity.Property(user => user.IsActive)
                .IsRequired()
                .HasDefaultValue(true);

            entity.HasIndex(user => user.NormalizedUsername)
                .IsUnique();
            entity.HasIndex(user => user.NormalizedEmail)
                .IsUnique();
            entity.HasIndex(user => new
            {
                user.IsActive,
                user.CreatedAtUtc
            });
        });

        modelBuilder.Entity<Post>(entity =>
        {
            entity.ToTable("Posts");
            entity.HasKey(post => post.Id);

            entity.Property(post => post.Content)
                .IsRequired()
                .HasMaxLength(280);

            entity.HasIndex(post => post.AuthorId);
            entity.HasIndex(post => post.CreatedAtUtc);
            entity.HasIndex(post => post.ParentPostId);

            entity.HasOne(post => post.Author)
                .WithMany(user => user.Posts)
                .HasForeignKey(post => post.AuthorId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(post => post.ParentPost)
                .WithMany(post => post.Replies)
                .HasForeignKey(post => post.ParentPostId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<PostLike>(entity =>
        {
            entity.ToTable("PostLikes");
            entity.HasKey(like => new
            {
                like.PostId,
                like.UserId
            });

            entity.HasIndex(like => like.UserId);

            entity.HasOne(like => like.Post)
                .WithMany(post => post.Likes)
                .HasForeignKey(like => like.PostId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(like => like.User)
                .WithMany(user => user.PostLikes)
                .HasForeignKey(like => like.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<Follow>(entity =>
        {
            entity.ToTable("Follows");
            entity.HasKey(follow => new
            {
                follow.FollowerId,
                follow.FollowingId
            });

            entity.HasIndex(follow => follow.FollowingId);

            entity.HasOne(follow => follow.Follower)
                .WithMany(user => user.Following)
                .HasForeignKey(follow => follow.FollowerId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(follow => follow.FollowingUser)
                .WithMany(user => user.Followers)
                .HasForeignKey(follow => follow.FollowingId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<Block>(entity =>
        {
            entity.ToTable("Blocks");
            entity.HasKey(block => block.Id);

            entity.HasOne(block => block.Blocker)
                .WithMany(user => user.BlocksCreated)
                .HasForeignKey(block => block.BlockerId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(block => block.BlockedUser)
                .WithMany(user => user.BlocksReceived)
                .HasForeignKey(block => block.BlockedUserId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasIndex(block => new
            {
                block.BlockerId,
                block.BlockedUserId
            }).IsUnique();

            entity.HasIndex(block => block.BlockedUserId);
        });

        modelBuilder.Entity<Report>(entity =>
        {
            entity.ToTable("Reports");
            entity.HasKey(report => report.Id);

            entity.Property(report => report.TargetType)
                .HasConversion<string>()
                .HasMaxLength(16)
                .IsRequired();

            entity.Property(report => report.Reason)
                .HasConversion<string>()
                .HasMaxLength(32)
                .IsRequired();

            entity.Property(report => report.Details)
                .HasMaxLength(500);

            entity.Property(report => report.Status)
                .HasConversion<string>()
                .HasMaxLength(16)
                .HasDefaultValue(ReportStatus.Pending)
                .IsRequired();

            entity.HasOne(report => report.Reporter)
                .WithMany(user => user.ReportsCreated)
                .HasForeignKey(report => report.ReporterId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(report => report.ReviewedByUser)
                .WithMany(user => user.ReportsReviewed)
                .HasForeignKey(report => report.ReviewedByUserId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasIndex(report => new
            {
                report.Status,
                report.CreatedAt
            });

            entity.HasIndex(report => new
            {
                report.ReporterId,
                report.TargetType,
                report.TargetId
            });

            entity.HasIndex(report => new
            {
                report.TargetType,
                report.TargetId
            });
        });

        modelBuilder.Entity<ModerationActionRecord>(entity =>
        {
            entity.ToTable("ModerationActions");
            entity.HasKey(action => action.Id);

            entity.Property(action => action.Action)
                .HasConversion<string>()
                .HasMaxLength(16)
                .IsRequired();

            entity.Property(action => action.Note)
                .HasMaxLength(500);

            entity.HasOne(action => action.Report)
                .WithMany(report => report.ModerationActions)
                .HasForeignKey(action => action.ReportId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(action => action.ModeratorUser)
                .WithMany(user => user.ModerationActions)
                .HasForeignKey(action => action.ModeratorUserId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasIndex(action => action.ReportId);
            entity.HasIndex(action => action.ModeratorUserId);
        });
    }
}