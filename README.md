# youtube-team-os

A Claude Code / Cowork plugin that runs a full 5-role YouTube production OS inside your project directory.

## What it does

Orchestrates five specialist roles — producer, writer, editor, thumbnail designer, and growth manager — through a persistent filesystem-based project state. One command starts a video; the system hands off between roles, preserves all deliverables, and runs postmortems.

## Skills

| Skill | Invoke | Purpose |
|---|---|---|
| orchestrator | `/youtube-team-os:orchestrator` | Route work, create projects, weekly planning |
| producer | `/youtube-team-os:producer` | Idea selection, content brief, calendar |
| writer | `/youtube-team-os:writer` | Outline, script, hook, B-roll cues |
| editor | `/youtube-team-os:editor` | Pacing, cut list, edit notes, chapters |
| thumbnail | `/youtube-team-os:thumbnail` | Thumbnail concepts, title variants, CTR audit |
| growth | `/youtube-team-os:growth` | Publish plan, repurposing, analytics, postmortem |

## Quick Start

```bash
# Install (dev mode)
claude --plugin-dir ./youtube-team-os

# Start a new video
/youtube-team-os:orchestrator "10 pricing mistakes SaaS founders make"

# Resume an existing project
/youtube-team-os:orchestrator 2026-06-ep14-pricing

# Weekly planning
/youtube-team-os:orchestrator plan week
```

## Project State

All work lives in `state/`:

```
state/
  projects/<id>/          ← one folder per video
    brief.md
    outline.md
    script.md
    edit-notes.md
    thumbnail-options.md
    publish-plan.md
    postmortem.md
    status.md
    activity.log
  roles/<role>/           ← per-role task queue
    inbox.md
    current.md
  notes/
    content-calendar.md
    channel-learnings.md
    weekly-plan-*.md
  records/
    session.log
    writes.log
    analytics-<id>.md
```

## Workflows

- `workflows/idea-to-upload.md` — full pipeline diagram
- `workflows/weekly-planning.md` — Monday planning procedure
- `workflows/postmortem.md` — 30-day retrospective

## Hooks

`hooks/hooks.json` logs session starts/ends and every file write to `state/records/`.

## Connectors

- `connectors/youtube-metadata.md` — YouTube Data API v3 via MCP
- `connectors/drive.md` — Google Drive for asset sharing

## Install from marketplace

```
/plugin install <marketplace>/youtube-team-os
```

## Requirements

- Claude Code v2.1.0+
- Node.js (for bin/ scripts, optional)
- YouTube Data API key (for YouTube connector, optional)
