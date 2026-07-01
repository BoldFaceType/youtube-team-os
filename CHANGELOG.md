# Changelog

All notable changes to `youtube-team-os` will be documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Planned
- `agents/` definitions for all 6 roles (NON-32)
- YouTube Data API v3 MCP connector via `.mcp.json` (NON-33)
- `bin/new-project` scaffolding script (NON-34)
- Weekly planning cron via Claude Code scheduled task (NON-35)
- `monitors/monitors.json` for content calendar deadline alerts (NON-38)
- Google Drive connector and deliverable sync (NON-36)
- Community marketplace submission (NON-37)

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

[Unreleased]: https://github.com/BoldFaceType/youtube-team-os/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/BoldFaceType/youtube-team-os/releases/tag/v1.0.0
