# Changelog

All notable changes to `youtube-team-os` will be documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Planned
- Weekly planning cron via Claude Code scheduled task (NON-35)
- Google Drive connector and deliverable sync (NON-36)
- Community marketplace submission (NON-37)

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

[Unreleased]: https://github.com/BoldFaceType/youtube-team-os/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/BoldFaceType/youtube-team-os/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/BoldFaceType/youtube-team-os/releases/tag/v1.0.0
