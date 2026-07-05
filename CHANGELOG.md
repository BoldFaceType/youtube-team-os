# Changelog

All notable changes to `youtube-team-os` will be documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Changed
- `skills/producer/SKILL.md` + `agents/producer.md` — replaced the blind idea-generation
  step with an evidence-based **Idea Sourcing & Validation** workflow (NON-56): (1) read
  internal `state/projects/*/postmortem.md` / `state/records/analytics-*.md` evidence
  first, degrading gracefully on a fresh install (state the absence in the brief, never
  block); (2) external demand signals per candidate — search-intent check + comparable-
  channel outlier scan; (3) packaging-first gate — working title + thumbnail concept
  required before a candidate is selectable; (4) 1–5 scoring rubric across demand
  evidence / differentiation / channel fit / effort-to-payoff, with the selection reason
  citing scores; (5) unselected candidates ≥14/20 appended to `state/notes/idea-bank.md`.
  Both files describe the same workflow (TM-10 two-source-of-truth rule); practice
  sources are cited in an HTML comment inside the SKILL's ideation section.

### Added
- `state/notes/idea-bank.md` — seed table (title, thumbnail concept, scores, evidence)
  plus usage/kill-criteria note, so high-scoring unselected candidates compound across
  producer runs (NON-56).

### Fixed
- `monitors/monitors.json` — was built on a schema that doesn't match the real Claude Code
  plugin spec (wrapped object with invented `trigger`/`timeout`/`failureMode` fields, and
  one-shot scripts instead of persistent watchers). Emptied to a valid `[]`; the deadline
  and postmortem-due reminder checks now run from `hooks/hooks.json`'s `SessionStart` hooks
  instead (TM-1, NON-46).
- `.mcp.json` — the `youtube` server referenced a package that doesn't exist on npm
  (`@modelcontextprotocol/server-youtube`, 404); the `drive` server referenced a package npm
  marks "no longer supported". Emptied to `{"mcpServers": {}}`. YouTube analytics is now
  manual-input (see `connectors/youtube-metadata.md`); Drive sync uses the existing
  rclone-based `bin/sync-state.ps1`/`.sh` instead of MCP (see `connectors/drive.md`)
  (TM-2, NON-39).
- `hooks/hooks.json` — the `PostToolUse` write-audit hook silently wrote a blank log line if
  `jq` was missing; it now writes an explicit `jq-missing` sentinel line instead (TM-3,
  NON-40).
- All `SessionStart`/`PostToolUse`/`Stop`/`SessionEnd` hook commands now defensively
  `mkdir -p state/records` before writing, so they no longer silently no-op if that
  directory doesn't exist yet (part of the New-3 fresh-clone fix, landed here since it
  touches the same hook command strings as the two fixes above).
- `state/notes/content-calendar.md` — seed header only had 4 columns
  (`Project ID | Title | Target Date | Stage`) while every script and skill/agent doc that
  writes to it uses 5 (adds `Owner`), and `monitors/check-deadlines.js`'s regex requires
  5 columns to match a row at all. Header now matches (TM-4, NON-41).
- `state/projects/`, `state/records/` were untracked in git — a fresh clone would be
  missing these directories entirely, causing the SessionStart/PostToolUse/Stop/SessionEnd
  hooks to silently no-op and `bin/validate.ps1` to fail its own state-filesystem check on
  a pristine checkout. Added `.gitkeep` to both (New-3). Deleted `state/deliverables/`
  (was empty, untracked, and referenced nowhere in any doc, skill, or agent file —
  superseded by `state/projects/<id>/*.md`).
- `bin/validate.ps1` — extended to check the hooks-based monitor wiring (replacing the
  removed monitors.json checks), presence of `bin/*.ps1`/`bin/*.sh` and
  `connectors/*.md`, and Node.js/rclone availability, none of which were previously
  checked despite being listed in `README.md`'s Requirements (TM-5, New-6, NON-42).
- `monitors/check-deadlines.js` and `check-postmortem-due.js` — both parsed calendar/
  activity-log dates via `new Date(str)` (UTC midnight) followed by `.setHours(0,0,0,0)`
  (local time), which silently shifts the effective date back a day in any timezone
  behind UTC (TM-6). Found live by `bin/smoke-test.ps1`'s TZ=America/New_York assertion
  during this remediation, not just by static review — the original plan only scheduled
  a *regression test* for this, not a fix, which was an oversight caught by actually
  running the new test. Both now parse `YYYY-MM-DD` components directly into a
  local-midnight `Date`, matching `today`'s construction.

