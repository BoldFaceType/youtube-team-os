---
name: thumbnail
description: >
  Use when generating thumbnail concepts, title/thumbnail pair variants, or visual
  packaging options for a specific video project. Invoke with /youtube-team-os:thumbnail.
  Do not use for scripting, editing, or distribution work.
routing_links:
  primary:
    - youtube-team-os:thumbnail
  related:
    - youtube-team-os:editor
    - youtube-team-os:growth
  avoid:
    - youtube-team-os:producer
    - youtube-team-os:writer
---

# Thumbnail Designer

## Purpose
Create click-optimized thumbnail concepts and title/thumbnail pairs that match the video's angle and drive CTR.

## Use When
- Designing thumbnail options for a completed or near-complete video
- Writing title variants to pair with each thumbnail concept
- Auditing an existing thumbnail for CTR issues
- Creating packaging that fits the channel's visual identity

## Do Not Use When
- Script isn't finalized (brief is fine; needs at least an angle)
- Task is about publishing or analytics (→ growth)

## Inputs
- `$ARGUMENTS`: project ID or specific packaging request
- `state/roles/thumbnail/inbox.md`
- `state/projects/<id>/brief.md` — for angle and keyword
- `state/projects/<id>/script.md` — for hook and key moments
- `state/projects/<id>/edit-notes.md` — for best visual frames

## Outputs
- `state/projects/<id>/thumbnail-options.md`
- `state/roles/growth/inbox.md` — handoff with project ID

## Procedure

### 1. Extract packaging signals
From the brief: primary keyword, hook, target viewer.
From the script: the single most surprising or high-value moment (best thumbnail frame candidate).
From edit notes: retention peak sections (high-energy moments = strong thumbnail frames).

### 2. Generate 3 thumbnail concepts
For each concept, define:
- **Visual**: what's in the image (face expression, object, text overlay, background)
- **Text overlay**: 2–4 words max, large font, high contrast
- **Emotion**: what the thumbnail makes the viewer feel (curiosity, fear of missing out, desire, shock)
- **Color palette**: dominant color + contrast color

Write to `state/projects/<id>/thumbnail-options.md`:

```markdown
# Thumbnail Options: <Title>
Project: <id>

## Concept A — <Name>
Visual: <description of image composition>
Text overlay: "<2–4 words>"
Emotion: <curiosity / FOMO / desire / shock>
Colors: <dominant> + <contrast>
Why it works: <one sentence>

## Concept B — <Name>
...

## Concept C — <Name>
...

## Recommended
Concept <X> — reason: <why this best matches the hook and viewer psychology>

---

## Title Variants
Pair each title with the recommended concept:

1. <Title option 1> — angle: <informational / curiosity / direct benefit>
2. <Title option 2>
3. <Title option 3>

## Packaging Notes
- Primary keyword placement: <in title / first 3 words / yes/no>
- Mobile legibility: text readable at 120×68px?
- Channel consistency: <fits / diverges from — note why>
```

### 3. CTR self-audit
Before saving, check each concept against:
- Text ≤4 words, high contrast, readable at small size
- Face (if used) has strong, readable expression
- No clutter — one clear focal point
- Curiosity gap or explicit benefit is visible at a glance

### 4. Handoff to growth
Write to `state/roles/growth/inbox.md`:
```
task: Prepare distribution and publish plan
project: <id>
thumbnail-options: state/projects/<id>/thumbnail-options.md
priority: normal
added: <ISO date>
```

Update `state/projects/<id>/status.md` → Stage: THUMBNAIL → complete.

## Quality Gates
- 3 distinct concepts, not variations of one idea
- Each concept has visual, text, emotion, and color defined
- Recommended concept is called with a reason
- At least 3 title variants produced
- Growth inbox updated

## Failure Modes
| Failure | Correction |
|---|---|
| All concepts look the same | Force at least one text-only and one face-forward concept |
| Text overlay too long | Cut to ≤4 words; move detail to the video title |
| No recommended option | Force a pick; defer alternatives to A/B test note |
| Title variants all use same structure | Vary opening word and angle across the 3 options |
