[CmdletBinding()]
param(
    [string]$RepositoryName = "CloneTwiter",
    [string]$CommitMessage = "ci: publish project"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Invoke-Native {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    & $FilePath @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed ($LASTEXITCODE): $FilePath $($Arguments -join ' ')"
    }
}

function Get-GitOutput {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    $output = & git @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Arguments -join ' ') failed."
    }

    return ($output | Out-String).Trim()
}

# scripts/ci -> scripts -> workspace
$workspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $workspaceRoot

Write-Host "WORKSPACE=$workspaceRoot"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "git is not installed or not available in PATH."
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw "GitHub CLI (gh) is required for authenticated publish."
}

# 1. GitHub authentication evidence.
Invoke-Native gh auth status

$githubLogin = (& gh api user --jq ".login").Trim()
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($githubLogin)) {
    throw "Authenticated GitHub login could not be resolved."
}

$githubId = (& gh api user --jq ".id").Trim()
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($githubId)) {
    throw "Authenticated GitHub user id could not be resolved."
}

Write-Host "GITHUB_AUTHENTICATED_AS=$githubLogin"

# 2. Ensure canonical workspace is a Git repository.
if (-not (Test-Path (Join-Path $workspaceRoot ".git"))) {
    Invoke-Native git init -b main
}

$gitTopLevel = Get-GitOutput rev-parse --show-toplevel
$resolvedGitTopLevel = (Resolve-Path $gitTopLevel).Path

if ($resolvedGitTopLevel -ne $workspaceRoot) {
    throw "Git repository root mismatch. Expected '$workspaceRoot', got '$resolvedGitTopLevel'."
}

Write-Host "GIT_REPOSITORY_ROOT=$resolvedGitTopLevel"

# Configure repository-local identity only when missing.
$currentName = (& git config --local user.name 2>$null | Out-String).Trim()
if ([string]::IsNullOrWhiteSpace($currentName)) {
    Invoke-Native git config --local user.name $githubLogin
}

$currentEmail = (& git config --local user.email 2>$null | Out-String).Trim()
if ([string]::IsNullOrWhiteSpace($currentEmail)) {
    Invoke-Native git config --local user.email "$githubId+$githubLogin@users.noreply.github.com"
}

# 3. Resolve/create GitHub repository and origin.
$repositoryFullName = "$githubLogin/$RepositoryName"
$origin = (& git remote get-url origin 2>$null | Out-String).Trim()

