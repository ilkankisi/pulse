using Microsoft.EntityFrameworkCore;

using Pulse.Api.Domain;

namespace Pulse.Api.Data;

public sealed class PulseDbContext : DbContext

{

public PulseDbContext(

DbContextOptions<PulseDbContext> options)

: base(options)

{

}

public DbSet<User> Users => Set<User>();

public DbSet<Post> Posts => Set<Post>();

public DbSet<PostLike> PostLikes => Set<PostLike>();

public DbSet<Follow> Follows => Set<Follow>();

public DbSet<Block> Blocks => Set<Block>();

public DbSet<Report> Reports => Set<Report>();

public DbSet<ModerationActionRecord> ModerationActions =>
    Set<ModerationActionRecord>();

protected override void OnModelCreating(
    ModelBuilder modelBuilder)
{
    base.OnModelCreating(modelBuilder);

    var postLike = modelBuilder.Entity<PostLike>();

    postLike.HasKey(
        value => new
        {
            value.PostId,
            value.UserId
        });

    var block = modelBuilder.Entity<Block>();

    block.ToTable("Blocks");

    block.HasKey(value => value.Id);

    block.HasOne(value => value.Blocker)
        .WithMany(user => user.BlocksCreated)
        .HasForeignKey(value => value.BlockerId)
        .OnDelete(DeleteBehavior.Restrict);

    block.HasOne(value => value.BlockedUser)
        .WithMany(user => user.BlocksReceived)
        .HasForeignKey(value => value.BlockedUserId)
        .OnDelete(DeleteBehavior.Restrict);

    block.HasIndex(
            value => new
            {
                value.BlockerId,
                value.BlockedUserId
            })
        .IsUnique();

    block.HasIndex(value => value.BlockedUserId);

    var follow = modelBuilder.Entity<Follow>();

    follow.ToTable("Follows");

    follow.HasKey(
        value => new
        {
            value.FollowerId,
            value.FollowingId
        });

    follow.HasIndex(value => value.FollowingId);

    follow.HasOne(value => value.Follower)
        .WithMany(user => user.Following)
        .HasForeignKey(value => value.FollowerId)
        .OnDelete(DeleteBehavior.Restrict);

    follow.HasOne(value => value.FollowingUser)
        .WithMany(user => user.Followers)
        .HasForeignKey(value => value.FollowingId)
        .OnDelete(DeleteBehavior.Restrict);

    var report = modelBuilder.Entity<Report>();

    report.HasOne(value => value.Reporter)
        .WithMany()
        .HasForeignKey("ReporterId")
        .OnDelete(DeleteBehavior.Restrict);

    report.HasOne(value => value.ReviewedByUser)
        .WithMany()
        .HasForeignKey("ReviewedByUserId")
        .OnDelete(DeleteBehavior.Restrict);
}

}