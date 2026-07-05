#!/usr/bin/env node
// fetch-analytics.js — Plain-script YouTube analytics fetcher for youtube-team-os
//
// Purpose:
//   Fetch per-video public stats (YouTube Data API v3) and — when OAuth is
//   configured — watch-time / retention / subscriber metrics (YouTube Analytics
//   API v2) for a single video, and write them into the growth skill's
//   state/records/analytics-<project-id>.md snapshot format. Zero npm
//   dependencies; requires Node >= 18 for the built-in global fetch().
//
//   This is the "Option B" plain-script replacement for the canceled
//   MCP-connector approach (NON-33). See NON-48.
//
// Usage:
//   node bin/fetch-analytics.js --project-id 2026-07-ep01-slug --video-id dQw4w9WgXcQ
//   node bin/fetch-analytics.js --project-id 2026-07-ep01-slug --video-id dQw4w9WgXcQ --days 30
//   node bin/fetch-analytics.js --project-id demo --dry-run
//   node bin/fetch-analytics.js --authorize        # one-time refresh-token helper
//   node bin/fetch-analytics.js --help
//
// Modes (auto-selected from which credentials are present):
//   dry-run  → fixture data only, no network (use --dry-run)
//   public   → YT_API_KEY only: public stats real; OAuth-only fields written as
//              "manual (YouTube Studio)"
//   full     → YT_API_KEY + OAuth refresh token: both APIs queried
//
// Config (env vars, or a git-ignored state/secrets/youtube.json fallback):
//   YT_API_KEY, YT_OAUTH_CLIENT_ID, YT_OAUTH_CLIENT_SECRET, YT_OAUTH_REFRESH_TOKEN
//   YT_OS_STATE_ROOT (or --state-root) overrides the default <repo>/state root.
//
// Setup:
//   See connectors/youtube-analytics.md for the full GCP / OAuth walkthrough,
//   including how to obtain a refresh token with `--authorize`.
//
// Exit codes: 0 success · 1 usage error · 2 API/auth error

'use strict';

const fs = require('fs');
const path = require('path');
const http = require('http');
const { URL } = require('url');

// ── Constants ─────────────────────────────────────────────────────────────────
const DATA_API = 'https://www.googleapis.com/youtube/v3';
const ANALYTICS_API = 'https://youtubeanalytics.googleapis.com/v2/reports';
const TOKEN_ENDPOINT = 'https://oauth2.googleapis.com/token';
const OAUTH_AUTH_ENDPOINT = 'https://accounts.google.com/o/oauth2/v2/auth';
const SCOPES = [
  'https://www.googleapis.com/auth/yt-analytics.readonly',
  'https://www.googleapis.com/auth/youtube.readonly',
];
// Metrics verified available in the Analytics API v2 (metrics doc, updated
// 2026-05-11). NOTE: impressions and impressionsClickThroughRate are NOT
// exposed by the API — they remain YouTube Studio-only. See connectors doc.
const ANALYTICS_METRICS = [
  'views',
  'estimatedMinutesWatched',
  'averageViewDuration',
  'averageViewPercentage',
  'subscribersGained',
];
const MANUAL = 'manual (YouTube Studio)';

// ── Arg parsing ───────────────────────────────────────────────────────────────
function parseArgs(argv) {
  const args = {
    projectId: null,
    videoId: null,
    days: 28,
    dryRun: false,
    authorize: false,
    help: false,
    stateRoot: null,
  };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    switch (a) {
      case '--project-id': args.projectId = argv[++i]; break;
      case '--video-id': args.videoId = argv[++i]; break;
      case '--days': args.days = argv[++i]; break;
      case '--state-root': args.stateRoot = argv[++i]; break;
      case '--dry-run': args.dryRun = true; break;
      case '--authorize': args.authorize = true; break;
      case '-h':
      case '--help': args.help = true; break;
      default:
        return { error: `Unknown argument: ${a}` };
    }
  }
  return { args };
}

