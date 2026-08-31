using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace Pulse.Api.Migrations;

public partial class InitialCreate : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.CreateTable(
            name: "Users",
            columns: table => new
            {
                Id = table.Column<int>(
                        type: "integer",
                        nullable: false)
                    .Annotation(
                        "Npgsql:ValueGenerationStrategy",
                        NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                Username = table.Column<string>(
                    type: "character varying(30)",
                    maxLength: 30,
                    nullable: false),
                NormalizedUsername = table.Column<string>(
                    type: "character varying(30)",
                    maxLength: 30,
                    nullable: false),
                Email = table.Column<string>(
                    type: "character varying(254)",
                    maxLength: 254,
                    nullable: false),
                NormalizedEmail = table.Column<string>(
                    type: "character varying(254)",
                    maxLength: 254,
                    nullable: false),
                DisplayName = table.Column<string>(
                    type: "character varying(80)",
                    maxLength: 80,
                    nullable: false),
                Bio = table.Column<string>(
                    type: "character varying(160)",
                    maxLength: 160,
                    nullable: true),
                AvatarUrl = table.Column<string>(
                    type: "character varying(2048)",
                    maxLength: 2048,
                    nullable: true),
                PasswordHash = table.Column<string>(
                    type: "character varying(512)",
                    maxLength: 512,
                    nullable: false),
                CreatedAtUtc = table.Column<DateTimeOffset>(
                    type: "timestamp with time zone",
                    nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey(
                    "PK_Users",
                    x => x.Id);
            });

        migrationBuilder.CreateTable(
            name: "Follows",
            columns: table => new
            {
                FollowerId = table.Column<int>(
                    type: "integer",
                    nullable: false),
                FollowingId = table.Column<int>(
                    type: "integer",
                    nullable: false),
                CreatedAtUtc = table.Column<DateTimeOffset>(
                    type: "timestamp with time zone",
                    nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey(
                    "PK_Follows",
                    x => new
                    {
                        x.FollowerId,
                        x.FollowingId
                    });

                table.ForeignKey(
                    name: "FK_Follows_Users_FollowerId",
                    column: x => x.FollowerId,
                    principalTable: "Users",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Restrict);

                table.ForeignKey(
                    name: "FK_Follows_Users_FollowingId",
                    column: x => x.FollowingId,
                    principalTable: "Users",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Restrict);
            });

        migrationBuilder.CreateTable(
            name: "Posts",
            columns: table => new
            {
                Id = table.Column<int>(
                        type: "integer",
                        nullable: false)
                    .Annotation(
                        "Npgsql:ValueGenerationStrategy",
                        NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                AuthorId = table.Column<int>(
                    type: "integer",
                    nullable: false),
                Content = table.Column<string>(
                    type: "character varying(280)",
                    maxLength: 280,
                    nullable: false),
                ParentPostId = table.Column<int>(
                    type: "integer",
                    nullable: true),
                CreatedAtUtc = table.Column<DateTimeOffset>(
                    type: "timestamp with time zone",
                    nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey(
                    "PK_Posts",
                    x => x.Id);

                table.ForeignKey(
                    name: "FK_Posts_Posts_ParentPostId",
                    column: x => x.ParentPostId,
                    principalTable: "Posts",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Restrict);

                table.ForeignKey(
                    name: "FK_Posts_Users_AuthorId",
                    column: x => x.AuthorId,
                    principalTable: "Users",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Cascade);
            });

        migrationBuilder.CreateTable(
            name: "PostLikes",
            columns: table => new
            {
                PostId = table.Column<int>(
                    type: "integer",
                    nullable: false),
                UserId = table.Column<int>(
                    type: "integer",
                    nullable: false),
                CreatedAtUtc = table.Column<DateTimeOffset>(
                    type: "timestamp with time zone",
                    nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey(
                    "PK_PostLikes",
                    x => new
                    {
                        x.PostId,
                        x.UserId
                    });

                table.ForeignKey(
                    name: "FK_PostLikes_Posts_PostId",
                    column: x => x.PostId,
                    principalTable: "Posts",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Cascade);

                table.ForeignKey(
                    name: "FK_PostLikes_Users_UserId",
                    column: x => x.UserId,
                    principalTable: "Users",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Cascade);
            });
        migrationBuilder.CreateIndex(
            name: "IX_Follows_FollowingId",
            table: "Follows",
            column: "FollowingId");

        migrationBuilder.CreateIndex(
            name: "IX_PostLikes_UserId",
            table: "PostLikes",
            column: "UserId");

        migrationBuilder.CreateIndex(
            name: "IX_Posts_AuthorId",
            table: "Posts",
            column: "AuthorId");

        migrationBuilder.CreateIndex(
            name: "IX_Posts_CreatedAtUtc",
            table: "Posts",
            column: "CreatedAtUtc");

        migrationBuilder.CreateIndex(
            name: "IX_Posts_ParentPostId",
            table: "Posts",
            column: "ParentPostId");

        migrationBuilder.CreateIndex(
            name: "IX_Users_NormalizedEmail",
            table: "Users",
            column: "NormalizedEmail",
            unique: true);

        migrationBuilder.CreateIndex(
            name: "IX_Users_NormalizedUsername",
            table: "Users",
            column: "NormalizedUsername",
            unique: true);
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropTable(
            name: "Follows");

        migrationBuilder.DropTable(
            name: "PostLikes");

        migrationBuilder.DropTable(
            name: "Posts");

        migrationBuilder.DropTable(
            name: "Users");
    }
}