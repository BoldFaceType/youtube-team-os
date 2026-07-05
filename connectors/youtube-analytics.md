# Connector: YouTube Analytics (plain-script)

## Purpose
Fetch per-video stats from YouTube and write them into the growth skill's
`state/records/analytics-<project-id>.md` snapshot, using
[`bin/fetch-analytics.js`](../bin/fetch-analytics.js). This is the **Option B**
plain-script approach (NON-48) that **supersedes** the manual-input-only guidance
in [`youtube-metadata.md`](./youtube-metadata.md) and the canceled
MCP-connector approach (NON-33).

- Single file, **zero npm dependencies**, Node >= 18 (built-in `fetch`).
- Deterministic: same inputs → same file. All numbers come from API responses;
  no LLM is involved anywhere in the fetch or the write.

## What each mode fetches

| Mode | Trigger | Public stats (Data API v3) | Watch time / retention / subs (Analytics API v2) |
|---|---|---|---|
| `dry-run` | `--dry-run` | fixture | fixture |
| `public` | `YT_API_KEY` only | real (views, likes, comments) | written as `manual (YouTube Studio)` |
| `full` | API key + OAuth refresh token | real | real |

The script auto-selects the mode from which credentials are present.

## APIs and endpoints used (verified 2026-07-05)

**YouTube Data API v3 — public per-video stats** (needs only an API key):
```
GET https://www.googleapis.com/youtube/v3/videos?part=statistics,snippet&id=<VIDEO_ID>&key=<API_KEY>
```
Returns `statistics.viewCount`, `statistics.likeCount`, `statistics.commentCount`
(quota cost: 1 unit). Ref:
https://developers.google.com/youtube/v3/docs/videos/list
Channel `subscriberCount` is available via
`GET /youtube/v3/channels?part=statistics&id=<CHANNEL_ID>&key=<API_KEY>`.

**YouTube Analytics API v2 — per-video watch metrics** (needs OAuth):
```
GET https://youtubeanalytics.googleapis.com/v2/reports
    ?ids=channel==MINE
    &startDate=<YYYY-MM-DD>&endDate=<YYYY-MM-DD>
    &metrics=views,estimatedMinutesWatched,averageViewDuration,averageViewPercentage,subscribersGained
    &filters=video==<VIDEO_ID>
```
Ref: https://developers.google.com/youtube/analytics/reference/reports/query
and the metrics list https://developers.google.com/youtube/analytics/metrics

## Honest limitations table

