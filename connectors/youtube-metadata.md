# Connector: YouTube Metadata

## Purpose
Fetch video stats, comments, channel metrics, and transcript data from YouTube.

## Recommended MCP / Tool
- **YouTube Data API v3** via an MCP server
- Or: use `yt-dlp` in `bin/` for transcript extraction

## Setup
1. Create a Google Cloud project and enable YouTube Data API v3
2. Generate an API key (no OAuth needed for public data)
3. Add to `.mcp.json` at plugin root:

```json
{
  "mcpServers": {
    "youtube": {
      "command": "npx",
      "args": ["@your-mcp/youtube-data", "--api-key", "${YOUTUBE_API_KEY}"]
    }
  }
}
```

## Available Operations
- `get_video_stats(video_id)` → views, CTR, retention, likes, comments
- `get_channel_stats(channel_id)` → subscribers, total views, upload count
- `get_video_comments(video_id, limit)` → top comments for postmortem/community
- `get_transcript(video_id)` → raw transcript for repurposing

## Usage in Skills
Reference in growth skill postmortem step to auto-populate analytics snapshot.
