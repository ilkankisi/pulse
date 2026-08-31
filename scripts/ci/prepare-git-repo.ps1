[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Invoke-Git {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    & git @Arguments

    if ($LASTEXITCODE -ne 0) {
        throw "git $($Arguments -join ' ') failed with exit code $LASTEXITCODE."
    }
}

function Get-GitOutput {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    $output = & git @Arguments

    if ($LASTEXITCODE -ne 0) {
        throw "git $($Arguments -join ' ') failed with exit code $LASTEXITCODE."
    }

    return ($output | Out-String).Trim()
}

# scripts/ci -> scripts -> canonical workspace root
$workspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $workspaceRoot

Write-Host "WORKSPACE=$workspaceRoot"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "Git is not installed or is not available in PATH."
}

$gitDirectory = Join-Path $workspaceRoot ".git"

if (-not (Test-Path $gitDirectory)) {
    Write-Host "GIT_REPOSITORY_INITIALIZED=false"
    Write-Host "Initializing Git repository..."

    Invoke-Git init -b main

    Write-Host "GIT_REPOSITORY_INITIALIZED=true"
}
else {
    Write-Host "GIT_REPOSITORY_INITIALIZED=already-exists"
}

$isInsideWorkTree = Get-GitOutput rev-parse --is-inside-work-tree

if ($isInsideWorkTree -ne "true") {
    throw "Canonical workspace is not a valid Git working tree."
}

$gitTopLevel = Get-GitOutput rev-parse --show-toplevel
$resolvedTopLevel = (Resolve-Path $gitTopLevel).Path

if ($resolvedTopLevel -ne $workspaceRoot) {
    throw @"
Git repository root mismatch.
Expected: $workspaceRoot
Actual:   $resolvedTopLevel
"@
}

Write-Host "GIT_TOP_LEVEL=$resolvedTopLevel"

$branch = (& git branch --show-current | Out-String).Trim()

if ($LASTEXITCODE -ne 0) {
    throw "Unable to determine active Git branch."
}

if ([string]::IsNullOrWhiteSpace($branch)) {
    # Unborn HEAD immediately after git init is expected to point at main.
    $symbolicHead = (& git symbolic-ref --short HEAD | Out-String).Trim()

    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($symbolicHead)) {
        throw "Unable to resolve Git HEAD branch."
    }

    $branch = $symbolicHead
}

Write-Host "ACTIVE_BRANCH=$branch"

# This preparation step intentionally does not stage, commit, configure a
# remote, authenticate to GitHub, or push anything. Those operations belong to
# the explicit publish step.
$stagedFiles = (& git diff --cached --name-only | Out-String).Trim()

if ($LASTEXITCODE -ne 0) {
    throw "Unable to inspect the Git staging area."
}

if ([string]::IsNullOrWhiteSpace($stagedFiles)) {
    Write-Host "STAGING_AREA_EMPTY=true"
}
else {
    Write-Host "STAGING_AREA_EMPTY=false"
    Write-Host "PREEXISTING_STAGED_FILES:"
    Write-Host $stagedFiles
}

Write-Host "GIT_REPOSITORY_READY=true"