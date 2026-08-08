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

    protected override void OnModelCreating(
        ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<User>(
            entity =>
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

                entity.HasIndex(user => user.NormalizedUsername)
                    .IsUnique();

                entity.HasIndex(user => user.NormalizedEmail)
                    .IsUnique();
            });

        modelBuilder.Entity<Post>(
            entity =>
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

        modelBuilder.Entity<PostLike>(
            entity =>
            {
                entity.ToTable("PostLikes");

                entity.HasKey(
                    like => new
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

        modelBuilder.Entity<Follow>(
            entity =>
            {
                entity.ToTable("Follows");

                entity.HasKey(
                    follow => new
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
    }
}