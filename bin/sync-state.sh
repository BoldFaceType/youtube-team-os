#!/usr/bin/env bash
# sync-state.sh — Sync state/ deliverables to Google Drive via rclone
# Usage: ./bin/sync-state.sh [project-id] [--dry-run]
#
# Prerequisites:
#   1. rclone installed: https://rclone.org/downloads or `brew install rclone`
#   2. rclone configured with Google Drive remote named "gdrive"
#      Run: rclone config  (add a remote, choose Google Drive, name it "gdrive")
#   3. Set $YT_OS_DRIVE_ROOT to your Drive folder (default: "YouTube Team OS")

set -euo pipefail

PROJECT_ID=""
DRY_RUN=false

for ARG in "$@"; do
    case "$ARG" in
        --dry-run) DRY_RUN=true ;;
        *) PROJECT_ID="$ARG" ;;
    esac
done

DRIVE_ROOT="${YT_OS_DRIVE_ROOT:-YouTube Team OS}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"
STATE_DIR="$PLUGIN_ROOT/state"

# ── Check rclone ──────────────────────────────────────────────────────────────
if ! command -v rclone >/dev/null 2>&1; then
    echo "rclone not found. Install it first:" >&2
    echo "  https://rclone.org/downloads or: brew install rclone" >&2
    echo "" >&2
    echo "Then configure Google Drive:" >&2
    echo "  rclone config" >&2
    echo "  (Add remote named 'gdrive', type: drive)" >&2
    exit 1
fi

# ── Build sync args ───────────────────────────────────────────────────────────
RCLONE_ARGS=(sync --progress --exclude "*.log" --exclude "current.md" --exclude ".gitkeep")

if [[ "$DRY_RUN" == true ]]; then
    RCLONE_ARGS+=(--dry-run)
    echo "[yt-os] DRY RUN — no files will be transferred"
fi

# ── Sync scope ────────────────────────────────────────────────────────────────
if [[ -n "$PROJECT_ID" ]]; then
    LOCAL_PATH="$STATE_DIR/projects/$PROJECT_ID"
    REMOTE_PATH="gdrive:$DRIVE_ROOT/projects/$PROJECT_ID"

    if [[ ! -d "$LOCAL_PATH" ]]; then
        echo "Error: Project not found: $LOCAL_PATH" >&2
        exit 1
    fi

    echo "[yt-os] Syncing project: $PROJECT_ID"
    echo "  Local:  $LOCAL_PATH"
    echo "  Remote: $REMOTE_PATH"
    echo ""

    rclone "${RCLONE_ARGS[@]}" "$LOCAL_PATH" "$REMOTE_PATH"
else
    LOCAL_PATH="$STATE_DIR/projects"
    REMOTE_PATH="gdrive:$DRIVE_ROOT/projects"

    echo "[yt-os] Syncing all projects to Drive"
    echo "  Local:  $LOCAL_PATH"
    echo "  Remote: $REMOTE_PATH"
    echo ""

    rclone "${RCLONE_ARGS[@]}" "$LOCAL_PATH" "$REMOTE_PATH"

    NOTES_LOCAL="$STATE_DIR/notes"
    NOTES_REMOTE="gdrive:$DRIVE_ROOT/notes"
    echo "[yt-os] Syncing notes/"
    rclone "${RCLONE_ARGS[@]}" "$NOTES_LOCAL" "$NOTES_REMOTE"
fi

echo ""
echo "[yt-os] Sync complete."
if [[ "$DRY_RUN" != true ]]; then
    echo "  View on Drive: https://drive.google.com/drive/search?q=${DRIVE_ROOT// /%20}"
fi
