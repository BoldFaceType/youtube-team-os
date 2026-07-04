# Connector: Google Drive

## Purpose
Save/retrieve assets, transcripts, raw footage lists, and deliverables.

## Current status: rclone, not MCP

The previously configured MCP package (`@modelcontextprotocol/server-gdrive`) is marked
"no longer supported" on npm. Rather than depend on a deprecated package, this plugin uses
`bin/sync-state.ps1` (Windows) / `bin/sync-state.sh` (Mac/Linux), which sync `state/` to
Google Drive via `rclone` — see those scripts' headers for setup (`rclone config`, add a
remote named `gdrive`).

## Usage
- `bin/sync-state.ps1 -ProjectId <id>` — sync one project's deliverables to Drive
- `bin/sync-state.ps1` (no args) — sync all projects plus `state/notes/`
- Recommended Drive folder structure:
  ```
  YouTube Team OS/
    projects/
      2026-07-ep01-pricing-mistakes/
        brief.md
        script.md
        edit-notes.md
        thumbnail-options.md
    notes/
  ```

## If a real MCP server becomes available
Add it to `.mcp.json`'s `mcpServers` object (currently empty) as a server named `drive`.
Verify it works (`npx -y <package>` responds to a basic file-list call) before referencing
it from any skill or agent file.