const HELP = `fetch-analytics.js — YouTube analytics fetcher (youtube-team-os, NON-48)

USAGE
  node bin/fetch-analytics.js --project-id <id> --video-id <youtube-id> [options]
  node bin/fetch-analytics.js --project-id <id> --dry-run
  node bin/fetch-analytics.js --authorize
  node bin/fetch-analytics.js --help

REQUIRED
  --project-id <id>     Project ID; output goes to analytics-<id>.md
  --video-id <id>       YouTube video ID (required unless --dry-run)

OPTIONS
  --days <n>            Analytics window length in days (default: 28)
  --dry-run             Use fixture data, no network calls
  --state-root <path>   Override state root (default: <repo>/state)
  --authorize           One-time helper to obtain an OAuth refresh token
  -h, --help            Show this help

ENVIRONMENT
  YT_API_KEY               Data API v3 key (enables "public" mode)
  YT_OAUTH_CLIENT_ID       OAuth 2.0 Desktop-app client ID
  YT_OAUTH_CLIENT_SECRET   OAuth 2.0 client secret
  YT_OAUTH_REFRESH_TOKEN   Refresh token (enables "full" mode)
  YT_OS_STATE_ROOT         Alternative to --state-root

  Env vars absent? The script also reads state/secrets/youtube.json
  (git-ignored) with keys: apiKey, clientId, clientSecret, refreshToken.

MODES (auto-selected)
  dry-run  fixture data, no network
  public   YT_API_KEY set: public stats real; watch-time/retention/subs = "${MANUAL}"
  full     API key + refresh token: both Data v3 and Analytics v2 queried

EXIT CODES
  0 success · 1 usage error · 2 API/auth error

Setup guide: connectors/youtube-analytics.md
`;

// ── Config loading ────────────────────────────────────────────────────────────
function loadConfig(stateRoot) {
  const cfg = {
    apiKey: process.env.YT_API_KEY || null,
    clientId: process.env.YT_OAUTH_CLIENT_ID || null,
    clientSecret: process.env.YT_OAUTH_CLIENT_SECRET || null,
    refreshToken: process.env.YT_OAUTH_REFRESH_TOKEN || null,
  };
  const anyEnv = cfg.apiKey || cfg.clientId || cfg.clientSecret || cfg.refreshToken;
  if (!anyEnv) {
    const secretsPath = path.join(stateRoot, 'secrets', 'youtube.json');
    if (fs.existsSync(secretsPath)) {
      try {
        const j = JSON.parse(fs.readFileSync(secretsPath, 'utf8'));
        cfg.apiKey = cfg.apiKey || j.apiKey || null;
        cfg.clientId = cfg.clientId || j.clientId || null;
        cfg.clientSecret = cfg.clientSecret || j.clientSecret || null;
        cfg.refreshToken = cfg.refreshToken || j.refreshToken || null;
      } catch (e) {
        throw new Error(`Failed to parse ${secretsPath}: ${e.message}`);
      }
    }
  }
  return cfg;
}

function pickMode(cfg, dryRun) {
  if (dryRun) return 'dry-run';
  const hasOAuth = cfg.clientId && cfg.clientSecret && cfg.refreshToken;
  if (cfg.apiKey && hasOAuth) return 'full';
  if (cfg.apiKey) return 'public';
  return null; // no usable credentials
}