### Added
- `bin/smoke-test.ps1` — deterministic mechanical regression test: validate.ps1,
  new-project scaffolding (including the TM-4 column-count regression), the actual
  `hooks.json` command strings (including the TM-3 jq-missing sentinel), and the two
  monitor scripts under both the default and a non-UTC timezone (TM-6 regression).
  Supports `-InjectFailure` (proves the test fails when something is actually broken)
  and `-KeepScratch` (debugging). Does not and cannot exercise the 6 role
  skills/agents — those are LLM-executed instructions, not deterministic code.
- `bin/new-project.ps1`/`.sh` — added a `-StateRoot`/positional override so tests (and
  any future automation) can scaffold into a fixture directory instead of the real
  `state/` tree.
- `tests/fixtures/state/` — static, non-date-sensitive example fixture (one project at
  the PUBLISH stage) for reference; the actual date-sensitive smoke-test assertions
  generate their own fixtures at run time since a checked-in fixed date would go stale.
- `tests/e2e-runbook.md` — documented manual procedure for running the full 6-role
  pipeline headlessly (`claude -p`) against a scratch project directory, with a
  pass/fail checklist. Deliberately a manual runbook, not a CI job (real API cost, and
  pass/fail is a human judgment call on deliverable quality, not a hard assertion).
- `bin/sync-state.sh` — Mac/Linux port of `sync-state.ps1` (rclone-based Drive sync);
  closes the last Windows-only script gap (New-4, NON-36).
- `bin/validate.sh` — Mac/Linux port of `validate.ps1`, kept in parity via CI (see below).
- `LICENSE` — MIT, matching `plugin.json`'s existing `license` field, which had no
  corresponding file (TM-8).
- `README.md` — added a Testing section (closes the dangling reference from
  `CLAUDE.md`, New-5) and a contributor note about `skills/`/`agents/` duplication
  (TM-10).
- `.github/workflows/validate.yml` — runs `validate.ps1`, `validate.sh`, and
  `smoke-test.ps1` (including a `-InjectFailure` self-check) on every push/PR to `main`.
  Deliberately does not run `tests/e2e-runbook.md` — see that file for why.

### Fixed (cont.)
- `.claude-plugin/plugin.json` — `homepage` pointed at `github.com/jtisby/...`; the
  actual git remote and `CHANGELOG.md`'s own compare links use
  `github.com/BoldFaceType/...`. Aligned (TM-7). Removed `minClaudeCodeVersion` — not a
  field in the official plugin manifest schema (checked 3 ways via Context7); likely
  silently ignored, but dead/invented metadata (TM-9). `settings.json`'s `agent` field
  was checked against the same schema and confirmed genuinely documented — no change
  needed there.

### Planned
- Weekly planning cron via Claude Code scheduled task (NON-35)
- Community marketplace submission (NON-37)
- Rewrite `connectors/mcp-setup.md` guidance once a real, maintained YouTube MCP server is
  identified (superseded interim guidance already shipped — see Fixed above)

---

## [1.2.0] — 2026-07-05

### Added
- `bin/fetch-analytics.js` — plain-script YouTube analytics fetcher (NON-48). Single
  file, **zero npm dependencies**, Node >= 18 (built-in `fetch`). Fetches per-video
  public stats from the YouTube Data API v3 (`videos.list?part=statistics`) and, when
  OAuth is configured, watch-time / retention / subscriber metrics from the YouTube
  Analytics API v2 (`reports.query`, `ids=channel==MINE`, `filters=video==<id>`), then
  writes `state/records/analytics-<project-id>.md` in the growth SKILL snapshot format
  with a `Source:` footer (fetched-at timestamp, mode, API versions). Three modes:
  `--dry-run` (fixture, no network), `public` (API key only; OAuth-only fields written
  as `manual (YouTube Studio)`), and `full` (both APIs). Includes an in-file
  `--authorize` refresh-token helper (Rule of One — no second script). UTC-safe date
  math throughout, guarding against the TM-6 timezone class of bug. Exit codes: 0 / 1
  usage / 2 API-auth.
- `connectors/youtube-analytics.md` — setup guide: GCP project, enabling both APIs,
  API-key + OAuth Desktop-app client creation, one-time refresh-token acquisition via
  `--authorize`, env-var reference, per-mode fetch table, and an honest limitations
  table. **Verified verdict:** `impressions` and `impressionsClickThroughRate` are NOT
  exposed by the Analytics API v2 (Studio-only), citing the metrics reference (updated
  2026-05-11); the script marks CTR/Impressions `manual (YouTube Studio)` accordingly.

