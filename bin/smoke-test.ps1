#!/usr/bin/env pwsh
# smoke-test.ps1 — Deterministic mechanical regression test for youtube-team-os
# Usage: .\bin\smoke-test.ps1 [-Verbose] [-InjectFailure] [-KeepScratch]
#
# Exercises the mechanical parts of the plugin with no LLM involved: validate.ps1,
# new-project scaffolding, hook commands, and the two SessionStart monitor scripts
# (including a non-UTC-timezone run, which is the regression test for TM-6).
# Does NOT exercise the 6 role skills/agents themselves — those are markdown
# instructions executed by an LLM, not deterministic code. See tests/e2e-runbook.md
# for the manual headless-Claude proof of the full pipeline.
#
# -InjectFailure deliberately breaks one check so this script can be self-tested:
# it must report a failure and exit 1, not pass silently.

param(
    [switch]$Verbose,
    [switch]$InjectFailure,
    [switch]$KeepScratch
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$PluginRoot = Split-Path -Parent $ScriptDir

$Errors = @()
$Passes = @()

function Check($Label, $Condition, $Message) {
    if ($Condition) {
        $script:Passes += $Label
        Write-Host "  ✓ $Label" -ForegroundColor Green
    } else {
        $script:Errors += "$Label — $Message"
        Write-Host "  ✗ $Label — $Message" -ForegroundColor Red
    }
}

# Resolve Git Bash explicitly. A bare `bash` on PATH may resolve to
# C:\WINDOWS\system32\bash.exe (the WSL launcher), which does not inherit Windows
# environment variables or understand Windows-style paths the way hooks.json's
# commands expect — Claude Code's hooks run through Git Bash semantics, so tests
# must too, or they'll pass/fail for the wrong reasons.
function Find-GitBash {
    # On Linux/Mac there's no WSL-launcher ambiguity — a bare `bash` is the real one.
    if (-not $IsWindows) {
        $Cmd = Get-Command bash -ErrorAction SilentlyContinue
        if ($Cmd) { return $Cmd.Source }
        return $null
    }
    $Candidates = @(
        "C:\Program Files\Git\bin\bash.exe",
        "C:\Program Files\Git\usr\bin\bash.exe",
        "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe"
    )
    foreach ($C in $Candidates) { if (Test-Path $C) { return $C } }
    return $null
}
$BashExe = Find-GitBash
if ($null -eq $BashExe) {
    Write-Host "  ✗ Bash not found — cannot test hooks.json commands" -ForegroundColor Red
    exit 1
}

# Writes $Command to a temp .sh file and runs it via Git Bash, instead of `bash -c
# "<string>"` — PowerShell's argument quoting mangles complex strings containing
# nested quotes/`${...}` when passed as a single -c argument.
#
# $StdinJson is required for PostToolUse: the real hook always receives the tool-use
# event JSON on stdin from Claude Code, and hooks.json's command does `jq -r
# '.tool_input.file_path'` with no explicit input file — jq reads stdin by default and
# blocks forever if nothing is piped in. Without this, the test hangs, it doesn't fail.
function Invoke-HookCommand($Command, $StdinJson = $null) {
    $TempScript = [System.IO.Path]::GetTempFileName() + ".sh"
    Set-Content -Path $TempScript -Value $Command -Encoding UTF8 -NoNewline
    if ($null -ne $StdinJson) {
        $StdinJson | & $BashExe $TempScript
    } else {
        "" | & $BashExe $TempScript
    }
    Remove-Item $TempScript -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host " youtube-team-os — Smoke Test"          -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan

# ── Scratch workspace ──────────────────────────────────────────────────────────
$Scratch = Join-Path $env:TEMP "yt-os-smoke-$(Get-Date -Format 'yyyyMMddHHmmssfff')"
New-Item -ItemType Directory -Path $Scratch -Force | Out-Null
Write-Host ""
Write-Host "Scratch dir: $Scratch" -ForegroundColor DarkGray

try {
    # ── 1. bin/validate.ps1 must pass clean ────────────────────────────────────
    Write-Host ""
    Write-Host "── 1. validate.ps1 ────────────────────" -ForegroundColor White
    & "$PluginRoot\bin\validate.ps1" | Out-Null
    Check "validate.ps1 exits 0" ($LASTEXITCODE -eq 0) "validate.ps1 reported errors — fix those before trusting this smoke test"

    # ── 2. new-project.ps1 scaffolding ─────────────────────────────────────────
    Write-Host ""
    Write-Host "── 2. new-project.ps1 scaffolding ─────" -ForegroundColor White
    $StateRoot = Join-Path $Scratch "state"
    $TargetDate3d = (Get-Date).AddDays(3).ToString("yyyy-MM-dd")

    $NewProjectScript = if ($InjectFailure) { "$PluginRoot\bin\new-project-DOES-NOT-EXIST.ps1" } else { "$PluginRoot\bin\new-project.ps1" }
    try {
        & $NewProjectScript -Slug "smoke-topic" -EpNumber 1 -TargetDate $TargetDate3d -StateRoot $StateRoot 2>$null | Out-Null
    } catch {
        # Expected when -InjectFailure points at a nonexistent script — let the Check
        # calls below report it as a normal failure instead of crashing the whole run.
    }

    $YearMonth = Get-Date -Format "yyyy-MM"
    $ProjectDir = "$StateRoot\projects\$YearMonth-ep01-smoke-topic"

    Check "project directory created" (Test-Path $ProjectDir) "Expected $ProjectDir"

    $ExpectedFiles = @("status.md", "activity.log", "brief.md", "outline.md", "script.md", "edit-notes.md", "thumbnail-options.md", "publish-plan.md", "postmortem.md")
    $AllFilesPresent = $true
    foreach ($F in $ExpectedFiles) {
        if (-not (Test-Path "$ProjectDir\$F")) { $AllFilesPresent = $false }
    }
    Check "all 9 deliverable/status files scaffolded" $AllFilesPresent "One or more of: $($ExpectedFiles -join ', ')"

    $CalendarPath = "$StateRoot\notes\content-calendar.md"
    $CalendarOk = $false
    if (Test-Path $CalendarPath) {
        $Row = (Get-Content $CalendarPath | Where-Object { $_ -like "*smoke-topic*" })
        if ($Row) {
            $ColumnCount = ($Row -split '\|').Count - 2  # leading/trailing empty from split
            $CalendarOk = ($ColumnCount -eq 5)
        }
    }
    Check "calendar row has 5 columns (TM-4 regression)" $CalendarOk "Row should have Project ID | Title | Target Date | Stage | Owner"

    $InboxPath = "$StateRoot\roles\producer\inbox.md"
    $InboxOk = (Test-Path $InboxPath) -and ((Get-Content $InboxPath -Raw) -like "*smoke-topic*")
    Check "producer inbox got handoff entry" $InboxOk "Expected an entry in $InboxPath"

    # ── 3. Hook commands (actual command strings from hooks.json) ─────────────
    Write-Host ""
    Write-Host "── 3. hooks.json commands ─────────────" -ForegroundColor White

    $HooksJson = Get-Content "$PluginRoot\hooks\hooks.json" -Raw | ConvertFrom-Json
    $RecordsDir = "$StateRoot\records"

    $SessionStartCmd = $HooksJson.hooks.SessionStart[0].hooks[0].command
    $env:CLAUDE_PROJECT_DIR = $Scratch
    Invoke-HookCommand $SessionStartCmd
    $SessionLogOk = (Test-Path "$RecordsDir\session.log") -and ((Get-Content "$RecordsDir\session.log" -Raw) -like "*Session started*")
    Check "SessionStart hook writes session.log (dir auto-created)" $SessionLogOk "Expected non-empty $RecordsDir\session.log"

    # Real Claude Code pipes the tool-use event JSON into PostToolUse hook commands on
    # stdin — hooks.json's jq call reads from stdin with no explicit input file.
    $ToolUseEventJson = '{"tool_input":{"file_path":"state/projects/smoke-topic/brief.md"}}'

    $PostToolUseCmd = $HooksJson.hooks.PostToolUse[0].hooks[0].command
    Invoke-HookCommand $PostToolUseCmd $ToolUseEventJson
    $WritesLogContent = if (Test-Path "$RecordsDir\writes.log") { Get-Content "$RecordsDir\writes.log" -Raw } else { "" }
    $WritesLogOk = ($WritesLogContent -like "*[write]*")
    Check "PostToolUse hook writes writes.log" $WritesLogOk "Expected a [write] line in $RecordsDir\writes.log"

    # jq-missing sentinel: strip only jq's directory from PATH for this one
    # invocation (nuking PATH entirely would also hide `date`/`mkdir`, which Git
    # Bash resolves as external binaries, breaking the hook command for reasons
    # unrelated to jq).
    $OldPath = $env:PATH
    try {
        $JqCmd = Get-Command jq -ErrorAction SilentlyContinue
        if ($JqCmd) {
            $JqDir = Split-Path $JqCmd.Source -Parent
            $env:PATH = ($OldPath -split ';' | Where-Object { $_ -ne $JqDir }) -join ';'
        }
        Remove-Item "$RecordsDir\writes.log" -ErrorAction SilentlyContinue
        Invoke-HookCommand $PostToolUseCmd $ToolUseEventJson
    } finally {
        $env:PATH = $OldPath
    }
    $JqMissingOk = (Test-Path "$RecordsDir\writes.log") -and ((Get-Content "$RecordsDir\writes.log" -Raw) -like "*jq-missing*")
    Check "jq-missing sentinel fires when jq absent (TM-3 regression)" $JqMissingOk "Expected a jq-missing line, not a blank/garbled entry"

    # ── 4. check-deadlines.js (TM-4 + TM-6 regression) ─────────────────────────
    Write-Host ""
    Write-Host "── 4. check-deadlines.js ──────────────" -ForegroundColor White

    $MonitorFixtureRoot = Join-Path $Scratch "monitor-fixture"
    New-Item -ItemType Directory -Path "$MonitorFixtureRoot\state\notes" -Force | Out-Null
    $DueIn3d    = (Get-Date).AddDays(3).ToString("yyyy-MM-dd")
    $Overdue10d = (Get-Date).AddDays(-10).ToString("yyyy-MM-dd")
    @"
# Content Calendar
| Project ID | Title | Target Date | Stage | Owner |
|---|---|---|---|---|
| smoke-due-3d | Due Soon | $DueIn3d | INTAKE | producer |
| smoke-overdue-10d | Overdue | $Overdue10d | BRIEF | writer |
"@ | Set-Content "$MonitorFixtureRoot\state\notes\content-calendar.md" -Encoding UTF8

    $DeadlinesScript = if ($InjectFailure) { "$PluginRoot\monitors\check-deadlines-DOES-NOT-EXIST.js" } else { "$PluginRoot\monitors\check-deadlines.js" }

    $env:CLAUDE_PLUGIN_ROOT = $MonitorFixtureRoot
    $Output = & node $DeadlinesScript 2>&1 | Out-String
    Check "warns DUE IN 3d (UTC/local default)" ($Output -match "DUE IN 3d") "stdout: $Output"
    Check "warns OVERDUE 10d (UTC/local default)" ($Output -match "OVERDUE 10d") "stdout: $Output"

    # Same assertion under a non-UTC timezone — this is the actual TM-6 regression test
    $OldTz = $env:TZ
    try {
        $env:TZ = "America/New_York"
        $OutputTz = & node $DeadlinesScript 2>&1 | Out-String
        Check "warns DUE IN 3d under TZ=America/New_York (TM-6 regression)" ($OutputTz -match "DUE IN 3d") "stdout: $OutputTz"
    } finally {
        if ($null -ne $OldTz) { $env:TZ = $OldTz } else { Remove-Item Env:\TZ -ErrorAction SilentlyContinue }
    }

    # ── 5. check-postmortem-due.js ─────────────────────────────────────────────
    Write-Host ""
    Write-Host "── 5. check-postmortem-due.js ─────────" -ForegroundColor White

    $PmFixtureRoot = Join-Path $Scratch "postmortem-fixture"
    $PmProjectDir = "$PmFixtureRoot\state\projects\smoke-pm-due"
    New-Item -ItemType Directory -Path $PmProjectDir -Force | Out-Null
    $PublishDate = (Get-Date).AddDays(-30).ToString("yyyy-MM-dd")
    "stage: PUBLISH`nowner: growth`ncreated: $PublishDate`nupdated: $PublishDate" | Set-Content "$PmProjectDir\status.md" -Encoding UTF8
    "[$PublishDate 10:00] THUMBNAIL -> PUBLISH (by orchestrator)" | Set-Content "$PmProjectDir\activity.log" -Encoding UTF8
    "> Not yet written. Stage: PUBLISH`n[VIEWS]" | Set-Content "$PmProjectDir\postmortem.md" -Encoding UTF8

    $env:CLAUDE_PLUGIN_ROOT = $PmFixtureRoot
    $PmOutput = & node "$PluginRoot\monitors\check-postmortem-due.js" 2>&1 | Out-String
    Check "warns POSTMORTEM DUE for a 30-day-old published video" ($PmOutput -match "POSTMORTEM DUE") "stdout: $PmOutput"

} finally {
    Remove-Item Env:\CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue
    Remove-Item Env:\CLAUDE_PLUGIN_ROOT -ErrorAction SilentlyContinue
    if (-not $KeepScratch) {
        Remove-Item -Recurse -Force $Scratch -ErrorAction SilentlyContinue
    } else {
        Write-Host ""
        Write-Host "Scratch dir kept: $Scratch" -ForegroundColor DarkGray
    }
}

# ── Summary ─────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host " Results" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Passed: $($Passes.Count)" -ForegroundColor Green
Write-Host "  Failed: $($Errors.Count)" -ForegroundColor $(if ($Errors.Count -gt 0) { "Red" } else { "Green" })
Write-Host ""

if ($Errors.Count -gt 0) {
    Write-Host "Failures:" -ForegroundColor Red
    $Errors | ForEach-Object { Write-Host "  • $_" -ForegroundColor Red }
    Write-Host ""
    exit 1
} else {
    Write-Host "Smoke test passed. Mechanical scaffolding works." -ForegroundColor Green
    Write-Host "This does NOT prove the 6 role skills work — see tests\e2e-runbook.md." -ForegroundColor Yellow
    Write-Host ""
    exit 0
}
