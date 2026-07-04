# Connector: YouTube Metadata

## Purpose
Fetch video stats, comments, channel metrics, and transcript data from YouTube.

## Current status: manual input only

No currently-maintained MCP server for the YouTube Data API v3 was found (the previously
configured `@modelcontextprotocol/server-youtube` package does not exist on npm). Until a
real, maintained MCP server is identified and adopted, analytics capture in the `growth`
skill uses manual input: leave `[VIEWS]`, `[CTR]`, and similar placeholders in
`state/records/analytics-<id>.md` and `state/projects/<id>/postmortem.md` for a human to
fill in from YouTube Studio.

## Manual data sources
- **YouTube Studio Analytics** (`studio.youtube.com`) — views, CTR, retention, watch time
- **YouTube Studio → Comments** — top comments for postmortem/community context
- `yt-dlp` (in `bin/` if added later) can extract transcripts locally without any API key

## If a real MCP server becomes available
Add it to `.mcp.json`'s `mcpServers` object (currently empty) as a server named `youtube`,
matching the shape documented in `connectors/mcp-setup.md`. Update `agents/growth.md` and
`skills/growth/SKILL.md` to reference it once it's verified working end to end
(`npx -y <package>` succeeds and returns real data for a test video ID).

## Usage in Skills
Referenced in the growth skill's postmortem step — see "What you must NOT do" in
`skills/growth/SKILL.md`: never fabricate stats, always use placeholders until real
numbers are entered.
