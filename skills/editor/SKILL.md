---
name: editor
description: >
  Use when reviewing a script for pacing, creating a cut list, writing edit notes,
  or generating a retention-optimized edit plan for a specific project. Invoke with
  /youtube-team-os:editor. Do not use for scripting (→ writer) or thumbnail/publishing work.
routing_links:
  primary:
    - youtube-team-os:editor
  related:
    - youtube-team-os:writer
    - youtube-team-os:thumbnail
  avoid:
    - youtube-team-os:producer
    - youtube-team-os:growth
---

# Editor

## Purpose
Convert a completed script into a structured edit plan with pacing notes, cut list, and retention checkpoints.

## Use When
- Script exists and is ready for edit planning
- Reviewing a rough cut for pacing issues
- Creating chapter markers or timestamps
- Identifying dead air, slow sections, or missing B-roll
- Writing color grade notes or audio flags

## Do Not Use When
- Script doesn't exist yet (→ writer)
- Task is thumbnail or distribution (→ thumbnail, growth)

## Inputs
- `$ARGUMENTS`: project ID or specific edit note request
- `state/roles/editor/inbox.md`
- `state/projects/<id>/script.md`
- `state/projects/<id>/outline.md`

## Outputs
- `state/projects/<id>/edit-notes.md`
- `state/roles/thumbnail/inbox.md` — handoff with project ID

## Procedure

### 1. Load script
Read `state/projects/<id>/script.md`. Note total word count and estimated runtime.

### 2. Pacing audit
Walk each section. Flag:
- **Dead zones**: intro longer than 60s, sections with no visual change for >45s
- **Hook risk**: anything before the core tension/hook
- **Transition gaps**: abrupt section jumps with no visual or audio bridge
- **Energy dips**: long monologue blocks with no B-roll, graphic, or cut

### 3. Write edit notes
Create `state/projects/<id>/edit-notes.md`:

```markdown
# Edit Notes: <Title>
Project: <id>
Script draft: <N>
Estimated runtime: <X> min

## Pacing Summary
- Hook: [STRONG / AT RISK / WEAK] — reason
- Average section length: ~<N> sec
- Longest uncut block: [Section name] at ~<N> sec — flag if >60s

## Cut List
| Section | Action | Note |
|---|---|---|
| Hook | Keep tight | Cut to <3 sentences on screen |
| Intro | Trim | Remove sentence: "In this video we'll..." |
| Section 2 | Add B-roll | Needs visual every 30s |
| ... | | |

## Retention Checkpoints
Place restatement or tease at:
- ~2:00 —
- ~4:00 —
- ~7:00 —

## B-Roll Gaps
List script lines that need visual coverage but have no `[B-roll]` cue:
-

## Chapter Markers (YouTube timestamps)
- 0:00 — Hook
- 0:30 — Intro
- <timestamp> — <Section name>
...

## Audio / Technical Flags
-

## Color / Grade Notes
-
```

### 4. Handoff to thumbnail
Write to `state/roles/thumbnail/inbox.md`:
```
task: Create thumbnail options and title variants
project: <id>
edit-notes: state/projects/<id>/edit-notes.md
script: state/projects/<id>/script.md
priority: normal
added: <ISO date>
```

Update `state/projects/<id>/status.md` → Stage: EDIT → complete.

## Quality Gates
- Hook assessment completed
- Cut list has at least one entry per script section
- Retention checkpoints placed at ≤2-min intervals
- B-roll gaps listed
- Chapter markers generated
- Thumbnail role inbox updated

## Failure Modes
| Failure | Correction |
|---|---|
| No B-roll in script | Flag every abstract claim; note [needs visual] |
| Hook longer than 30s | Create specific trim instruction in cut list |
| No retention checkpoints | Insert tease lines at 2, 4, 7 min marks in cut list |
| Script not found | Ping orchestrator; block until writer completes |