// ── UTC-safe date math ────────────────────────────────────────────────────────
// This repo had a timezone bug (TM-6); use UTC throughout for date ranges.
function utcDateString(d) {
  // Returns YYYY-MM-DD in UTC
  const y = d.getUTCFullYear();
  const m = String(d.getUTCMonth() + 1).padStart(2, '0');
  const day = String(d.getUTCDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

function dateRange(days, now) {
  const end = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
  const start = new Date(end.getTime() - (days - 1) * 24 * 60 * 60 * 1000);
  return { startDate: utcDateString(start), endDate: utcDateString(end) };
}

// ── Network helpers ───────────────────────────────────────────────────────────
async function getJSON(url, headers) {
  const res = await fetch(url, { headers: headers || {} });
  const text = await res.text();
  let body;
  try { body = text ? JSON.parse(text) : {}; } catch { body = { raw: text }; }
  if (!res.ok) {
    const msg = body && body.error && body.error.message ? body.error.message : text;
    const err = new Error(`HTTP ${res.status}: ${msg}`);
    err.status = res.status;
    throw err;
  }
  return body;
}

async function exchangeRefreshToken(cfg) {
  const params = new URLSearchParams({
    client_id: cfg.clientId,
    client_secret: cfg.clientSecret,
    refresh_token: cfg.refreshToken,
    grant_type: 'refresh_token',
  });
  const res = await fetch(TOKEN_ENDPOINT, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: params.toString(),
  });
  const text = await res.text();
  let body;
  try { body = JSON.parse(text); } catch { body = { raw: text }; }
  if (!res.ok || !body.access_token) {
    const detail = body.error_description || body.error || text;
    throw new Error(
      `OAuth refresh failed (HTTP ${res.status}): ${detail}\n` +
      `  Check YT_OAUTH_CLIENT_ID / _CLIENT_SECRET / _REFRESH_TOKEN.\n` +
      `  Re-run with --authorize to mint a new refresh token.`
    );
  }
  return body.access_token;
}

// ── Data API v3: public stats ─────────────────────────────────────────────────
async function fetchPublicStats(cfg, videoId) {
  const url = `${DATA_API}/videos?part=statistics,snippet&id=${encodeURIComponent(videoId)}&key=${encodeURIComponent(cfg.apiKey)}`;
  const body = await getJSON(url);
  if (!body.items || body.items.length === 0) {
    throw new Error(`No video found for id "${videoId}" (check the video ID and API key).`);
  }
  const item = body.items[0];
  const s = item.statistics || {};
  return {
    title: (item.snippet && item.snippet.title) || null,
    channelId: (item.snippet && item.snippet.channelId) || null,
    viewCount: s.viewCount != null ? Number(s.viewCount) : null,
    likeCount: s.likeCount != null ? Number(s.likeCount) : null,
    commentCount: s.commentCount != null ? Number(s.commentCount) : null,
  };
}

// ── Analytics API v2: watch time / retention / subs ───────────────────────────
async function fetchAnalytics(accessToken, videoId, startDate, endDate) {
  const url = new URL(ANALYTICS_API);
  url.searchParams.set('ids', 'channel==MINE');
  url.searchParams.set('startDate', startDate);
  url.searchParams.set('endDate', endDate);
  url.searchParams.set('metrics', ANALYTICS_METRICS.join(','));
  url.searchParams.set('filters', `video==${videoId}`);
  const body = await getJSON(url.toString(), { Authorization: `Bearer ${accessToken}` });
  const headers = (body.columnHeaders || []).map((h) => h.name);
  const row = (body.rows && body.rows[0]) || [];
  const out = {};
  ANALYTICS_METRICS.forEach((m) => {
    const idx = headers.indexOf(m);
    out[m] = idx >= 0 && row[idx] != null ? Number(row[idx]) : null;
  });
  return out;
}

// ── Fixture (dry-run) ─────────────────────────────────────────────────────────
function fixtureData() {
  return {
    public: {
      title: 'Sample Video (dry-run fixture)',
      channelId: 'UC_dryrun_fixture',
      viewCount: 12345,
      likeCount: 678,
      commentCount: 90,
    },
    analytics: {
      views: 12000,
      estimatedMinutesWatched: 48000,
      averageViewDuration: 240,
      averageViewPercentage: 42.5,
      subscribersGained: 210,
    },
  };
}

// ── Number formatting (deterministic) ─────────────────────────────────────────
function fmtInt(n) {
  return n == null ? MANUAL : Number(n).toLocaleString('en-US');
}
function fmtSeconds(sec) {
  if (sec == null) return MANUAL;
  const s = Math.round(sec);
  const m = Math.floor(s / 60);
  const r = s % 60;
  return `${m}m ${String(r).padStart(2, '0')}s`;
}
function fmtHours(minutes) {
  if (minutes == null) return MANUAL;
  return (minutes / 60).toLocaleString('en-US', { maximumFractionDigits: 1 });
}
function fmtPct(p) {
  if (p == null) return MANUAL;
  return `${Number(p).toLocaleString('en-US', { maximumFractionDigits: 1 })}%`;
}

// ── Snapshot rendering (matches skills/growth/SKILL.md format) ─────────────────
function renderSnapshot({ projectId, title, days, mode, pub, analytics, fetchedAt }) {
  const capturedDate = fetchedAt.slice(0, 10);
  const heading = title || projectId;

  // Analytics-only fields fall back to MANUAL string when unavailable.
  const views = analytics ? fmtInt(analytics.views) : MANUAL;
  const avd = analytics ? fmtSeconds(analytics.averageViewDuration) : MANUAL;
  const watch = analytics ? fmtHours(analytics.estimatedMinutesWatched) : MANUAL;
  const subs = analytics ? fmtInt(analytics.subscribersGained) : MANUAL;
  const avp = analytics ? fmtPct(analytics.averageViewPercentage) : MANUAL;

  const lines = [];
  lines.push(`# Analytics Snapshot: ${heading}`);
  lines.push(`Project: ${projectId}`);
  lines.push(`Captured: ${capturedDate} (${days} days after publish)`);
  lines.push('');
  lines.push('| Metric | Value | vs. channel avg |');
  lines.push('|---|---|---|');
  lines.push(`| Views (${days}d) | ${views} | |`);
  lines.push(`| CTR | ${MANUAL} | |`);
  lines.push(`| Avg view duration | ${avd} | |`);
  lines.push(`| Watch time (hours) | ${watch} | |`);
  lines.push(`| Subscribers gained | ${subs} | |`);
  lines.push(`| Comments | ${fmtInt(pub.commentCount)} | |`);
  lines.push(`| Likes | ${fmtInt(pub.likeCount)} | |`);
  lines.push('');
  lines.push('## Additional metrics');
  lines.push('');
  lines.push('| Metric | Value |');
  lines.push('|---|---|');
  lines.push(`| Public view count (Data API) | ${fmtInt(pub.viewCount)} |`);
  lines.push(`| Avg view percentage | ${avp} |`);
  lines.push(`| Impressions | ${MANUAL} |`);
  lines.push(`| Impressions CTR | ${MANUAL} |`);
  lines.push('');
  lines.push(
    '> CTR and impressions are not exposed by the YouTube Analytics API v2 and must be ' +
    'read from YouTube Studio. See connectors/youtube-analytics.md.'
  );
  lines.push('');
  lines.push('---');
  lines.push(
    `Source: fetch-analytics.js (NON-48) · fetched-at ${fetchedAt} · mode ${mode} · ` +
    `Data API v3 + Analytics API v2 · window ${days}d`
  );
  lines.push('');
  return lines.join('\n');
}

// ── --authorize helper (in-file per Rule of One) ──────────────────────────────
async function runAuthorize(cfg) {
  if (!cfg.clientId || !cfg.clientSecret) {
    console.error(
      'Error: --authorize needs YT_OAUTH_CLIENT_ID and YT_OAUTH_CLIENT_SECRET set\n' +
      '(env vars or state/secrets/youtube.json). See connectors/youtube-analytics.md.'
    );
    return 2;
  }
  const redirectUri = 'http://localhost:8723/';
  const authUrl = new URL(OAUTH_AUTH_ENDPOINT);
  authUrl.searchParams.set('client_id', cfg.clientId);
  authUrl.searchParams.set('redirect_uri', redirectUri);
  authUrl.searchParams.set('response_type', 'code');
  authUrl.searchParams.set('scope', SCOPES.join(' '));
  authUrl.searchParams.set('access_type', 'offline');
  authUrl.searchParams.set('prompt', 'consent');

  console.log('\n1. Open this URL in a browser and approve access:\n');
  console.log('   ' + authUrl.toString() + '\n');
  console.log('2. Waiting for the redirect on ' + redirectUri + ' ...\n');

  const code = await new Promise((resolve, reject) => {
    const server = http.createServer((req, res) => {
      try {
        const u = new URL(req.url, redirectUri);
        const c = u.searchParams.get('code');
        const err = u.searchParams.get('error');
        res.writeHead(200, { 'Content-Type': 'text/plain' });
        if (c) {
          res.end('Authorization received. You can close this tab and return to the terminal.');
          server.close();
          resolve(c);
        } else {
          res.end('No code received' + (err ? `: ${err}` : '') + '. Check the terminal.');
        }
      } catch (e) {
        res.writeHead(500); res.end('error');
        server.close();
        reject(e);
      }
    });
    server.on('error', reject);
    server.listen(8723);
  });

  const params = new URLSearchParams({
    client_id: cfg.clientId,
    client_secret: cfg.clientSecret,
    code,
    redirect_uri: redirectUri,
    grant_type: 'authorization_code',
  });
  const res = await fetch(TOKEN_ENDPOINT, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: params.toString(),
  });
  const body = await res.json().catch(() => ({}));
  if (!res.ok || !body.refresh_token) {
    console.error(
      `Token exchange failed (HTTP ${res.status}): ` +
      (body.error_description || body.error || 'no refresh_token returned') +
      '\nEnsure the OAuth client is a "Desktop app" type and consent was granted.'
    );
    return 2;
  }
  console.log('\nSuccess. Save this refresh token as YT_OAUTH_REFRESH_TOKEN');
  console.log('(or refreshToken in state/secrets/youtube.json):\n');
  console.log('   ' + body.refresh_token + '\n');
  return 0;
}

