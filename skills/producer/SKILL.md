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
- `state/projects/*/postmortem.md` + `state/records/analytics-*.md` — internal performance evidence (may not exist yet on a new install)
- `state/notes/idea-bank.md` — banked candidates from previous runs
- `resources/templates/brief-template.md`

## Outputs
- `state/projects/<id>/brief.md` — completed content brief
- `state/notes/content-calendar.md` — updated calendar entry
- `state/notes/idea-bank.md` — unselected candidates scoring ≥14/20 appended
- `state/roles/writer/inbox.md` — task handoff with project ID

## Procedure

### 1. Load context
Read `state/roles/producer/inbox.md`. Extract the current task and project ID.
If the brief already exists at `state/projects/<id>/brief.md`, load it. Otherwise create it from the template.

### 2. Idea Sourcing & Validation (if needed)
When the input is an idea prompt or broad topic, do NOT generate candidates blind. Work the evidence in order:

**a. Internal evidence first (the OS loop).** Read every `state/projects/*/postmortem.md` and `state/records/analytics-*.md`, plus `state/notes/channel-learnings.md`. Extract what has actually worked and failed on this channel: hook styles, topics, retention patterns, CTR by packaging style. Skim `state/notes/idea-bank.md` for banked candidates worth re-scoring. If no postmortems or analytics exist yet (new install), write "No internal performance data yet — external signals only" in the brief and continue. Never block on missing history.

**b. External demand signals.** Generate 3–5 candidate angles, then validate each on the web:
- Search intent: are people actively searching this phrasing? What do autocomplete and the current top results promise, and what do they leave unanswered?
- Comparable-channel outliers: look for videos on similar-sized channels in this niche that beat their channel's average (high view-to-subscriber ratio, or views several times the channel norm). An outlier on a channel your size is stronger proof than a hit on a 2M-sub channel.
Record one evidence line per candidate — "no demand signal found" is also a finding.

**c. Packaging-first gate.** Every candidate must have a working title AND a one-line thumbnail concept before it is eligible for selection. If you can't package it, it isn't ready — bank it or drop it.

**d. Score each candidate 1–5** on:
- Demand evidence (search intent + outlier proof)
- Differentiation (can we own a unique angle?)
- Channel fit (cite internal evidence from step a when it exists)
- Effort-to-payoff

Write candidates to `state/projects/<id>/brief.md` under `## Idea Candidates`. Each candidate shows: working title, thumbnail concept, core angle, target audience segment, its four scores, and its one-line evidence note.

<!-- NON-56 sources (practice → URL):
  Analytics-informed ideation (use your own CTR/retention/new-viewer data to plan the next video):
    https://blog.youtube/creator-and-artist-stories/master-these-4-metrics/
  Packaging-first — title + thumbnail treated as pre-production, before scripting:
    https://www.spotterstudio.com/blog/optimize-youtube-titles-thumbnails
    https://www.videotoblog.ai/resources/youtube-thumbnail-and-title-workflow-how-to-produce-more-content-with-less-stress
  Comparable-channel outlier validation (view-to-channel-average multiplier, channels your size):
    https://vidiq.com/features/outliers/
    https://support.vidiq.com/en/articles/9660010-outliers
  High-multiple outlier research as idea proof (6x–100x, 1of10-style):
    https://outlierkit.com/blog/best-youtube-outlier-finder-tools
  Audience → idea → packaging → retention pipeline and idea scoring:
    https://outlierkit.com/blog/youtube-channel-growth-strategy
-->

### 3. Select and commit
Pick one candidate and state why, explicitly referencing its scores (e.g. "highest demand evidence, only candidate scoring 5/5 on channel fit"). Append unselected candidates with total score ≥14/20 to `state/notes/idea-bank.md` so ideation compounds across runs. Then write the full brief:

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
- Every idea candidate has a working title, thumbnail concept, four 1–5 scores, and an evidence line
- Selection reason explicitly references scores
- Internal-evidence step ran (or its absence is stated in the brief)
- Angle is stated in one sentence
- Hook is concrete, not vague
- Calendar entry added
- Writer inbox updated

## Failure Modes
| Failure | Correction |
|---|---|
| Too many angles, none chosen | Force selection; defer others to future brief |
| No internal data (new install) | State it in the brief and proceed on external signals — never block |
| Candidate can't be packaged (no title/thumbnail concept) | Not eligible for selection; bank or drop it |
| Scores asserted without evidence | Add the search-intent / outlier / internal-data line or lower the score |
| Hook is generic | Rewrite with specific tension or curiosity gap |
| No SEO notes | Add at least one primary keyword |
