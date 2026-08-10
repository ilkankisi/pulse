using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace Pulse.Api.Migrations;

public partial class AddSecurityModeration : Migration
{
    protected override void Up(
        MigrationBuilder migrationBuilder)
    {
        migrationBuilder.AddColumn<bool>(
            name: "IsActive",
            table: "Users",
            type: "boolean",
            nullable: false,
            defaultValue: true);

        migrationBuilder.AddColumn<string>(
            name: "Role",
            table: "Users",
            type: "character varying(32)",
            maxLength: 32,
            nullable: false,
            defaultValue: "user");

        migrationBuilder.AddColumn<DateTime>(
            name: "DeletedAt",
            table: "Posts",
            type: "timestamp with time zone",
            nullable: true);

        migrationBuilder.CreateTable(
            name: "Blocks",
            columns: table => new
            {
                Id = table.Column<int>(
                        type: "integer",
                        nullable: false)
                    .Annotation(
                        "Npgsql:ValueGenerationStrategy",
                        NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                BlockerId = table.Column<int>(
                    type: "integer",
                    nullable: false),
                BlockedUserId = table.Column<int>(
                    type: "integer",
                    nullable: false),
                CreatedAt = table.Column<DateTime>(
                    type: "timestamp with time zone",
                    nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey(
                    "PK_Blocks",
                    x => x.Id);

                table.ForeignKey(
                    name: "FK_Blocks_Users_BlockedUserId",
                    column: x => x.BlockedUserId,
                    principalTable: "Users",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Restrict);

                table.ForeignKey(
                    name: "FK_Blocks_Users_BlockerId",
                    column: x => x.BlockerId,
                    principalTable: "Users",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Restrict);
            });

        migrationBuilder.CreateTable(
            name: "Reports",
            columns: table => new
            {
                Id = table.Column<int>(
                        type: "integer",
                        nullable: false)
                    .Annotation(
                        "Npgsql:ValueGenerationStrategy",
                        NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                ReporterId = table.Column<int>(
                    type: "integer",
                    nullable: false),
                TargetType = table.Column<string>(
                    type: "character varying(16)",
                    maxLength: 16,
                    nullable: false),
                TargetId = table.Column<int>(
                    type: "integer",
                    nullable: false),
                Reason = table.Column<string>(
                    type: "character varying(32)",
                    maxLength: 32,
                    nullable: false),
                Details = table.Column<string>(
                    type: "character varying(500)",
                    maxLength: 500,
                    nullable: true),
                Status = table.Column<string>(
                    type: "character varying(16)",
                    maxLength: 16,
                    nullable: false,
                    defaultValue: "Pending"),
                ReviewedByUserId = table.Column<int>(
                    type: "integer",
                    nullable: true),
                CreatedAt = table.Column<DateTime>(
                    type: "timestamp with time zone",
                    nullable: false),
                ReviewedAt = table.Column<DateTime>(
                    type: "timestamp with time zone",
                    nullable: true)
            },
            constraints: table =>
            {
                table.PrimaryKey(
                    "PK_Reports",
                    x => x.Id);

                table.ForeignKey(
                    name: "FK_Reports_Users_ReporterId",
                    column: x => x.ReporterId,
                    principalTable: "Users",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Restrict);

                table.ForeignKey(
                    name: "FK_Reports_Users_ReviewedByUserId",
                    column: x => x.ReviewedByUserId,
                    principalTable: "Users",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Restrict);
            });

        migrationBuilder.CreateTable(
            name: "ModerationActions",
            columns: table => new
            {
                Id = table.Column<int>(
                        type: "integer",
                        nullable: false)
                    .Annotation(
                        "Npgsql:ValueGenerationStrategy",
                        NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                ReportId = table.Column<int>(
                    type: "integer",
                    nullable: false),
                ModeratorUserId = table.Column<int>(
                    type: "integer",
                    nullable: false),
                Action = table.Column<string>(
                    type: "character varying(16)",
                    maxLength: 16,
                    nullable: false),
                Note = table.Column<string>(
                    type: "character varying(500)",
                    maxLength: 500,
                    nullable: true),
                CreatedAt = table.Column<DateTime>(
                    type: "timestamp with time zone",
                    nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey(
                    "PK_ModerationActions",
                    x => x.Id);

                table.ForeignKey(
                    name: "FK_ModerationActions_Reports_ReportId",
                    column: x => x.ReportId,
                    principalTable: "Reports",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Cascade);

                table.ForeignKey(
                    name: "FK_ModerationActions_Users_ModeratorUserId",
                    column: x => x.ModeratorUserId,
                    principalTable: "Users",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Restrict);
            });
        migrationBuilder.CreateIndex(
            name: "IX_Blocks_BlockedUserId",
            table: "Blocks",
            column: "BlockedUserId");

        migrationBuilder.CreateIndex(
            name: "IX_Blocks_BlockerId_BlockedUserId",
            table: "Blocks",
            columns: new[]
            {
                "BlockerId",
                "BlockedUserId"
            },
            unique: true);

        migrationBuilder.CreateIndex(
            name: "IX_ModerationActions_ModeratorUserId",
            table: "ModerationActions",
            column: "ModeratorUserId");

        migrationBuilder.CreateIndex(
            name: "IX_ModerationActions_ReportId",
            table: "ModerationActions",
            column: "ReportId");

        migrationBuilder.CreateIndex(
            name: "IX_Reports_ReporterId_TargetType_TargetId",
            table: "Reports",
            columns: new[]
            {
                "ReporterId",
                "TargetType",
                "TargetId"
            });

        migrationBuilder.CreateIndex(
            name: "IX_Reports_ReviewedByUserId",
            table: "Reports",
            column: "ReviewedByUserId");

        migrationBuilder.CreateIndex(
            name: "IX_Reports_Status_CreatedAt",
            table: "Reports",
            columns: new[]
            {
                "Status",
                "CreatedAt"
            });

        migrationBuilder.CreateIndex(
            name: "IX_Reports_TargetType_TargetId",
            table: "Reports",
            columns: new[]
            {
                "TargetType",
                "TargetId"
            });

        migrationBuilder.CreateIndex(
            name: "IX_Users_IsActive_CreatedAtUtc",
            table: "Users",
            columns: new[]
            {
                "IsActive",
                "CreatedAtUtc"
            });
    }

    protected override void Down(
        MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropTable(
            name: "Blocks");

        migrationBuilder.DropTable(
            name: "ModerationActions");

        migrationBuilder.DropTable(
            name: "Reports");

        migrationBuilder.DropIndex(
            name: "IX_Users_IsActive_CreatedAtUtc",
            table: "Users");

        migrationBuilder.DropColumn(
            name: "DeletedAt",
            table: "Posts");

        migrationBuilder.DropColumn(
            name: "IsActive",
            table: "Users");

        migrationBuilder.DropColumn(
            name: "Role",
            table: "Users");
    }
}