// ── Main ──────────────────────────────────────────────────────────────────────
async function main() {
  const { args, error } = parseArgs(process.argv.slice(2));
  if (error) {
    console.error(error);
    console.error('Run with --help for usage.');
    return 1;
  }
  if (args.help) {
    process.stdout.write(HELP);
    return 0;
  }

  // Resolve state root: --state-root > YT_OS_STATE_ROOT > <repo>/state
  const repoRoot = path.dirname(__dirname); // bin/ -> repo root
  const stateRoot = args.stateRoot || process.env.YT_OS_STATE_ROOT || path.join(repoRoot, 'state');

  let cfg;
  try {
    cfg = loadConfig(stateRoot);
  } catch (e) {
    console.error(e.message);
    return 2;
  }

  if (args.authorize) {
    return await runAuthorize(cfg);
  }

  // Validate required args
  if (!args.projectId) {
    console.error('Error: --project-id is required.');
    console.error('Run with --help for usage.');
    return 1;
  }
  const days = Number(args.days);
  if (!Number.isInteger(days) || days < 1) {
    console.error(`Error: --days must be a positive integer (got "${args.days}").`);
    return 1;
  }
  if (!args.dryRun && !args.videoId) {
    console.error('Error: --video-id is required unless --dry-run is set.');
    return 1;
  }

  const mode = pickMode(cfg, args.dryRun);
  if (mode === null) {
    console.error(
      'Error: no usable credentials. Set YT_API_KEY (public mode) or full OAuth,\n' +
      'or use --dry-run. See connectors/youtube-analytics.md.'
    );
    return 2;
  }

  const now = new Date();
  const { startDate, endDate } = dateRange(days, now);
  const fetchedAt = now.toISOString();

  let pub, analytics;
  try {
    if (mode === 'dry-run') {
      const fx = fixtureData();
      pub = fx.public;
      analytics = fx.analytics;
    } else {
      pub = await fetchPublicStats(cfg, args.videoId);
      if (mode === 'full') {
        const accessToken = await exchangeRefreshToken(cfg);
        analytics = await fetchAnalytics(accessToken, args.videoId, startDate, endDate);
      } else {
        analytics = null; // public mode: OAuth-only fields become MANUAL
      }
    }
  } catch (e) {
    console.error(`API/auth error: ${e.message}`);
    return 2;
  }

  const content = renderSnapshot({
    projectId: args.projectId,
    title: pub.title,
    days,
    mode,
    pub,
    analytics,
    fetchedAt,
  });

  const recordsDir = path.join(stateRoot, 'records');
  fs.mkdirSync(recordsDir, { recursive: true });
  const outPath = path.join(recordsDir, `analytics-${args.projectId}.md`);
  fs.writeFileSync(outPath, content, 'utf8');

  console.log(`[yt-os] Wrote ${outPath} (mode: ${mode}, window: ${days}d)`);
  if (mode === 'public') {
    console.log('[yt-os] Watch-time, retention, and subscriber fields marked "' + MANUAL + '".');
    console.log('[yt-os] Configure OAuth for full mode — see connectors/youtube-analytics.md.');
  }
  return 0;
}

main()
  .then((code) => process.exit(code))
  .catch((e) => {
    console.error(`Unexpected error: ${e && e.stack ? e.stack : e}`);
    process.exit(2);
  });
