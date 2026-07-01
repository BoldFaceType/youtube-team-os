# MCP Connector Setup

Both connectors are pre-configured in `.mcp.json` at the plugin root.
Claude Code merges this with user and project MCP configs on session start.

---

## YouTube Data API v3

### 1. Create Google Cloud project

1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. New project → enable **YouTube Data API v3**
3. Credentials → Create API key → restrict to YouTube Data API v3
4. Copy the key

### 2. Set env var

```powershell
# Windows — add to your shell profile or .env
$env:YOUTUBE_API_KEY = "AIza..."
```

```bash
# Mac/Linux
export YOUTUBE_API_KEY="AIza..."
```

### 3. Verify

```bash
# Should return video metadata
curl "https://www.googleapis.com/youtube/v3/videos?id=dQw4w9WgXcQ&part=snippet&key=$YOUTUBE_API_KEY"
```

### Available operations (via MCP)

| Tool | Description | Required params |
|---|---|---|
| `videos_list` | Fetch video stats, snippet, status | `id`, `part` |
| `videos_update` | Update title/description/tags | `id`, `snippet.title`, `snippet.categoryId` |
| `videos_insert` | Upload a video | `snippet`, `status`, video file |
| `thumbnails_set` | Upload thumbnail image | `videoId`, image bytes |
| `channels_list` | Channel stats and metadata | `id` or `mine=true`, `part` |
| `search_list` | Search YouTube | `q`, `type`, `part` |

### OAuth scopes (for write operations)

- `https://www.googleapis.com/auth/youtube` — full access
- `https://www.googleapis.com/auth/youtube.upload` — upload only
- `https://www.googleapis.com/auth/youtube.readonly` — read only (analytics)

---

## Google Drive

### 1. Enable Drive API

1. Same Google Cloud project
2. Enable **Google Drive API**
3. Credentials → OAuth 2.0 client → Desktop app
4. Download `credentials.json`

### 2. Set env var

```powershell
# Windows — point to your credentials.json
$env:GOOGLE_CREDENTIALS = "C:\path\to\credentials.json"
```

```bash
# Mac/Linux
export GOOGLE_CREDENTIALS="/path/to/credentials.json"
```

### 3. First run — authorize

On first use, the MCP server will open a browser window for OAuth consent.
Credentials are cached locally after first auth.

### Available operations (via MCP)

| Tool | Description |
|---|---|
| `drive_list_files` | List files in a folder |
| `drive_read_file` | Read file content |
| `drive_create_file` | Create/upload a file |
| `drive_update_file` | Update file content |
| `drive_share_file` | Set sharing permissions |

### Recommended folder structure (Drive)

```
YouTube Team OS/
  projects/
    2026-07-ep01-pricing-mistakes/
      brief.md
      script.md
      edit-notes.md
      thumbnail-options.md
  assets/
    thumbnails/
    b-roll/
```

---

## Testing connectors

```bash
# Validate .mcp.json is syntactically correct
npx --yes @anthropic-ai/claude-code plugin validate

# Test YouTube connector (in a Claude Code session)
/mcp youtube videos_list --id dQw4w9WgXcQ --part snippet,statistics

# Test Drive connector (in a Claude Code session)
/mcp drive drive_list_files --query "name contains 'YouTube Team OS'"
```
