#!/usr/bin/env bash
# validate.sh — Run plugin validation and state health checks (Mac/Linux port of validate.ps1)
# Usage: ./bin/validate.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"

PASSES=0
WARNINGS=0
ERRORS=0
ERROR_MESSAGES=()

check() {
    local label="$1" condition="$2" message="$3" warn="${4:-false}"
    if [[ "$condition" == "true" ]]; then
        PASSES=$((PASSES + 1))
        echo "  ✓ $label"
    elif [[ "$warn" == "true" ]]; then
        WARNINGS=$((WARNINGS + 1))
        echo "  ⚠ $label — $message"
    else
        ERRORS=$((ERRORS + 1))
        ERROR_MESSAGES+=("$label — $message")
        echo "  ✗ $label — $message"
    fi
}

path_exists() { [[ -e "$1" ]] && echo true || echo false; }

echo ""
echo "═══════════════════════════════════════"
echo " youtube-team-os — Plugin Validation"
echo "═══════════════════════════════════════"
echo ""

# ── 1. Manifest ────────────────────────────────────────────────────────────────
echo "── Manifest ──────────────────────────"
MANIFEST_PATH="$PLUGIN_ROOT/.claude-plugin/plugin.json"
check "plugin.json exists" "$(path_exists "$MANIFEST_PATH")" "Missing .claude-plugin/plugin.json"

if [[ -f "$MANIFEST_PATH" ]]; then
    if command -v jq >/dev/null 2>&1 && jq empty "$MANIFEST_PATH" >/dev/null 2>&1; then
        check "manifest.name" "$([[ "$(jq -r '.name // empty' "$MANIFEST_PATH")" != "" ]] && echo true || echo false)" "Missing 'name' field"
        check "manifest.version" "$([[ "$(jq -r '.version // empty' "$MANIFEST_PATH")" != "" ]] && echo true || echo false)" "Missing 'version' field"
        check "manifest.author" "$([[ "$(jq -r '.author // empty' "$MANIFEST_PATH")" != "" ]] && echo true || echo false)" "Missing 'author' field"
    else
        ERRORS=$((ERRORS + 1))
        ERROR_MESSAGES+=("plugin.json — Invalid JSON or jq unavailable to check it")
        echo "  ✗ plugin.json — Invalid JSON or jq unavailable to check it"
    fi
fi

# ── 2. Required files ─────────────────────────────────────────────────────────
echo ""
echo "── Required files ─────────────────────"
REQUIRED_FILES=(
    "CLAUDE.md" "README.md" "CHANGELOG.md" "hooks/hooks.json" "settings.json"
    "skills/orchestrator/SKILL.md" "skills/producer/SKILL.md" "skills/writer/SKILL.md"
    "skills/editor/SKILL.md" "skills/thumbnail/SKILL.md" "skills/growth/SKILL.md"
    "agents/orchestrator.md" "agents/producer.md" "agents/writer.md"
    "agents/editor.md" "agents/thumbnail.md" "agents/growth.md"
)
for f in "${REQUIRED_FILES[@]}"; do
    check "$f" "$(path_exists "$PLUGIN_ROOT/$f")" "File missing"
done

# ── 3. .mcp.json validation ────────────────────────────────────────────────────
echo ""
echo "── MCP config ─────────────────────────"
MCP_PATH="$PLUGIN_ROOT/.mcp.json"
if [[ -f "$MCP_PATH" ]]; then
    if command -v jq >/dev/null 2>&1 && jq empty "$MCP_PATH" >/dev/null 2>&1; then
        check ".mcp.json valid JSON" true ""
    else
        ERRORS=$((ERRORS + 1))
        ERROR_MESSAGES+=(".mcp.json — Invalid JSON")
        echo "  ✗ .mcp.json — Invalid JSON"
    fi
else
    check ".mcp.json exists" false "Missing .mcp.json (should exist, even with an empty mcpServers object)"
fi

# ── 4. Hooks validation ────────────────────────────────────────────────────────
echo ""
echo "── Hooks ──────────────────────────────"
HOOKS_PATH="$PLUGIN_ROOT/hooks/hooks.json"
if [[ -f "$HOOKS_PATH" ]]; then
    if command -v jq >/dev/null 2>&1 && jq empty "$HOOKS_PATH" >/dev/null 2>&1; then
        check "hooks.json valid JSON" true ""
        check "SessionStart hook defined" "$([[ "$(jq -r '.hooks.SessionStart // empty' "$HOOKS_PATH")" != "" ]] && echo true || echo false)" "Missing SessionStart"
        check "PostToolUse hook defined" "$([[ "$(jq -r '.hooks.PostToolUse // empty' "$HOOKS_PATH")" != "" ]] && echo true || echo false)" "Missing PostToolUse"
        check "SessionEnd hook defined" "$([[ "$(jq -r '.hooks.SessionEnd // empty' "$HOOKS_PATH")" != "" ]] && echo true || echo false)" "Missing SessionEnd" true

        SESSION_START_CMDS="$(jq -r '.hooks.SessionStart[0].hooks[].command' "$HOOKS_PATH" 2>/dev/null)"
        check "check-deadlines.js wired into SessionStart" "$(echo "$SESSION_START_CMDS" | grep -q "check-deadlines.js" && echo true || echo false)" "Deadline reminder hook missing from hooks.json"
        check "check-postmortem-due.js wired into SessionStart" "$(echo "$SESSION_START_CMDS" | grep -q "check-postmortem-due.js" && echo true || echo false)" "Postmortem reminder hook missing from hooks.json"
    else
        ERRORS=$((ERRORS + 1))
        ERROR_MESSAGES+=("hooks.json — Invalid JSON")
        echo "  ✗ hooks.json — Invalid JSON"
    fi
