# Workflow: Idea → Upload

## Overview
End-to-end pipeline for a single video from raw idea to live on YouTube.

## Stages & Handoffs

```
[INTAKE]
  → /youtube-team-os:orchestrator "<idea or topic>"
  → Creates: state/projects/<id>/

[BRIEF]
  → /youtube-team-os:producer
  → Produces: state/projects/<id>/brief.md
  → Hands off to: writer inbox

[OUTLINE + SCRIPT]
  → /youtube-team-os:writer
  → Produces: state/projects/<id>/outline.md, script.md
  → Hands off to: editor inbox

[EDIT NOTES]
  → /youtube-team-os:editor
  → Produces: state/projects/<id>/edit-notes.md
  → Hands off to: thumbnail inbox

[THUMBNAIL + TITLE]
  → /youtube-team-os:thumbnail
  → Produces: state/projects/<id>/thumbnail-options.md
  → Hands off to: growth inbox

[PUBLISH PLAN]
  → /youtube-team-os:growth
  → Produces: state/projects/<id>/publish-plan.md

[LIVE → 30 DAYS]
  → /youtube-team-os:growth <id>
  → Produces: state/records/analytics-<id>.md
             state/projects/<id>/postmortem.md
```

## Resume Protocol
At any stage: `/youtube-team-os:orchestrator <id>` to reload status and dispatch next step.

## Abort / Pause
Set `state/projects/<id>/status.md` stage to `PAUSED`. Orchestrator skips paused projects in weekly planning.
