# MCP Connector Setup

**Current status:** `.mcp.json` at the plugin root defines no servers (`{"mcpServers": {}}`).
The YouTube and Drive MCP servers this file used to configure were removed after a code
review found the YouTube package doesn't exist on npm (404) and the Drive package is
marked deprecated/unsupported.

- For YouTube analytics: see `connectors/youtube-metadata.md` — manual entry via YouTube
  Studio is the current path.
- For Drive sync: see `connectors/drive.md` — `bin/sync-state.ps1`/`.sh` (rclone-based) is
  the current path.

## If you want to wire up a real MCP server later

1. Confirm the package actually exists and is maintained:
   `npm view <package-name>` should not 404, and should not show a deprecation notice.
2. Add it to `.mcp.json`'s `mcpServers` object, following the shape in the official docs:
   `code.claude.com/docs/en/mcp`.
3. Test it responds to a basic call in a live Claude Code session before referencing it
   from any skill or agent file (`agents/growth.md`, `skills/growth/SKILL.md`).
4. Update `connectors/youtube-metadata.md` or `connectors/drive.md` to describe the working
   setup, and remove the "manual input only" framing once it's verified.
