#!/usr/bin/env pwsh
# validate.ps1 — Run plugin validation and state health checks
# Usage: .\bin\validate.ps1 [-Verbose]

param(
    [switch]$Verbose
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$PluginRoot = Split-Path -Parent $ScriptDir

$Errors   = @()
$Warnings = @()
$Passes   = @()

function Check($Label, $Condition, $Message, [switch]$Warn) {
    if ($Condition) {
        $script:Passes += $Label
        if ($Verbose) { Write-Host "  ✓ $Label" -ForegroundColor Green }
    } elseif ($Warn) {
        $script:Warnings += "$Label — $Message"
        Write-Host "  ⚠ $Label — $Message" -ForegroundColor Yellow
    } else {
        $script:Errors += "$Label — $Message"
        Write-Host "  ✗ $Label — $Message" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host " youtube-team-os — Plugin Validation"   -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# ── 1. Manifest ───────────────────────────────────────────────────────────────
Write-Host "── Manifest ──────────────────────────" -ForegroundColor White

$ManifestPath = "$PluginRoot\.claude-plugin\plugin.json"
Check "plugin.json exists"    (Test-Path $ManifestPath)    "Missing .claude-plugin/plugin.json"

if (Test-Path $ManifestPath) {
    try {
        $Manifest = Get-Content $ManifestPath | ConvertFrom-Json
        Check "manifest.name"    ($null -ne $Manifest.name)    "Missing 'name' field"
        Check "manifest.version" ($null -ne $Manifest.version) "Missing 'version' field"
        Check "manifest.author"  ($null -ne $Manifest.author)  "Missing 'author' field"
    } catch {
        $Errors += "plugin.json — Invalid JSON: $_"
        Write-Host "  ✗ plugin.json — Invalid JSON" -ForegroundColor Red
    }
}

# ── 2. Required files ─────────────────────────────────────────────────────────
Write-Host ""
Write-Host "── Required files ─────────────────────" -ForegroundColor White

$RequiredFiles = @(
    "CLAUDE.md",
    "README.md",
    "CHANGELOG.md",
    "hooks\hooks.json",
    "settings.json",
    "skills\orchestrator\SKILL.md",
    "skills\producer\SKILL.md",
    "skills\writer\SKILL.md",
    "skills\editor\SKILL.md",
    "skills\thumbnail\SKILL.md",
    "skills\growth\SKILL.md",
    "agents\orchestrator.md",
    "agents\producer.md",
    "agents\writer.md",
    "agents\editor.md",
    "agents\thumbnail.md",
    "agents\growth.md"
)

foreach ($File in $RequiredFiles) {
    $FullPath = "$PluginRoot\$File"
    Check $File (Test-Path $FullPath) "File missing"
}

# ── 3. .mcp.json validation ───────────────────────────────────────────────────
Write-Host ""
Write-Host "── MCP config ─────────────────────────" -ForegroundColor White

$McpPath = "$PluginRoot\.mcp.json"
if (Test-Path $McpPath) {
    try {
        $Mcp = Get-Content $McpPath | ConvertFrom-Json
        Check ".mcp.json valid JSON" $true ""
        # No servers are expected to be configured right now — see connectors/mcp-setup.md.
        # This just confirms the file parses; it intentionally does not require any server.
    } catch {
        $Errors += ".mcp.json — Invalid JSON"
        Write-Host "  ✗ .mcp.json — Invalid JSON" -ForegroundColor Red
    }
} else {
    Check ".mcp.json exists" $false "Missing .mcp.json (should exist, even with an empty mcpServers object)"
}

# ── 4. Hooks validation ───────────────────────────────────────────────────────
Write-Host ""
Write-Host "── Hooks ──────────────────────────────" -ForegroundColor White

$HooksPath = "$PluginRoot\hooks\hooks.json"
if (Test-Path $HooksPath) {
    try {
        $Hooks = Get-Content $HooksPath | ConvertFrom-Json
        Check "hooks.json valid JSON"       $true ""
        Check "SessionStart hook defined"   ($null -ne $Hooks.hooks.SessionStart)  "Missing SessionStart"
        Check "PostToolUse hook defined"    ($null -ne $Hooks.hooks.PostToolUse)   "Missing PostToolUse"
        Check "SessionEnd hook defined"     ($null -ne $Hooks.hooks.SessionEnd)    "Missing SessionEnd" -Warn

        # Deadline/postmortem reminder logic lives in SessionStart hook commands now
        # (monitors/monitors.json is intentionally empty — see CHANGELOG.md, TM-1).
        $SessionStartCommands = ($Hooks.hooks.SessionStart | ForEach-Object { $_.hooks.command }) -join "`n"
        Check "check-deadlines.js wired into SessionStart" ($SessionStartCommands -like "*check-deadlines.js*") "Deadline reminder hook missing from hooks.json"
        Check "check-postmortem-due.js wired into SessionStart" ($SessionStartCommands -like "*check-postmortem-due.js*") "Postmortem reminder hook missing from hooks.json"
    } catch {
        $Errors += "hooks.json — Invalid JSON"
        Write-Host "  ✗ hooks.json — Invalid JSON" -ForegroundColor Red
    }
}

# ── 4b. Monitor scripts referenced by hooks ───────────────────────────────────
Write-Host ""
Write-Host "── Monitor scripts ────────────────────" -ForegroundColor White

Check "monitors\check-deadlines.js exists"       (Test-Path "$PluginRoot\monitors\check-deadlines.js")       "File missing"
Check "monitors\check-postmortem-due.js exists"  (Test-Path "$PluginRoot\monitors\check-postmortem-due.js")  "File missing"

$MonitorsJsonPath = "$PluginRoot\monitors\monitors.json"
if (Test-Path $MonitorsJsonPath) {
    $MonitorsRaw = Get-Content $MonitorsJsonPath -Raw
    try {
        # Note: `ConvertFrom-Json '[]'` returns $null (a valid empty-array parse), not an
        # empty array object — treat $null as pass here, don't touch .Count on it.
        $MonitorsJson = $MonitorsRaw | ConvertFrom-Json
        Check "monitors.json valid JSON" $true ""
        $IsBareArrayOrEmpty = ($null -eq $MonitorsJson) -or ($MonitorsJson -is [array]) -or ($MonitorsJson -is [System.Collections.IEnumerable] -and $MonitorsJson -isnot [string])
        Check "monitors.json is a bare array" $IsBareArrayOrEmpty "Should be a bare JSON array (possibly empty), not a wrapped object — real logic now lives in hooks.json"
    } catch {
        $Errors += "monitors.json — Invalid JSON: $_"
        Write-Host "  ✗ monitors.json — Invalid JSON" -ForegroundColor Red
    }
}

# ── 5. Required scripts and docs ──────────────────────────────────────────────
Write-Host ""
Write-Host "── Scripts and connector docs ─────────" -ForegroundColor White

$RequiredScripts = @(
    "bin\new-project.ps1", "bin\new-project.sh",
    "bin\validate.ps1", "bin\validate.sh",
    "bin\sync-state.ps1", "bin\sync-state.sh"
)
foreach ($Script in $RequiredScripts) {
    Check $Script (Test-Path "$PluginRoot\$Script") "File missing" -Warn
}

$RequiredConnectorDocs = @(
    "connectors\youtube-metadata.md",
    "connectors\drive.md",
    "connectors\mcp-setup.md"
)
foreach ($Doc in $RequiredConnectorDocs) {
    Check $Doc (Test-Path "$PluginRoot\$Doc") "File missing"
}

# ── 6. Dependencies ────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "── Dependencies ───────────────────────" -ForegroundColor White

$JqAvailable = $null -ne (Get-Command jq -ErrorAction SilentlyContinue)
Check "jq on PATH" $JqAvailable "Write-audit hook requires jq for the file path (falls back to a jq-missing sentinel line otherwise). Install: winget install jqlang.jq" -Warn

$ClaudeAvailable = $null -ne (Get-Command claude -ErrorAction SilentlyContinue)
Check "claude CLI on PATH" $ClaudeAvailable "Install Claude Code: https://claude.ai/code" -Warn

$NodeAvailable = $null -ne (Get-Command node -ErrorAction SilentlyContinue)
Check "Node.js on PATH" $NodeAvailable "bin/ scripts and the two SessionStart reminder hooks require Node.js v18+. Install: https://nodejs.org" -Warn

$RcloneAvailable = $null -ne (Get-Command rclone -ErrorAction SilentlyContinue)
Check "rclone on PATH" $RcloneAvailable "Optional — required only for bin/sync-state.ps1/.sh. Install: winget install Rclone.Rclone" -Warn

# ── 7. State directories ──────────────────────────────────────────────────────
Write-Host ""
Write-Host "── State filesystem ───────────────────" -ForegroundColor White

$StateDirs = @(
    "state\projects",
    "state\roles\producer",
    "state\roles\writer",
    "state\roles\editor",
    "state\roles\thumbnail",
    "state\roles\growth",
    "state\notes",
    "state\records"
)

foreach ($Dir in $StateDirs) {
    Check $Dir (Test-Path "$PluginRoot\$Dir") "Directory missing — run: mkdir state\..."
}

# ── Summary ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host " Results" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Passed:   $($Passes.Count)" -ForegroundColor Green
Write-Host "  Warnings: $($Warnings.Count)" -ForegroundColor Yellow
Write-Host "  Errors:   $($Errors.Count)" -ForegroundColor $(if ($Errors.Count -gt 0) { "Red" } else { "Green" })
Write-Host ""

if ($Errors.Count -gt 0) {
    Write-Host "Errors to fix:" -ForegroundColor Red
    $Errors | ForEach-Object { Write-Host "  • $_" -ForegroundColor Red }
    Write-Host ""
    exit 1
} else {
    Write-Host "Plugin is valid and ready to use." -ForegroundColor Green
    Write-Host ""
    Write-Host "Start a session:" -ForegroundColor Yellow
    Write-Host "  claude --plugin-dir '$PluginRoot'" -ForegroundColor Yellow
    exit 0
}
