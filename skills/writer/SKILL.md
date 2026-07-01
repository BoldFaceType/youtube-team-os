---
name: writer
description: >
  Use when writing or refining a video script, outline, hook, or research notes for a
  specific project. Invoke with /youtube-team-os:writer. Do not use for idea selection
  (→ producer) or post-production work (→ editor, thumbnail, growth).
routing_links:
  primary:
    - youtube-team-os:writer
  related:
    - youtube-team-os:producer
    - youtube-team-os:editor
  avoid:
    - youtube-team-os:thumbnail
    - youtube-team-os:growth
---

# Writer / Researcher

## Purpose
Turn a content brief into a tight, watchable script with a strong hook, clear structure, and retention checkpoints.

## Use When
- Writing the video outline
- Drafting or refining the full script
- Writing or rewriting the hook
- Fact-checking or researching supporting material
- Adding B-roll notes or on-screen text cues

## Do Not Use When
- Brief doesn't exist yet (→ producer)
- Script is done and task is about cutting/pacing (→ editor)

## Inputs
- `$ARGUMENTS`: project ID or specific script section
- `state/roles/writer/inbox.md`
- `state/projects/<id>/brief.md`
- `state/projects/<id>/outline.md` (if exists)
- `resources/templates/script-template.md`

## Outputs
- `state/projects/<id>/outline.md`
- `state/projects/<id>/script.md`
- `state/roles/editor/inbox.md` — handoff with project ID

## Procedure

### 1. Load brief
Read `state/projects/<id>/brief.md`. Extract: angle, target viewer, hook, key points, CTA.

### 2. Write outline
Create `state/projects/<id>/outline.md`:

```markdown
# Outline: <Title>
Project: <id>

## Hook (0:00–0:30)
<Tension or question that makes someone stay>

## Intro / Promise (0:30–1:00)
<What this video delivers and why it matters>

## Section 1: <Name> (~min)
- Point A
- Point B
- Transition: <how we move to next section>

## Section 2: <Name> (~min)
...

## Section N: <Name> (~min)
...

## CTA + Close (~1:00)
<What viewer should do; subscribe / comment prompt>

## B-Roll / Visual Notes
- <Timestamp or section>: <What to show on screen>
```

### 3. Write script
Expand each outline section into full narration. Follow these rules:
- Write in conversational spoken language, not essay prose
- Sentences ≤20 words on average
- Hook: open with tension, question, or surprising fact — no "welcome back" openers
- Retention checkpoints every 60–90 seconds: restate the promise or tease what's next
- B-roll cues in `[brackets]` inline
- On-screen text in `{curly braces}`

Script format:

```markdown
# Script: <Title>
Project: <id>
Draft: 1
Word count: ~<N> (~<runtime> min at 130wpm)

---

[HOOK]
<narration>

[INTRO]
<narration>

[SECTION 1: <Name>]
<narration>
[B-roll: <description>]

...

[CTA]
<narration>
```

### 4. Self-review
Before saving final draft, verify:
- Hook lands in first 3 sentences
- Every section has a transition to the next
- Estimated runtime is within target (from brief or default 8–12 min)
- No filler phrases: "So basically", "Um", "As I mentioned"
- CTA is specific and placed before final goodbye

### 5. Handoff to editor
Write to `state/roles/editor/inbox.md`:
```
task: Review pacing and create cut list
project: <id>
script: state/projects/<id>/script.md
priority: normal
added: <ISO date>
```

Update `state/projects/<id>/status.md` → Stage: SCRIPT → complete.

## Quality Gates
- Outline exists before script is started
- Hook is in first 3 sentences, not a welcome greeting
- Script has inline B-roll and on-screen text cues
- Word count estimate and runtime noted
- Editor inbox updated

## Failure Modes
| Failure | Correction |
|---|---|
| Hook is a welcome/greeting | Delete it; open with the tension/question directly |
| Sections have no transitions | Add a one-sentence bridge at the end of each section |
| Script too long | Cut to one idea per section; move secondary ideas to a follow-up brief |
| No B-roll notes | Add `[B-roll: <visual description>]` at every abstract claim |