### Changed
- Design decision: analytics capture is now a **plain, dependency-free Node script**
  rather than an MCP connector. This **supersedes the canceled MCP-connector approach
  (NON-33)** and the manual-input-only fallback in `connectors/youtube-metadata.md`.
  No runtime npm dependencies were introduced, keeping the plugin install-free.
- `.gitignore` — added `state/secrets/` so the optional git-ignored
  `state/secrets/youtube.json` credentials fallback is never committed.

---

## [1.1.0] — 2026-07-01

### Added
- `CLAUDE.md` — project context, role routing table, state conventions, hard rules for Claude Code sessions
- `.mcp.json` — YouTube Data API v3 + Google Drive MCP server configs (fact-checked against official Claude Code spec)
- `connectors/mcp-setup.md` — step-by-step MCP setup with API key, OAuth, and test commands
- `agents/orchestrator.md` — routes work, scaffolds projects, weekly planning (NON-32)
- `agents/producer.md` — idea scoring, brief writing, calendar management
- `agents/writer.md` — hook rules, script formatting conventions, pacing targets
- `agents/editor.md` — pacing audit format, retention checkpoints, chapter marker spec
- `agents/thumbnail.md` — 5-dimension concept format, CTR scoring, title variant rules
- `agents/growth.md` — publish plan, repurposing spec, postmortem template, YouTube MCP usage
- `bin/new-project.ps1` — Windows script: scaffold project folder, update calendar, post to inbox (NON-34)
- `bin/new-project.sh` — Mac/Linux equivalent of new-project.ps1
- `bin/validate.ps1` — plugin health check: manifest, required files, .mcp.json, hooks, jq dependency, state dirs
- `bin/sync-state.ps1` — rclone-based state sync to Google Drive
- `monitors/monitors.json` — deadline, stale inbox, and postmortem-due monitors (NON-38)
- `monitors/check-deadlines.js` — parses content calendar, warns on projects due within 3 days
- `monitors/check-postmortem-due.js` — detects published videos 28–32 days old needing postmortem
- `resources/best-practices/youtube-production.md` — hook, retention, CTR, SEO, publish timing best practices
- `resources/best-practices/claude-code-skills.md` — SKILL.md authoring spec, common mistakes, testing guide
- `resources/metrics/youtube-kpis.md` — CTR, AVD, retention, engagement rate benchmarks with grade scale
- `resources/links/tools-and-resources.md` — 50+ curated links: YouTube, SEO, design, analytics, automation, learning

### Fixed
- `hooks/hooks.json` — corrected jq path from `.file_path` to `.tool_input.file_path` (confirmed via Context7 official docs)

---

## [1.0.0] — 2026-07-01

### Added
- `.claude-plugin/plugin.json` — Anthropic-spec plugin manifest
- `settings.json` — sets orchestrator as default agent
- `hooks/hooks.json` — SessionStart/Stop logging + PostToolUse Write/Edit file audit trail
- `skills/orchestrator/SKILL.md` — routes work, scaffolds project folders, weekly planning
- `skills/producer/SKILL.md` — idea selection, content brief, calendar management
- `skills/writer/SKILL.md` — outline, script, hook rules, B-roll cues, editor handoff
- `skills/editor/SKILL.md` — pacing audit, cut list, chapter markers, thumbnail handoff
- `skills/thumbnail/SKILL.md` — 3 thumbnail concepts, title variants, CTR audit
- `skills/growth/SKILL.md` — publish plan, repurposing, analytics capture, postmortem
- `workflows/idea-to-upload.md` — full pipeline diagram (INTAKE → POSTMORTEM)
- `workflows/weekly-planning.md` — Monday planning procedure
- `workflows/postmortem.md` — 30-day retrospective workflow
- `prompts/video-brief.md` — intake prompt template
- `prompts/release-checklist.md` — pre-upload checklist
- `resources/templates/brief-template.md` — content brief template
- `resources/templates/script-template.md` — script template
- `resources/scoring/ctr-audit.md` — thumbnail CTR scoring rubric (5 dimensions, /25)
- `connectors/youtube-metadata.md` — YouTube Data API v3 connector spec
- `connectors/drive.md` — Google Drive connector spec
- `schedules/cron.md` — weekly planning and analytics cron expressions
- `state/` filesystem seeded — role inboxes, notes, records
- `README.md` — install, usage, and structure docs

[Unreleased]: https://github.com/BoldFaceType/youtube-team-os/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/BoldFaceType/youtube-team-os/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/BoldFaceType/youtube-team-os/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/BoldFaceType/youtube-team-os/releases/tag/v1.0.0
