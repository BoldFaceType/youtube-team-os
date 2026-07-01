#!/usr/bin/env bash
# new-project.sh — Scaffold a new youtube-team-os project
# Usage: ./bin/new-project.sh <slug> [ep-number] [target-date]
#
# Creates: state/projects/YYYY-MM-ep##-slug/ with all required files
# Updates: state/notes/content-calendar.md

set -euo pipefail

SLUG="${1:-}"
EP_NUMBER="${2:-0}"
TARGET_DATE="${3:-}"

if [[ -z "$SLUG" ]]; then
    echo "Usage: $0 <slug> [ep-number] [target-date YYYY-MM-DD]" >&2
    exit 1
fi

# ── Resolve plugin root ───────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"

# ── Build project ID ──────────────────────────────────────────────────────────
YEAR_MONTH="$(date +%Y-%m)"

if [[ "$EP_NUMBER" -eq 0 ]]; then
    # Auto-increment: count existing projects this month
    EXISTING=$(find "$PLUGIN_ROOT/state/projects" -maxdepth 1 -type d -name "${YEAR_MONTH}-*" 2>/dev/null | wc -l)
    EP_NUMBER=$((EXISTING + 1))
fi

EP_PADDED=$(printf "%02d" "$EP_NUMBER")
PROJECT_ID="${YEAR_MONTH}-ep${EP_PADDED}-${SLUG}"
PROJECT_DIR="$PLUGIN_ROOT/state/projects/$PROJECT_ID"

# ── Check for duplicates ──────────────────────────────────────────────────────
if [[ -d "$PROJECT_DIR" ]]; then
    echo "Error: Project already exists: $PROJECT_ID" >&2
    exit 1
fi

echo "[yt-os] Creating project: $PROJECT_ID"

# ── Create project directory ──────────────────────────────────────────────────
mkdir -p "$PROJECT_DIR"

# ── Scaffold files ────────────────────────────────────────────────────────────
TODAY="$(date +%Y-%m-%d)"
NOW="$(date '+%Y-%m-%d %H:%M')"

# status.md
cat > "$PROJECT_DIR/status.md" <<EOF
stage: INTAKE
owner: producer
created: $TODAY
updated: $TODAY
EOF

# activity.log
cat > "$PROJECT_DIR/activity.log" <<EOF
[$NOW] Project created by new-project.sh
[$NOW] INTAKE — assigned to producer
EOF

# brief.md (stub)
cat > "$PROJECT_DIR/brief.md" <<EOF
# Brief: $PROJECT_ID

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
EOF

# Deliverable stubs
for STUB in outline script edit-notes thumbnail-options publish-plan postmortem; do
    echo "# $STUB — $PROJECT_ID" > "$PROJECT_DIR/${STUB}.md"
    echo "" >> "$PROJECT_DIR/${STUB}.md"
    echo "> Not yet written. Stage: INTAKE" >> "$PROJECT_DIR/${STUB}.md"
done

# ── Update content calendar ───────────────────────────────────────────────────
CALENDAR="$PLUGIN_ROOT/state/notes/content-calendar.md"

if [[ -z "$TARGET_DATE" ]]; then
    # Default: 14 days from today
    if command -v gdate &>/dev/null; then
        TARGET_DATE="$(gdate -d '+14 days' +%Y-%m-%d)"
    else
        TARGET_DATE="$(date -v +14d +%Y-%m-%d 2>/dev/null || date -d '+14 days' +%Y-%m-%d)"
    fi
fi

ROW="| $PROJECT_ID | (untitled) | $TARGET_DATE | INTAKE | producer |"

if [[ -f "$CALENDAR" ]]; then
    echo "" >> "$CALENDAR"
    echo "$ROW" >> "$CALENDAR"
else
    cat > "$CALENDAR" <<EOF
# Content Calendar

| Project ID | Title | Target Date | Stage | Owner |
|---|---|---|---|---|
$ROW
EOF
fi

# ── Post to producer inbox ────────────────────────────────────────────────────
INBOX="$PLUGIN_ROOT/state/roles/producer/inbox.md"
echo "" >> "$INBOX"
echo "- [ ] [$PROJECT_ID] Write content brief — state/projects/$PROJECT_ID/brief.md" >> "$INBOX"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "[yt-os] Project scaffolded successfully!"
echo "  ID:    $PROJECT_ID"
echo "  Path:  $PROJECT_DIR"
echo "  Stage: INTAKE → producer"
echo ""
echo "Next step:"
echo "  /youtube-team-os:producer $PROJECT_ID"
