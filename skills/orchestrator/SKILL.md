---
name: orchestrator
description: >
  Use when starting or resuming any YouTube production task. Routes requests to the
  correct role (producer, writer, editor, thumbnail, growth), creates project folders,
  manages task handoffs, and maintains a consistent project state. Invoke with
  /youtube-team-os:orchestrator. Do not use for single-role tasks you already know
  the target for — call the role skill directly instead.
routing_links:
  primary:
    - youtube-team-os:orchestrator
  related:
    - youtube-team-os:producer
    - youtube-team-os:writer
    - youtube-team-os:editor
    - youtube-team-os:thumbnail
    - youtube-team-os:growth
  avoid:
    - general-documentation
    - one-off-answer
---

# Orchestrator

## Purpose
Route YouTube production work to the correct role, scaffold project state, and track cross-role handoffs.

## Use When
- Starting a new video project
- Resuming an in-progress project
- Unclear which role owns a task
- Running a multi-role workflow (e.g., ideation through publishing)
- Weekly planning or postmortem review

## Do Not Use When
- You already know the target role — call it directly
- The request is a one-off question with no state to persist

## Inputs
- `$ARGUMENTS`: project ID, video title, or free-text request
- Existing project folders in `state/projects/`

## Outputs
- Project folder scaffolded at `state/projects/<project-id>/`
- Role task files updated in `state/roles/<role>/inbox.md`
- Updated `state/projects/<project-id>/status.md`

## Procedure

### 1. Resolve project
Check if `$ARGUMENTS` matches an existing project folder under `state/projects/`.
- If yes: load `state/projects/<id>/status.md` to resume.
- If no: create a new project. Generate an ID as `YYYY-MM-<slug>` (e.g., `2026-06-ep14-pricing`). Scaffold the folder:

```
state/projects/<id>/
  brief.md
  outline.md
  script.md
  edit-notes.md
  thumbnail-options.md
  publish-plan.md
  postmortem.md
  status.md
  activity.log
```

Write initial `status.md`:
```
# <Title>
ID: <id>
Created: <date>
Stage: INTAKE
Roles active: none
```

### 2. Classify the request
Map the request to one or more roles:

| Intent | Role |
|---|---|
| Idea, angle, calendar, brief | producer |
| Script, hook, outline, research | writer |
| Pacing, cut list, edit notes | editor |
| Thumbnail, title, packaging | thumbnail |
| Distribution, repurposing, analytics | growth |
| Retrospective, postmortem | orchestrator |
| Weekly planning | orchestrator → all roles |

### 3. Dispatch to role
Write the task into the target role's inbox:

```
state/roles/<role>/inbox.md
---
task: <description>
project: <id>
priority: <high|normal>
added: <ISO date>
---
```

Then invoke the appropriate skill: `/youtube-team-os:<role>`

### 4. Track progress
After each role completes, update `state/projects/<id>/status.md`:
- Set the current stage
- Note which deliverable was produced
- Log entry in `activity.log`

Stages in order: INTAKE → BRIEF → OUTLINE → SCRIPT → EDIT → THUMBNAIL → PUBLISH → POSTMORTEM

### 5. Weekly planning mode
When asked to plan the week:
1. List all open projects in `state/projects/` where `status.md` shows an incomplete stage.
2. List all role inboxes with pending items.
3. Produce `state/notes/weekly-plan-<YYYY-WNN>.md` with priorities.

## Quality Gates
- Every project has a folder and a `status.md`
- No role receives a task without a project ID
- Stage transitions are logged to `activity.log`
- Deliverables are named and placed correctly before advancing stage

## Failure Modes
| Failure | Correction |
|---|---|
| No project ID provided | Generate one from title/date |
| Ambiguous role assignment | Assign to producer for intake |
| Missing deliverable from previous stage | Block advance; re-dispatch to prior role |
| state/ folder missing | Create it; log warning to records/session.log |
