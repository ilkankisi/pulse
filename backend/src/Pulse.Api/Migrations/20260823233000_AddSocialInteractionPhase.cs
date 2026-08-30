using System;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;
using Pulse.Api.Data;

#nullable disable

namespace Pulse.Api.Migrations;

[DbContext(typeof(PulseDbContext))]
[Migration("20260823233000_AddSocialInteractionPhase")]
public sealed class AddSocialInteractionPhase : Migration
{
    protected override void Up(
        MigrationBuilder migrationBuilder)
    {
        migrationBuilder.AddColumn<string>(
            name: "Kind",
            table: "Posts",
            type: "character varying(16)",
            maxLength: 16,
            nullable: false,
            defaultValue: "Post");

        migrationBuilder.AddColumn<int>(
            name: "OriginalPostId",
            table: "Posts",
            type: "integer",
            nullable: true);

        migrationBuilder.CreateTable(
            name: "Hashtags",
            columns: table => new
            {
                Id = table.Column<int>(
                        type: "integer",
                        nullable: false)
                    .Annotation(
                        "Npgsql:ValueGenerationStrategy",
                        NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                Tag = table.Column<string>(
                    type: "character varying(64)",
                    maxLength: 64,
                    nullable: false),
                NormalizedTag = table.Column<string>(
                    type: "character varying(64)",
                    maxLength: 64,
                    nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey(
                    "PK_Hashtags",
                    x => x.Id);
            });

        migrationBuilder.CreateTable(
            name: "Bookmarks",
            columns: table => new
            {
                UserId = table.Column<int>(
                    type: "integer",
                    nullable: false),
                PostId = table.Column<int>(
                    type: "integer",
                    nullable: false),
                CreatedAtUtc = table.Column<DateTimeOffset>(
                    type: "timestamp with time zone",
                    nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey(
                    "PK_Bookmarks",
                    x => new
                    {
                        x.UserId,
                        x.PostId
                    });

                table.ForeignKey(
                    name: "FK_Bookmarks_Posts_PostId",
                    column: x => x.PostId,
                    principalTable: "Posts",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Cascade);

                table.ForeignKey(
                    name: "FK_Bookmarks_Users_UserId",
                    column: x => x.UserId,
                    principalTable: "Users",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Cascade);
            });

        migrationBuilder.CreateTable(
            name: "Notifications",
            columns: table => new
            {
                Id = table.Column<int>(
                        type: "integer",
                        nullable: false)
                    .Annotation(
                        "Npgsql:ValueGenerationStrategy",
                        NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                RecipientUserId = table.Column<int>(
                    type: "integer",
                    nullable: false),
                ActorUserId = table.Column<int>(
                    type: "integer",
                    nullable: false),
                Type = table.Column<string>(
                    type: "character varying(16)",
                    maxLength: 16,
                    nullable: false),
                PostId = table.Column<int>(
                    type: "integer",
                    nullable: true),
                SourceKey = table.Column<string>(
                    type: "character varying(160)",
                    maxLength: 160,
                    nullable: false),
                IsRead = table.Column<bool>(
                    type: "boolean",
                    nullable: false),
                CreatedAtUtc = table.Column<DateTimeOffset>(
                    type: "timestamp with time zone",
                    nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey(
                    "PK_Notifications",
                    x => x.Id);

                table.ForeignKey(
                    name: "FK_Notifications_Posts_PostId",
                    column: x => x.PostId,
                    principalTable: "Posts",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Cascade);

                table.ForeignKey(
                    name: "FK_Notifications_Users_ActorUserId",
                    column: x => x.ActorUserId,
                    principalTable: "Users",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Cascade);

                table.ForeignKey(
                    name: "FK_Notifications_Users_RecipientUserId",
                    column: x => x.RecipientUserId,
                    principalTable: "Users",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Cascade);
            });

        migrationBuilder.CreateTable(
            name: "PostMentions",
            columns: table => new
            {
                PostId = table.Column<int>(
                    type: "integer",
                    nullable: false),
                MentionedUserId = table.Column<int>(
                    type: "integer",
                    nullable: false),
                CreatedAtUtc = table.Column<DateTimeOffset>(
                    type: "timestamp with time zone",
                    nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey(
                    "PK_PostMentions",
                    x => new
                    {
                        x.PostId,
                        x.MentionedUserId
                    });

                table.ForeignKey(
                    name: "FK_PostMentions_Posts_PostId",
                    column: x => x.PostId,
                    principalTable: "Posts",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Cascade);

                table.ForeignKey(
                    name: "FK_PostMentions_Users_MentionedUserId",
                    column: x => x.MentionedUserId,
                    principalTable: "Users",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Cascade);
            });

        migrationBuilder.CreateTable(
            name: "Media",
            columns: table => new
            {
                Id = table.Column<int>(
                        type: "integer",
                        nullable: false)
                    .Annotation(
                        "Npgsql:ValueGenerationStrategy",
                        NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                OwnerUserId = table.Column<int>(
                    type: "integer",
                    nullable: false),
                PostId = table.Column<int>(
                    type: "integer",
                    nullable: true),
                ObjectKey = table.Column<string>(
                    type: "character varying(512)",
                    maxLength: 512,
                    nullable: false),
                Url = table.Column<string>(
                    type: "character varying(2048)",
                    maxLength: 2048,
                    nullable: false),
                MediaType = table.Column<string>(
                    type: "character varying(16)",
                    maxLength: 16,
                    nullable: false),
                ContentType = table.Column<string>(
                    type: "character varying(128)",
                    maxLength: 128,
                    nullable: false),
                Width = table.Column<int>(
                    type: "integer",
                    nullable: true),
                Height = table.Column<int>(
                    type: "integer",
                    nullable: true),
                CreatedAtUtc = table.Column<DateTimeOffset>(
                    type: "timestamp with time zone",
                    nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey(
                    "PK_Media",
                    x => x.Id);

                table.ForeignKey(
                    name: "FK_Media_Posts_PostId",
                    column: x => x.PostId,
                    principalTable: "Posts",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Cascade);

                table.ForeignKey(
                    name: "FK_Media_Users_OwnerUserId",
                    column: x => x.OwnerUserId,
                    principalTable: "Users",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Cascade);
            });

        migrationBuilder.CreateTable(
            name: "PostHashtags",
            columns: table => new
            {
                PostId = table.Column<int>(
                    type: "integer",
                    nullable: false),
                HashtagId = table.Column<int>(
                    type: "integer",
                    nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey(
                    "PK_PostHashtags",
                    x => new
                    {
                        x.PostId,
                        x.HashtagId
                    });

                table.ForeignKey(
                    name: "FK_PostHashtags_Hashtags_HashtagId",
                    column: x => x.HashtagId,
                    principalTable: "Hashtags",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Cascade);

                table.ForeignKey(
                    name: "FK_PostHashtags_Posts_PostId",
                    column: x => x.PostId,
                    principalTable: "Posts",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Cascade);
            });

        migrationBuilder.CreateIndex(
            name: "IX_Posts_OriginalPostId",
            table: "Posts",
            column: "OriginalPostId");

        migrationBuilder.CreateIndex(
            name: "IX_Posts_AuthorId_OriginalPostId",
            table: "Posts",
            columns: new[]
            {
                "AuthorId",
                "OriginalPostId"
            },
            unique: true,
            filter:
                "\"Kind\" = 'Repost' AND \"DeletedAt\" IS NULL");

        migrationBuilder.CreateIndex(
            name: "IX_Bookmarks_PostId",
            table: "Bookmarks",
            column: "PostId");

        migrationBuilder.CreateIndex(
            name: "IX_Bookmarks_UserId_CreatedAtUtc",
            table: "Bookmarks",
            columns: new[]
            {
                "UserId",
                "CreatedAtUtc"
            });

        migrationBuilder.CreateIndex(
            name: "IX_Hashtags_NormalizedTag",
            table: "Hashtags",
            column: "NormalizedTag",
            unique: true);

        migrationBuilder.CreateIndex(
            name: "IX_Media_ObjectKey",
            table: "Media",
            column: "ObjectKey",
            unique: true);

        migrationBuilder.CreateIndex(
            name: "IX_Media_OwnerUserId",
            table: "Media",
            column: "OwnerUserId");

        migrationBuilder.CreateIndex(
            name: "IX_Media_PostId",
            table: "Media",
            column: "PostId");

        migrationBuilder.CreateIndex(
            name: "IX_Notifications_ActorUserId",
            table: "Notifications",
            column: "ActorUserId");

        migrationBuilder.CreateIndex(
            name: "IX_Notifications_PostId",
            table: "Notifications",
            column: "PostId");

        migrationBuilder.CreateIndex(
            name: "IX_Notifications_RecipientUserId_CreatedAtUtc",
            table: "Notifications",
            columns: new[]
            {
                "RecipientUserId",
                "CreatedAtUtc"
            });

        migrationBuilder.CreateIndex(
            name: "IX_Notifications_RecipientUserId_Type_SourceKey",
            table: "Notifications",
            columns: new[]
            {
                "RecipientUserId",
                "Type",
                "SourceKey"
            },
            unique: true);

        migrationBuilder.CreateIndex(
            name: "IX_PostHashtags_HashtagId",
            table: "PostHashtags",
            column: "HashtagId");

        migrationBuilder.CreateIndex(
            name: "IX_PostMentions_MentionedUserId",
            table: "PostMentions",
            column: "MentionedUserId");

        migrationBuilder.AddForeignKey(
            name: "FK_Posts_Posts_OriginalPostId",
            table: "Posts",
            column: "OriginalPostId",
            principalTable: "Posts",
            principalColumn: "Id",
            onDelete: ReferentialAction.Restrict);
    }

    protected override void Down(
        MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropForeignKey(
            name: "FK_Posts_Posts_OriginalPostId",
            table: "Posts");

        migrationBuilder.DropTable(
            name: "Bookmarks");

        migrationBuilder.DropTable(
            name: "Media");

        migrationBuilder.DropTable(
            name: "Notifications");

        migrationBuilder.DropTable(
            name: "PostHashtags");

        migrationBuilder.DropTable(
            name: "PostMentions");

        migrationBuilder.DropTable(
            name: "Hashtags");

        migrationBuilder.DropIndex(
            name: "IX_Posts_AuthorId_OriginalPostId",
            table: "Posts");

        migrationBuilder.DropIndex(
            name: "IX_Posts_OriginalPostId",
            table: "Posts");

        migrationBuilder.DropColumn(
            name: "Kind",
            table: "Posts");

        migrationBuilder.DropColumn(
            name: "OriginalPostId",
            table: "Posts");
    }
}