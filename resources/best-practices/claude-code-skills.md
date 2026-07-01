# Claude Code Skill Authoring Best Practices

Reference for writing and maintaining SKILL.md files in this plugin.
Based on Anthropic official skill spec (verified via Context7, 2026-07-01).

---

## SKILL.md structure

Every skill file must have:

```markdown
---
name: skill-name
description: >
  One-paragraph description used for routing decisions.
  Be specific about WHEN to use this skill (not just what it does).
routing_links:
  - ../other-skill/SKILL.md
---

## Use When
## Do Not Use When
## Inputs
## Outputs
## Procedure
## Quality Gates
## Failure Modes
```

---

## Frontmatter rules

### `name`
- Lowercase kebab-case
- Should match the directory name
- Used in `/plugin-name:skill-name` invocation syntax

### `description`
- Written for routing, not marketing
- Must answer: "When should Claude pick THIS skill over others?"
- Include signals that would trigger it: "when user says X, when the stage is Y"
- Max ~150 words

### `routing_links`
- Relative paths to related skill files
- Helps Claude understand the handoff chain
- Include the skill you call BEFORE this one and AFTER this one

---

## Procedure section rules

Write in imperative mood, not prose:
```markdown
## Procedure

1. Read `state/projects/<id>/brief.md`. If any required field is blank, stop and ask.
2. Write outline to `state/projects/<id>/outline.md` using the template structure.
3. Verify outline covers all key points from brief before proceeding.
4. Write full script to `state/projects/<id>/script.md`.
5. Append handoff task to `state/roles/editor/inbox.md`.
6. Update `state/projects/<id>/status.md`: set stage to SCRIPT, owner to editor.
```

Each step should be:
- One action
- Specific about the file path
- Verifiable (has a clear success condition)

---

## Quality Gates section

Define explicit pass/fail criteria. Use tables:

```markdown
## Quality Gates

| Gate | Criterion | Fail action |
|---|---|---|
| Brief complete | All required fields non-empty | Stop, notify producer |
| Script length | 800–2500 words for 8–15min video | Flag and ask |
| Hook length | ≤60 seconds (≤150 words) | Cut or rework |
| B-roll density | ≥1 cue per 60 seconds | Add cues before handoff |
```

---

## Failure Modes section

Document the top 3–5 ways this skill breaks and what to do:

```markdown
## Failure Modes

- **Brief is incomplete** — Stop. Do not guess. Ask the producer to fill missing fields.
- **Project ID doesn't exist** — Check `state/projects/`. If missing, run `bin/new-project` first.
- **Inbox write fails** — Manually append the task. Check file permissions on `state/roles/`.
- **Hook test fails** — Do not proceed to script. Rewrite the hook until the test passes.
```

---

## Routing links best practice

Always link to the next skill in the pipeline:

```yaml
routing_links:
  - ../producer/SKILL.md   # comes before
  - ../editor/SKILL.md     # comes after
```

Claude uses these links to understand context when a user is mid-pipeline.

---

## Length constraints

| Section | Target length |
|---|---|
| `description` frontmatter | 50–150 words |
| `Use When` | 3–7 bullet points |
| `Procedure` | 5–15 numbered steps |
| `Quality Gates` | 3–8 rows |
| `Failure Modes` | 3–6 items |
| **Total SKILL.md** | **≤500 lines** |

---

## Common mistakes

| Mistake | Fix |
|---|---|
| Procedure written as prose | Convert to numbered imperative steps |
| `Use When` duplicates `description` | `description` is for routing; `Use When` is for edge cases |
| No file paths in procedure | Every read/write step must name the exact file |
| Quality gates are vague ("good quality") | Make them measurable ("≥18/25 on CTR rubric") |
| Skill handles two stages | Split into two skills |

---

## Testing a skill

```bash
# 1. Validate the plugin (checks skill file exists)
.\bin\validate.ps1

# 2. Invoke the skill in Claude Code
claude --plugin-dir . /youtube-team-os:skill-name "test input"

# 3. Check output files were written correctly
ls state\projects\<id>\

# 4. Check inbox was updated
cat state\roles\<next-role>\inbox.md
```
