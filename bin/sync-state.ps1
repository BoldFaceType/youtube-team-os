#!/usr/bin/env pwsh
# sync-state.ps1 — Sync state/ deliverables to Google Drive via rclone
# Usage: .\bin\sync-state.ps1 [-ProjectId "2026-07-ep01-pricing"] [-DryRun]
#
# Prerequisites:
#   1. rclone installed: winget install Rclone.Rclone
#   2. rclone configured with Google Drive remote named "gdrive"
#      Run: rclone config  (add a remote, choose Google Drive, name it "gdrive")
#   3. Set $env:YT_OS_DRIVE_ROOT to your Drive folder (default: "YouTube Team OS")

param(
    [string]$ProjectId = "",
    [switch]$DryRun,
    [string]$DriveRoot = $env:YT_OS_DRIVE_ROOT ?? "YouTube Team OS"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$PluginRoot = Split-Path -Parent $ScriptDir
$StateDir   = "$PluginRoot\state"

# ── Check rclone ──────────────────────────────────────────────────────────────
if (-not (Get-Command rclone -ErrorAction SilentlyContinue)) {
    Write-Error @"
rclone not found. Install it first:
  winget install Rclone.Rclone

Then configure Google Drive:
  rclone config
  (Add remote named 'gdrive', type: drive)
"@
    exit 1
}

# ── Build sync args ───────────────────────────────────────────────────────────
$RcloneArgs = @(
    "sync",
    "--progress",
    "--exclude", "*.log",          # skip session/write logs
    "--exclude", "current.md",     # skip ephemeral current-task files
    "--exclude", ".gitkeep"
)

if ($DryRun) {
    $RcloneArgs += "--dry-run"
    Write-Host "[yt-os] DRY RUN — no files will be transferred" -ForegroundColor Yellow
}

# ── Sync scope ────────────────────────────────────────────────────────────────
if ($ProjectId -ne "") {
    # Single project
    $LocalPath  = "$StateDir\projects\$ProjectId"
    $RemotePath = "gdrive:$DriveRoot/projects/$ProjectId"

    if (-not (Test-Path $LocalPath)) {
        Write-Error "Project not found: $LocalPath"
        exit 1
    }

    Write-Host "[yt-os] Syncing project: $ProjectId" -ForegroundColor Cyan
    Write-Host "  Local:  $LocalPath"
    Write-Host "  Remote: $RemotePath"
    Write-Host ""

    rclone @RcloneArgs $LocalPath $RemotePath

} else {
    # All projects (exclude records/ and roles/ ephemeral state)
    $LocalPath  = "$StateDir\projects"
    $RemotePath = "gdrive:$DriveRoot/projects"

    Write-Host "[yt-os] Syncing all projects to Drive" -ForegroundColor Cyan
    Write-Host "  Local:  $LocalPath"
    Write-Host "  Remote: $RemotePath"
    Write-Host ""

    rclone @RcloneArgs $LocalPath $RemotePath

    # Also sync notes
    $NotesLocal  = "$StateDir\notes"
    $NotesRemote = "gdrive:$DriveRoot/notes"
    Write-Host "[yt-os] Syncing notes/" -ForegroundColor Cyan
    rclone @RcloneArgs $NotesLocal $NotesRemote
}

Write-Host ""
Write-Host "[yt-os] Sync complete." -ForegroundColor Green
if (-not $DryRun) {
    Write-Host "  View on Drive: https://drive.google.com/drive/search?q=$DriveRoot" -ForegroundColor White
}
