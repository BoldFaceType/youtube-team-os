---
name: producer
description: >
  Use when selecting video ideas, writing a content brief, building the content calendar,
  or setting channel priorities. Invoke with /youtube-team-os:producer. Do not use for
  scripting, editing, thumbnails, or distribution — those belong to other roles.
routing_links:
  primary:
    - youtube-team-os:producer
  related:
    - youtube-team-os:orchestrator
    - youtube-team-os:writer
  avoid:
    - youtube-team-os:editor
    - youtube-team-os:thumbnail
    - youtube-team-os:growth
---

# Producer / Strategist

## Purpose
Select video ideas, write content briefs, and manage the channel content calendar.

## Use When
- Generating or evaluating video ideas
- Writing a brief for a specific project
- Building or updating the content calendar
- Defining the angle, audience, and goal for a video
- Setting channel-level priorities and theme direction

## Do Not Use When
- Script is already briefed (→ writer)
- Task is about editing, thumbnails, or publishing

## Inputs
- `$ARGUMENTS`: idea prompt, topic, or project ID
- `state/roles/producer/inbox.md`
- `state/projects/<id>/brief.md` (if resuming)
- `resources/templates/brief-template.md`

## Outputs
- `state/projects/<id>/brief.md` — completed content brief
- `state/notes/content-calendar.md` — updated calendar entry
- `state/roles/writer/inbox.md` — task handoff with project ID

## Procedure

### 1. Load context
Read `state/roles/producer/inbox.md`. Extract the current task and project ID.
If the brief already exists at `state/projects/<id>/brief.md`, load it. Otherwise create it from the template.

### 2. Idea selection (if needed)
When the input is an idea prompt or broad topic, generate 3–5 candidate video angles. For each:
- Working title
- Core angle / hook
- Target audience segment
- Estimated search intent (informational / inspirational / entertaining)
- Rough differentiation from existing channel videos

Write candidates to `state/projects/<id>/brief.md` under `## Idea Candidates`.

### 3. Select and commit
Pick or confirm one angle. Write the full brief:

```markdown
# Content Brief: <Title>
Project: <id>
Date: <YYYY-MM-DD>
Stage: BRIEF

## Core Angle
<One sentence — what is this video really about?>

## Target Viewer
<Who is this for? What do they already know? What do they want?>

## Hook
<Opening 30 seconds — what makes someone stay?>

## Key Points (3–5)
1.
2.
3.

## Call to Action
<What should the viewer do after watching?>

## SEO / Discovery Notes
<Primary keyword, secondary keywords, thumbnail keyword>

## Channel Fit
<How does this serve the channel's current priorities?>

## Success Criteria
- Views target (30-day):
- CTR target:
- Retention target:
- Comments goal:
```

### 4. Calendar update
Append to `state/notes/content-calendar.md`:
```
| <id> | <Title> | <Target publish date> | BRIEF |
```

### 5. Handoff to writer
Write to `state/roles/writer/inbox.md`:
```
task: Write outline and script
project: <id>
brief: state/projects/<id>/brief.md
priority: normal
added: <ISO date>
```

Update `state/projects/<id>/status.md` → Stage: BRIEF → complete.

## Quality Gates
- Brief has all sections populated
- Angle is stated in one sentence
- Hook is concrete, not vague
- Calendar entry added
- Writer inbox updated

## Failure Modes
| Failure | Correction |
|---|---|
| Too many angles, none chosen | Force selection; defer others to future brief |
| Hook is generic | Rewrite with specific tension or curiosity gap |
| No SEO notes | Add at least one primary keyword |
