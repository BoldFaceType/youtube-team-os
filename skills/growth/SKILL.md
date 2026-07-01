---
name: growth
description: >
  Use when building a publish plan, repurposing content, writing community posts,
  reviewing analytics, or running a postmortem for a completed video. Invoke with
  /youtube-team-os:growth. Do not use for scripting, editing, or thumbnail work.
routing_links:
  primary:
    - youtube-team-os:growth
  related:
    - youtube-team-os:thumbnail
    - youtube-team-os:orchestrator
  avoid:
    - youtube-team-os:writer
    - youtube-team-os:editor
---

# Growth / Community Manager

## Purpose
Maximize video reach through a structured publish plan, repurposing workflow, community engagement, and analytics capture.

## Use When
- Building the distribution and publishing plan for a video
- Writing repurposed clips, Shorts descriptions, community posts, or email blurbs
- Scheduling or planning posting cadence
- Capturing analytics snapshots for retrospectives
- Preparing the postmortem after a video has been live 30 days

## Do Not Use When
- Video isn't ready for publishing (no thumbnail confirmed)
- Task is creative content — script, edit, or thumbnail (→ those roles)

## Inputs
- `$ARGUMENTS`: project ID, analytics data, or distribution request
- `state/roles/growth/inbox.md`
- `state/projects/<id>/brief.md`
- `state/projects/<id>/script.md`
- `state/projects/<id>/thumbnail-options.md`

## Outputs
- `state/projects/<id>/publish-plan.md`
- `state/projects/<id>/postmortem.md` (at 30-day mark)
- `state/records/analytics-<id>.md`

## Procedure

### 1. Build publish plan
Create `state/projects/<id>/publish-plan.md`:

```markdown
# Publish Plan: <Title>
Project: <id>
Planned publish date: <YYYY-MM-DD HH:MM timezone>

## Upload Checklist
- [ ] Final video file uploaded
- [ ] Thumbnail selected and uploaded (Concept <X> from thumbnail-options.md)
- [ ] Title set: "<chosen title>"
- [ ] Description written (see below)
- [ ] Tags added (see below)
- [ ] End screen configured
- [ ] Cards added (if applicable)
- [ ] Chapters/timestamps added to description
- [ ] Premiere or publish scheduled

## YouTube Description
<Title>

<2–3 sentence hook that mirrors the thumbnail promise>

Chapters:
<paste from edit-notes.md chapter markers>

Links:
- Subscribe: <channel link>
- <Resource 1>: <URL>

<Primary keyword> | <Secondary keyword> | <Category keyword>

## Tags
<tag1>, <tag2>, <tag3>, ... (10–15 total, mix broad and specific)

## Repurposing Plan
| Format | Platform | Key moment | Status |
|---|---|---|---|
| Short (60s) | YouTube Shorts / TikTok / Reels | <timestamp – moment> | pending |
| Quote card | Twitter/X / Instagram | "<pull quote>" | pending |
| Community post | YouTube Community | <teaser question> | pending |
| Email blurb | Newsletter | <one-line value prop> | pending |

## Community Post Draft
<Question or teaser tied to the video's hook, ≤150 words>

## Email Blurb Draft
Subject: <curiosity-gap subject line>
Body: <2–3 sentences, CTA to watch>
```

### 2. Repurposing drafts
For each format in the repurposing plan, draft the copy inline or in a linked note. Shorts/clips should have: hook (first 3 seconds), value delivery, CTA.

### 3. Schedule logging
Append to `state/notes/content-calendar.md`:
```
| <id> | <Title> | <publish date> | PUBLISH |
```

### 4. Analytics capture (30-day)
When called after publishing, create `state/records/analytics-<id>.md`:

```markdown
# Analytics Snapshot: <Title>
Project: <id>
Captured: <date> (<N> days after publish)

| Metric | Value | vs. channel avg |
|---|---|---|
| Views (30d) | | |
| CTR | | |
| Avg view duration | | |
| Watch time (hours) | | |
| Subscribers gained | | |
| Comments | | |
| Likes | | |
```

### 5. Postmortem
Create `state/projects/<id>/postmortem.md`:

```markdown
# Postmortem: <Title>
Project: <id>
Published: <date>
Reviewed: <date>

## Performance vs. Goals
| Metric | Target | Actual | Delta |
|---|---|---|---|
| Views | | | |
| CTR | | | |
| Retention | | | |

## What Worked
-

## What Didn't
-

## Lessons for Next Video
-

## Channel Learning
<Any finding worth persisting to state/notes/channel-learnings.md>
```

Append key learnings to `state/notes/channel-learnings.md`.

Update `state/projects/<id>/status.md` → Stage: POSTMORTEM → complete.

## Quality Gates
- Publish plan has all upload checklist items
- Description includes chapters from edit notes
- At least 3 repurposing formats planned
- Analytics snapshot captured within 35 days of publish
- Postmortem references specific numbers, not impressions

## Failure Modes
| Failure | Correction |
|---|---|
| No chapters in description | Pull directly from edit-notes.md; do not skip |
| Repurposing plan left pending | Set a schedule note in state/notes/ |
| Postmortem skipped | Flag in orchestrator weekly planning review |
| Analytics not captured | Note as missing in records; prompt on next session |