if ([string]::IsNullOrWhiteSpace($origin)) {
    & gh repo view $repositoryFullName --json nameWithOwner *> $null

    if ($LASTEXITCODE -eq 0) {
        $origin = "https://github.com/$repositoryFullName.git"
        Invoke-Native git remote add origin $origin
    }
    else {
        Invoke-Native gh repo create $repositoryFullName `
            --private `
            --source $workspaceRoot `
            --remote origin

        $origin = Get-GitOutput remote get-url origin
    }
}

if ($origin -notmatch "^https://github\.com/" -and
    $origin -notmatch "^git@github\.com:") {
    throw "origin is not a GitHub remote: $origin"
}

Write-Host "GITHUB_REMOTE=$origin"

# Confirm the resolved origin is accessible with the authenticated account.
Invoke-Native gh repo view $repositoryFullName --json nameWithOwner,url,defaultBranchRef

# 4. Prevent unrelated files from entering the publish commit.
#
# These paths represent the complete project workspace produced by the
# orchestrator. Anything outside this list is treated as unrelated and blocks
# publishing instead of being silently staged.
$allowedTopLevelPaths = @(
    ".github",
    "backend",
    "mobile",
    "docs",
    "design",
    "infra",
    "scripts",
    "docker-compose.yml",
    "docker-compose.ci.yml",
    "Dockerfile",
    ".gitignore",
    ".gitattributes",
    ".editorconfig",
    "README.md",
    "LICENSE",
    "LICENSE.md",
    "global.json",
    "Directory.Build.props",
    "Directory.Build.targets"
)

$statusPaths = @(
    & git status --porcelain=v1 --untracked-files=all |
        ForEach-Object {
            if ($_ -match "^..\s+(.+)$") {
                $path = $Matches[1].Trim()

                # Handle porcelain rename representation: old -> new
                if ($path -match " -> (.+)$") {
                    $path = $Matches[1]
                }

                $path.Trim('"').Replace("\", "/")
            }
        }
)

if ($LASTEXITCODE -ne 0) {
    throw "Unable to inspect Git working tree."
}

$unrelatedPaths = @()

foreach ($path in $statusPaths) {
    if ([string]::IsNullOrWhiteSpace($path)) {
        continue
    }

    $topLevel = ($path -split "/")[0]

    if ($allowedTopLevelPaths -notcontains $topLevel) {
        $unrelatedPaths += $path
    }
}

if ($unrelatedPaths.Count -gt 0) {
    Write-Host "UNRELATED_FILES_DETECTED:"
    $unrelatedPaths | ForEach-Object { Write-Host "  $_" }

    throw "Publish stopped because unrelated workspace files were detected."
}

# Clear any pre-existing staging selection, then stage only the verified project
# working tree. At this point every changed/untracked path has passed the
# allow-list check above.
Invoke-Native git reset

Invoke-Native git add -A -- .

$stagedPaths = @(
    & git diff --cached --name-only |
        ForEach-Object { $_.Trim().Replace("\", "/") } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
)

if ($LASTEXITCODE -ne 0) {
    throw "Unable to inspect staged files."
}

if ($stagedPaths.Count -eq 0) {
    throw "No project changes are staged; refusing to create an empty publish commit."
}

$invalidStagedPaths = @()

foreach ($path in $stagedPaths) {
    $topLevel = ($path -split "/")[0]

    if ($allowedTopLevelPaths -notcontains $topLevel) {
        $invalidStagedPaths += $path
    }
}

if ($invalidStagedPaths.Count -gt 0) {
    Invoke-Native git reset

    Write-Host "INVALID_STAGED_FILES:"
    $invalidStagedPaths | ForEach-Object { Write-Host "  $_" }

    throw "Stage verification failed; nothing was published."
}

Write-Host "STAGED_FILES:"
$stagedPaths | ForEach-Object { Write-Host "  $_" }

# 5. Create commit.
Invoke-Native git commit -m $CommitMessage

$commitSha = Get-GitOutput rev-parse HEAD
Write-Host "COMMIT_SHA=$commitSha"

# 6. Resolve active branch and push it to origin.
$branch = Get-GitOutput branch --show-current

if ([string]::IsNullOrWhiteSpace($branch)) {
    throw "Active Git branch could not be resolved."
}

Write-Host "ACTIVE_BRANCH=$branch"

Invoke-Native git push -u origin $branch

# 7. Prove remote branch now points to the created commit.
$remoteRef = (& git ls-remote origin "refs/heads/$branch" | Out-String).Trim()

if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($remoteRef)) {
    throw "Remote branch verification failed after push."
}

$remoteSha = ($remoteRef -split "\s+")[0]

if ($remoteSha -ne $commitSha) {
    throw "Push verification mismatch. Local=$commitSha Remote=$remoteSha"
}

Write-Host "REMOTE_COMMIT_SHA=$remoteSha"
Write-Host "PUSH_VERIFIED=true"

# 8. Final unrelated/working-tree verification.
$remainingStatus = (& git status --porcelain=v1 --untracked-files=all | Out-String).Trim()

if ($LASTEXITCODE -ne 0) {
    throw "Final git status verification failed."
}

if (-not [string]::IsNullOrWhiteSpace($remainingStatus)) {
    Write-Host "REMAINING_WORKTREE_CHANGES:"
    Write-Host $remainingStatus
    throw "Working tree is not clean after publish."
}

Write-Host "UNRELATED_FILES_PUBLISHED=false"
Write-Host "WORKTREE_CLEAN=true"
Write-Host "PUBLISH_COMPLETED=true"