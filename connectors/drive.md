# Connector: Google Drive

## Purpose
Save/retrieve assets, transcripts, raw footage lists, and deliverables.

## Recommended MCP
- Google Drive MCP (available in Claude marketplace or via `@google/drive-mcp`)

## Setup
Add to `.mcp.json`:
```json
{
  "mcpServers": {
    "drive": {
      "command": "npx",
      "args": ["@google/drive-mcp"],
      "env": { "GOOGLE_CREDENTIALS": "${GOOGLE_CREDENTIALS}" }
    }
  }
}
```

## Usage
- Upload completed scripts, briefs, edit notes to a shared team folder
- Mirror `state/projects/<id>/` to Drive for team visibility
- Download raw footage file lists for editor reference
