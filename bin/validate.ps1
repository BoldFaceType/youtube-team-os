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
    ".mcp.json",
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
        Check "mcpServers.youtube defined" ($null -ne $Mcp.mcpServers.youtube) "YouTube MCP not configured"
        Check "mcpServers.drive defined"   ($null -ne $Mcp.mcpServers.drive)   "Drive MCP not configured"
    } catch {
        $Errors += ".mcp.json — Invalid JSON"
        Write-Host "  ✗ .mcp.json — Invalid JSON" -ForegroundColor Red
    }
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
    } catch {
        $Errors += "hooks.json — Invalid JSON"
        Write-Host "  ✗ hooks.json — Invalid JSON" -ForegroundColor Red
    }
}

# ── 5. jq availability ───────────────────────────────────────────────────────
Write-Host ""
Write-Host "── Dependencies ───────────────────────" -ForegroundColor White

$JqAvailable = $null -ne (Get-Command jq -ErrorAction SilentlyContinue)
Check "jq on PATH" $JqAvailable "Hooks require jq. Install: winget install jqlang.jq" -Warn

$ClaudeAvailable = $null -ne (Get-Command claude -ErrorAction SilentlyContinue)
Check "claude CLI on PATH" $ClaudeAvailable "Install Claude Code: https://claude.ai/code" -Warn

# ── 6. State directories ──────────────────────────────────────────────────────
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