fi

# ── 4b. Monitor scripts referenced by hooks ────────────────────────────────────
echo ""
echo "── Monitor scripts ────────────────────"
check "monitors/check-deadlines.js exists" "$(path_exists "$PLUGIN_ROOT/monitors/check-deadlines.js")" "File missing"
check "monitors/check-postmortem-due.js exists" "$(path_exists "$PLUGIN_ROOT/monitors/check-postmortem-due.js")" "File missing"

MONITORS_JSON_PATH="$PLUGIN_ROOT/monitors/monitors.json"
if [[ -f "$MONITORS_JSON_PATH" ]]; then
    if command -v jq >/dev/null 2>&1 && jq empty "$MONITORS_JSON_PATH" >/dev/null 2>&1; then
        check "monitors.json valid JSON" true ""
        check "monitors.json is a bare array" "$([[ "$(jq -r 'if type == "array" then "true" else "false" end' "$MONITORS_JSON_PATH")" == "true" ]] && echo true || echo false)" "Should be a bare JSON array (possibly empty), not a wrapped object — real logic now lives in hooks.json"
    else
        ERRORS=$((ERRORS + 1))
        ERROR_MESSAGES+=("monitors.json — Invalid JSON")
        echo "  ✗ monitors.json — Invalid JSON"
    fi
fi

# ── 5. Required scripts and docs ───────────────────────────────────────────────
echo ""
echo "── Scripts and connector docs ─────────"
for s in bin/new-project.ps1 bin/new-project.sh bin/validate.ps1 bin/validate.sh bin/sync-state.ps1 bin/sync-state.sh; do
    check "$s" "$(path_exists "$PLUGIN_ROOT/$s")" "File missing" true
done
for d in connectors/youtube-metadata.md connectors/drive.md connectors/mcp-setup.md; do
    check "$d" "$(path_exists "$PLUGIN_ROOT/$d")" "File missing"
done

# ── 6. Dependencies ─────────────────────────────────────────────────────────────
echo ""
echo "── Dependencies ───────────────────────"
check "jq on PATH" "$(command -v jq >/dev/null 2>&1 && echo true || echo false)" "Write-audit hook requires jq (falls back to a jq-missing sentinel line otherwise). Install: apt/brew install jq" true
check "claude CLI on PATH" "$(command -v claude >/dev/null 2>&1 && echo true || echo false)" "Install Claude Code: https://claude.ai/code" true
check "Node.js on PATH" "$(command -v node >/dev/null 2>&1 && echo true || echo false)" "bin/ scripts and the two SessionStart reminder hooks require Node.js v18+. Install: https://nodejs.org" true
check "rclone on PATH" "$(command -v rclone >/dev/null 2>&1 && echo true || echo false)" "Optional — required only for bin/sync-state.ps1/.sh. Install: https://rclone.org/downloads" true

# ── 7. State directories ────────────────────────────────────────────────────────
echo ""
echo "── State filesystem ───────────────────"
STATE_DIRS=(state/projects state/roles/producer state/roles/writer state/roles/editor state/roles/thumbnail state/roles/growth state/notes state/records)
for d in "${STATE_DIRS[@]}"; do
    check "$d" "$(path_exists "$PLUGIN_ROOT/$d")" "Directory missing — run: mkdir -p $d"
done

# ── Summary ──────────────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════"
echo " Results"
echo "═══════════════════════════════════════"
echo "  Passed:   $PASSES"
echo "  Warnings: $WARNINGS"
echo "  Errors:   $ERRORS"
echo ""

if [[ $ERRORS -gt 0 ]]; then
    echo "Errors to fix:"
    for m in "${ERROR_MESSAGES[@]}"; do echo "  • $m"; done
    echo ""
    exit 1
else
    echo "Plugin is valid and ready to use."
    echo ""
    echo "Start a session:"
    echo "  claude --plugin-dir '$PLUGIN_ROOT'"
    exit 0
fi