Verified against the YouTube Analytics API v2 **Metrics** reference
(https://developers.google.com/youtube/analytics/metrics, page last updated
2026-05-11) and the Data API v3 videos.list reference
(https://developers.google.com/youtube/v3/docs/videos/list, updated 2026-06-01).

| Metric | Available via API? | Source used by the script |
|---|---|---|
| Views | Yes | Analytics v2 `views` (full) / Data v3 `viewCount` (public) |
| Likes | Yes | Data v3 `statistics.likeCount` |
| Comments | Yes | Data v3 `statistics.commentCount` |
| Estimated minutes watched → watch-time hours | Yes | Analytics v2 `estimatedMinutesWatched` |
| Average view duration | Yes | Analytics v2 `averageViewDuration` |
| Average view percentage | Yes | Analytics v2 `averageViewPercentage` |
| Subscribers gained | Yes | Analytics v2 `subscribersGained` |
| Subscriber count (channel total) | Yes | Data v3 channels `statistics.subscriberCount` |
| **Impressions** | **No** | Not exposed by Analytics API v2 — Studio-only |
| **Impressions CTR** | **No** | Not exposed by Analytics API v2 — Studio-only |

**Impressions / CTR verdict:** The Analytics API v2 metrics reference lists no
`impressions` or `impressionsClickThroughRate` metric. The only "impression"
metrics it defines are `adImpressions` (ad performance), card/annotation
impressions, and playlist aggregated impressions — none of which are the
thumbnail impressions or thumbnail CTR shown in YouTube Studio. These remain
**Studio-only**. The script therefore always writes `manual (YouTube Studio)`
for CTR and Impressions, and the snapshot includes a note saying so.

## One-time setup

1. **Create / pick a Google Cloud project** at
   https://console.cloud.google.com/ .
2. **Enable both APIs** for that project (APIs & Services → Library):
   - *YouTube Data API v3*
   - *YouTube Analytics API*
3. **Create an API key** (APIs & Services → Credentials → Create credentials →
   API key). This is `YT_API_KEY`. Restrict it to the two APIs above.
4. **Configure the OAuth consent screen** (APIs & Services → OAuth consent
   screen): User type *External* (or *Internal* for a Workspace), add your
   Google account as a *Test user* while the app is unverified, and add the
   scopes `.../auth/yt-analytics.readonly` and `.../auth/youtube.readonly`.
5. **Create an OAuth client** (Credentials → Create credentials → OAuth client
   ID → Application type: **Desktop app**). Note the client ID and secret →
   `YT_OAUTH_CLIENT_ID` / `YT_OAUTH_CLIENT_SECRET`.
6. **Obtain a refresh token** with the built-in helper (Rule of One: the helper
   lives inside `fetch-analytics.js`, not a second script):
   ```
   YT_OAUTH_CLIENT_ID=... YT_OAUTH_CLIENT_SECRET=... \
     node bin/fetch-analytics.js --authorize
   ```
   It prints a Google consent URL, listens on `http://localhost:8723/` for the
   redirect, exchanges the code, and prints the refresh token. Save it as
   `YT_OAUTH_REFRESH_TOKEN`.

## Environment variable reference

| Variable | Required for | Meaning |
|---|---|---|
| `YT_API_KEY` | public, full | Data API v3 key |
| `YT_OAUTH_CLIENT_ID` | full, `--authorize` | OAuth Desktop-app client ID |
| `YT_OAUTH_CLIENT_SECRET` | full, `--authorize` | OAuth client secret |
| `YT_OAUTH_REFRESH_TOKEN` | full | Long-lived refresh token from `--authorize` |
| `YT_OS_STATE_ROOT` | optional | Overrides the default `<repo>/state` root |

If none of the four credential env vars are set, the script falls back to a
git-ignored `state/secrets/youtube.json`:
```json
{
  "apiKey": "...",
  "clientId": "...",
  "clientSecret": "...",
  "refreshToken": "..."
}
```

**Secrets hygiene:** `.gitignore` covers `.env`, `*.key`, and `.env.local`, but
does **not** yet have a blanket `state/secrets/` rule as of NON-48; this connector
adds a minimal `state/secrets/` entry. Keep `youtube.json` out of version control.

## Usage

```
# Public stats only (real views/likes/comments; watch-time = manual)
YT_API_KEY=... node bin/fetch-analytics.js \
  --project-id 2026-07-ep01-slug --video-id dQw4w9WgXcQ

# Full mode (both APIs)
YT_API_KEY=... YT_OAUTH_CLIENT_ID=... YT_OAUTH_CLIENT_SECRET=... \
YT_OAUTH_REFRESH_TOKEN=... node bin/fetch-analytics.js \
  --project-id 2026-07-ep01-slug --video-id dQw4w9WgXcQ --days 30

# Dry run (fixture, no network)
node bin/fetch-analytics.js --project-id demo --dry-run
```

Output overwrites `state/records/analytics-<project-id>.md` in the growth SKILL
snapshot format, with a `Source:` footer recording fetched-at timestamp, mode,
and API versions.

## Relationship to youtube-metadata.md
`youtube-metadata.md` documented the interim manual-input-only state (no MCP
server available). This connector supersedes the analytics-capture portion of
that guidance: analytics capture now runs through `bin/fetch-analytics.js`.
Transcript extraction (via `yt-dlp`) and comment review remain manual as
described there.
