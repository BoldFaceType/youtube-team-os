# youtube-team-os — Claude Code Context

This is a multi-role YouTube production OS plugin. Claude Code sessions run inside
this plugin directory. Read this file before taking any action.

---

## What this plugin does

Manages a full video production pipeline across five specialist roles:

```
INTAKE → BRIEF → OUTLINE → SCRIPT → EDIT → THUMBNAIL → PUBLISH → POSTMORTEM
```

Each role has a dedicated skill (`skills/<role>/SKILL.md`) and an agent definition
(`agents/<role>.md`). Work is handed off via `state/roles/<role>/inbox.md`.

---

## Role routing

| User intent | Invoke |
|---|---|
| New video idea / resume project / weekly plan | `orchestrator` |
| Content strategy, brief, calendar | `producer` |
| Outline or script | `writer` |
| Pacing, cut notes, chapters | `editor` |
| Thumbnail concepts, title, CTR | `thumbnail` |
| Upload, repurposing, analytics, postmortem | `growth` |

**Default agent is `orchestrator`.** It reads the current `state/` and routes to the
right role automatically. Only invoke a role skill directly if you know exactly what
stage you are at.

---

## State filesystem

All persistent work lives under `state/`. Never delete or move these directories.

```
state/
  projects/<id>/          ← one folder per video (YYYY-MM-ep##-slug)
    brief.md              ← producer output
    outline.md            ← writer output
    script.md             ← writer output
    edit-notes.md         ← editor output
    thumbnail-options.md  ← thumbnail output
    publish-plan.md       ← growth output
    postmortem.md         ← growth output (30-day)
    status.md             ← current stage + owner
    activity.log          ← timestamped stage transitions
  roles/<role>/
    inbox.md              ← pending tasks for this role (FIFO)
    current.md            ← active task (excluded from git)
  notes/
    content-calendar.md   ← pipeline stage overview
    channel-learnings.md  ← persistent postmortem learnings
    weekly-plan-*.md      ← Monday planning outputs
  records/
    session.log           ← hook-generated (excluded from git)
    writes.log            ← hook-generated (excluded from git)
    analytics-<id>.md     ← 30-day stats snapshots
```

### Project ID format

`YYYY-MM-ep##-slug` — e.g., `2026-07-ep01-pricing-mistakes`

Always create the folder with `bin/new-project.ps1 "slug"` or `bin/new-project.sh slug`
to guarantee all subfiles are scaffolded correctly.

---

## Hard rules

1. **Never write directly to `state/records/`** — that is hook-managed.
2. **Never modify another role's deliverable** — handoff is one-way. Writer does not
   edit briefs. Editor does not edit scripts.
3. **No hallucinated stats** — if analytics aren't available, leave placeholders
   (`[VIEWS]`, `[CTR]`) for the human to fill.
4. **Hook jq path** — hooks parse `jq -r '.tool_input.file_path'` from stdin.
   Do not change the hooks schema without updating `hooks/hooks.json`.
5. **No hardcoded secrets** — if an MCP server is added to `.mcp.json` in the future,
   inject credentials via env vars, never hardcode them.
6. **No `localStorage` or browser storage** — n/a for this plugin, but noted for
   any HTML artifact generation.

---

## MCP connectors

`.mcp.json` currently defines no servers (`{"mcpServers": {}}`). YouTube analytics and
Drive sync are manual/rclone-based for now — see `connectors/youtube-metadata.md` and
`connectors/drive.md` for why and what to use instead. See `connectors/mcp-setup.md` for
how to wire up a real MCP server later if one becomes available.

---

## Hooks

`hooks/hooks.json` runs automatically on:
- `SessionStart` — logs session start to `state/records/session.log`, and runs the
  deadline (`monitors/check-deadlines.js`) and postmortem-due
  (`monitors/check-postmortem-due.js`) reminder checks
- `PostToolUse` (Write|Edit) — logs every file write to `state/records/writes.log`
  (writes a `jq-missing` sentinel line instead of a blank line if `jq` isn't installed)
- `Stop` / `SessionEnd` — logs session end

Hooks require `jq` on PATH for the write-audit log, and Node.js on PATH for the two
deadline/postmortem reminder checks. Install jq: `winget install jqlang.jq` (Windows) or
`brew install jq` (Mac).

---

## Agent invocation (Claude Code)

```bash
# Use orchestrator (default)
claude --plugin-dir .

# Invoke a specific role skill
/youtube-team-os:producer "10 pricing mistakes SaaS founders make"
/youtube-team-os:writer 2026-07-ep01-pricing-mistakes
/youtube-team-os:growth 2026-07-ep01-pricing-mistakes publish
```

---

## Scripts

| Script | Platform | Purpose |
|---|---|---|
| `bin/new-project.ps1` | Windows | Scaffold a new project folder |
| `bin/new-project.sh` | Mac/Linux | Scaffold a new project folder |
| `bin/validate.ps1` | Windows | Run `claude plugin validate` |
| `bin/sync-state.ps1` | Windows | Push state snapshot to Google Drive |

---

## Skill authoring conventions

- All `SKILL.md` files use YAML frontmatter (`name`, `description`, `routing_links`).
- Sections in order: Use When / Do Not Use When / Inputs / Outputs / Procedure /
  Quality Gates / Failure Modes.
- Never exceed 500 lines per skill file.
- Keep procedures imperative: "Read X. Write Y. Check Z."

---

## Testing

See `README.md` → Testing section for the full test protocol.
Quick smoke test: `bin/validate.ps1` then run `/youtube-team-os:orchestrator "test idea"`.
