#!/usr/bin/env pwsh
# new-project.ps1 — Scaffold a new youtube-team-os project
# Usage: .\bin\new-project.ps1 -Slug "pricing-mistakes" [-EpNumber 1]
#        .\bin\new-project.ps1 -Slug "test" -StateRoot "C:\fixtures\state"   (for tests)
#
# Creates: <StateRoot|state>/projects/YYYY-MM-ep##-slug/ with all required files
# Updates: <StateRoot|state>/notes/content-calendar.md

param(
    [Parameter(Mandatory=$true)]
    [string]$Slug,

    [Parameter(Mandatory=$false)]
    [int]$EpNumber = 0,

    [Parameter(Mandatory=$false)]
    [string]$TargetDate = "",

    [Parameter(Mandatory=$false)]
    [string]$StateRoot = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Resolve plugin root ───────────────────────────────────────────────────────
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PluginRoot = Split-Path -Parent $ScriptDir

# ── Resolve state root (override for tests, default is real plugin state/) ────
$StateDir = if ($StateRoot -ne "") { $StateRoot } else { "$PluginRoot\state" }
New-Item -ItemType Directory -Path $StateDir -Force | Out-Null

# ── Build project ID ──────────────────────────────────────────────────────────
$YearMonth = Get-Date -Format "yyyy-MM"

if ($EpNumber -eq 0) {
    # Auto-increment: count existing projects this month
    $ExistingProjects = Get-ChildItem "$StateDir\projects" -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like "$YearMonth-*" }
    $EpNumber = $ExistingProjects.Count + 1
}

$EpPadded = $EpNumber.ToString("D2")
$ProjectId = "$YearMonth-ep$EpPadded-$Slug"
$ProjectDir = "$StateDir\projects\$ProjectId"

# ── Check for duplicates ──────────────────────────────────────────────────────
if (Test-Path $ProjectDir) {
    Write-Error "Project already exists: $ProjectId"
    exit 1
}

Write-Host "[yt-os] Creating project: $ProjectId" -ForegroundColor Cyan

# ── Create project directory ──────────────────────────────────────────────────
New-Item -ItemType Directory -Path $ProjectDir | Out-Null

# ── Scaffold files ────────────────────────────────────────────────────────────
$Today = Get-Date -Format "yyyy-MM-dd"
$Now   = Get-Date -Format "yyyy-MM-dd HH:mm"

# status.md
@"
stage: INTAKE
owner: producer
created: $Today
updated: $Today
"@ | Set-Content "$ProjectDir\status.md" -Encoding UTF8

# activity.log
@"
[$Now] Project created by new-project.ps1
[$Now] INTAKE — assigned to producer
"@ | Set-Content "$ProjectDir\activity.log" -Encoding UTF8

# brief.md (stub)
@"
# Brief: $ProjectId

> Fill this using /youtube-team-os:producer or resources/templates/brief-template.md

## Angle


## Hook concept


## Target audience


## Key points

1.
2.
3.

## SEO title options


## Success criteria

- CTR target:
- Retention @2min target:
- View target (30-day):
"@ | Set-Content "$ProjectDir\brief.md" -Encoding UTF8

# Remaining deliverable stubs
$Stubs = @("outline.md", "script.md", "edit-notes.md", "thumbnail-options.md", "publish-plan.md", "postmortem.md")
foreach ($Stub in $Stubs) {
    "# $($Stub -replace '\.md','') — $ProjectId`n`n> Not yet written. Stage: INTAKE" |
        Set-Content "$ProjectDir\$Stub" -Encoding UTF8
}

# ── Update content calendar ───────────────────────────────────────────────────
$CalendarFile = "$StateDir\notes\content-calendar.md"
New-Item -ItemType Directory -Path "$StateDir\notes" -Force | Out-Null

if ($TargetDate -eq "") {
    $TargetDate = (Get-Date).AddDays(14).ToString("yyyy-MM-dd")
}

if (Test-Path $CalendarFile) {
    # Append row to existing table
    $Row = "| $ProjectId | (untitled) | $TargetDate | INTAKE | producer |"
    Add-Content $CalendarFile "`n$Row" -Encoding UTF8
} else {
    @"
# Content Calendar

| Project ID | Title | Target Date | Stage | Owner |
|---|---|---|---|---|
| $ProjectId | (untitled) | $TargetDate | INTAKE | producer |
"@ | Set-Content $CalendarFile -Encoding UTF8
}

# ── Post to producer inbox ────────────────────────────────────────────────────
New-Item -ItemType Directory -Path "$StateDir\roles\producer" -Force | Out-Null
$ProducerInbox = "$StateDir\roles\producer\inbox.md"
if (-not (Test-Path $ProducerInbox)) { New-Item -ItemType File -Path $ProducerInbox | Out-Null }
$InboxEntry = "- [ ] [$ProjectId] Write content brief — state/projects/$ProjectId/brief.md"
Add-Content $ProducerInbox "`n$InboxEntry" -Encoding UTF8

# ── Done ──────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[yt-os] Project scaffolded successfully!" -ForegroundColor Green
Write-Host "  ID:       $ProjectId"                  -ForegroundColor White
Write-Host "  Path:     $ProjectDir"                 -ForegroundColor White
Write-Host "  Stage:    INTAKE → producer"           -ForegroundColor White
Write-Host ""
Write-Host "Next step:"                              -ForegroundColor Yellow
Write-Host "  /youtube-team-os:producer $ProjectId" -ForegroundColor Yellow
