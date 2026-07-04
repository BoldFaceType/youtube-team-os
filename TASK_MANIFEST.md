# Task Manifest — youtube-team-os

Last updated: 2026-07-04
Source: Full-repo code review (manual file-by-file audit + Context7 verification against
`code.claude.com/docs` + live npm registry checks). See Linear project
[`youtube-team-os`](https://linear.app/non-linear0507/project/youtube-team-os-127fd35e0735)
for tracked issues (`NON-*`).

## Severity legend

| Severity | Meaning |
|---|---|
| Urgent | A documented/advertised feature does not work at all as shipped |
| High | Feature partially works but silently corrupts data or misleads the user |
| Medium | Gap in validation/tooling that lets Urgent/High issues go undetected |
| Low | Cosmetic, metadata, or maintainability nitpick — no runtime impact |

---

## TM-1 — `monitors/monitors.json` uses a schema that doesn't exist (Urgent)

**File:** `monitors/monitors.json:1-28`
**Linked:** NON-38 (tracks "add monitors" — ticket is Backlog but the broken file already exists)

Verified against `code.claude.com/docs/en/plugins-reference` and `.../plugins` via Context7.
The real schema is a **bare JSON array** of `{name, command, description, when?}`, and a monitor
is a **persistent background process** (docs' own examples: `tail -F ./logs/error.log`, a polling
script) whose stdout lines stream to Claude as notifications for the life of the session. `when`
only accepts `"always"` (default) or `"on-skill-invoke:<skill>"`.

The shipped file gets every axis wrong:
- Wraps the array in `{"monitors": [...]}` instead of a bare array
- Uses `id` instead of the required `name`
- Invents `trigger: "SessionStart"`, `timeout`, `failureMode` — none of these fields exist
- Points at `check-deadlines.js` / `check-postmortem-due.js`, which are **one-shot** scripts that
  print output once and call `process.exit(0)` — incompatible with the persistent-process model

Additionally, `monitors.json:15` references `check-stale-inbox.js`, which was never created —
only `check-deadlines.js` and `check-postmortem-due.js` exist in `monitors/`.

**Fix:** Rewrite `monitors/monitors.json` as a bare array with correct fields. Either convert the
two existing scripts into persistent watchers (loop + sleep, or a `tail`-style long-running
process) or drop "monitors" as the delivery mechanism and invoke `check-deadlines.js` from a hook
or skill step instead. Write or remove the `check-stale-inbox.js` reference.

**Acceptance criteria:** `monitors/monitors.json` parses as a bare array; every `command` it
references resolves to an existing, long-running (non-exiting) process; `claude --plugin-dir .`
shows monitor notifications firing mid-session, not just once at start.

---

## TM-2 — `.mcp.json` points at a nonexistent package and a deprecated one (Urgent)

**File:** `.mcp.json:2-26`
**Linked:** NON-33 (tracks "wire YouTube Data API v3 MCP connector" — ticket is Backlog but the
broken config already exists)

Verified live against the npm registry:
- `@modelcontextprotocol/server-youtube` (`.mcp.json:4-9`) → **HTTP 404, package does not exist**
- `@modelcontextprotocol/server-gdrive` (`.mcp.json:16-19`) → exists, but npm marks it
  **"Package no longer supported"**

Compounding this, the same two connectors are documented with three mutually-inconsistent
package names: `connectors/youtube-metadata.md:20` says `@your-mcp/youtube-data` (an unresolved
placeholder), `connectors/drive.md:16` says `@google/drive-mcp`. Three files, three different
answers for the same two integrations.

**Fix:** Pick one real, currently-maintained MCP server per connector (or explicitly document
that no maintained YouTube MCP server exists yet and the growth skill's analytics step requires
manual input until one does). Make `.mcp.json`, `connectors/youtube-metadata.md`, and
`connectors/drive.md` agree.

**Acceptance criteria:** `npx -y <package>` for both configured servers succeeds and the server
responds to a basic tool call; all three docs referencing these connectors name the same package.

---

## TM-3 — Write-audit hook fails silently without `jq` (High)

**File:** `hooks/hooks.json:19`, `CLAUDE.md:83-84`, `bin/validate.ps1:125-126`

CLAUDE.md states as a "hard rule" that the audit-trail hook parses
`jq -r '.tool_input.file_path'` (this path expression itself is correct — confirmed via Context7
against the official hooks example, matching `code.claude.com/docs/en/plugins`). But if `jq` is
absent, `$(jq ...)` returns empty output rather than erroring, and the hook still logs a blank
line and exits 0 (`2>/dev/null; exit 0`). `validate.ps1:126` only **warns** on missing `jq`, never
blocks. Net effect: the plugin's whole audit-trail feature can silently degrade to garbage with
no visible error anywhere.

**Fix:** Have the hook command check `command -v jq` first and write an explicit
`[write] jq-missing` sentinel line when absent, so the gap is visible in the log itself.

**Acceptance criteria:** Running the hook with `jq` uninstalled produces a log line that clearly
flags the missing dependency instead of a blank/garbled entry.

---

## TM-4 — Content calendar seed file has fewer columns than every consumer expects (High)

**Files:** `state/notes/content-calendar.md:3` (4 columns) vs. `agents/producer.md:53-56`,
`skills/producer/SKILL.md:102-105`, `bin/new-project.ps1:116`, `bin/new-project.sh:115`,
`monitors/check-deadlines.js:25` (all assume 5 columns incl. `Owner`)

The seeded calendar header is `| Project ID | Title | Target Date | Stage |`. Every script that
appends to it, and every skill/agent doc describing the format, uses 5 columns including `Owner`.
`check-deadlines.js:25`'s regex requires 5 pipe-delimited fields to match a row at all — rows
written against the seed's 4-column shape will silently never trigger deadline warnings.

**Fix:** Add the `Owner` column to the seed file's header so it matches what every writer and
reader of this file actually expects.

**Acceptance criteria:** A row appended by `bin/new-project.ps1`/`.sh` aligns under the header;
`check-deadlines.js` correctly matches and warns on a test row with a near-term date.

---

## TM-5 — `validate.ps1` health check doesn't cover monitors/bin/connectors (Medium)

**File:** `bin/validate.ps1:60-79`

Checks manifest, core skills/agents, hooks, and `.mcp.json`, but was never updated when v1.1.0
added `monitors/`, `bin/`, `connectors/`, `resources/`, `workflows/` (per `CHANGELOG.md:19-45`).
It would report a clean pass even with TM-1 and TM-2 present — the two worst bugs in the package
go undetected by the tool whose whole job is to catch exactly this.

**Fix:** Add checks for `monitors/monitors.json` (and that every `command` it references
resolves to a file that exists) and for `bin/*.ps1`/`bin/*.sh` presence.

**Acceptance criteria:** `validate.ps1` fails loudly when `monitors/monitors.json` references a
missing script, as it currently does for `check-stale-inbox.js`.

---

## TM-6 — Timezone-naive date math in monitor scripts (Medium)

**Files:** `monitors/check-deadlines.js:29-32`, `monitors/check-postmortem-due.js:41-43`

`new Date("YYYY-MM-DD")` is parsed as UTC midnight; `today` is constructed via local-timezone
`setHours(0,0,0,0)`. In any timezone behind UTC (all of the Americas), this can shift the
computed day count by one, causing off-by-one errors in "due in N days" / "overdue" /
"postmortem due" warnings.

**Fix:** Parse both dates the same way — e.g. append `T00:00:00` to force local-time parsing on
the calendar date string, or do the whole comparison in UTC.

**Acceptance criteria:** A date exactly 3 days out reads as "DUE IN 3d" regardless of the host
machine's timezone (test in at least one UTC-negative zone).

---

## TM-7 — `plugin.json` homepage doesn't match the actual repo (Low)

**Files:** `.claude-plugin/plugin.json:9`, `CHANGELOG.md:74-76`, `git remote -v`

`plugin.json` sets `homepage` to `github.com/jtisby/youtube-team-os`; the actual git remote and
`CHANGELOG.md`'s compare links both point to `github.com/BoldFaceType/youtube-team-os`.

**Fix:** Align `homepage` in `plugin.json` with the actual remote.

---

## TM-8 — Missing `LICENSE` file despite `license: "MIT"` in manifest (Low)

**File:** `.claude-plugin/plugin.json:10`

Context7's official "Standard Plugin Directory Layout" example explicitly includes a `LICENSE`
file at plugin root — this isn't just a nice-to-have, it's a deviation from the documented
standard layout.

**Fix:** Add an MIT `LICENSE` file at the plugin root.

---

## TM-9 — `minClaudeCodeVersion` is not a documented plugin.json field (Low)

**File:** `.claude-plugin/plugin.json:12`

Searched the official manifest schema three ways via Context7 — the full field list is `name`,
`displayName`, `version`, `description`, `author`, `homepage`, `repository`, `license`,
`keywords`, `skills`, `commands`, `agents`, `hooks`, `mcpServers`, `outputStyles`, `lspServers`,
`experimental`, `dependencies`. `minClaudeCodeVersion` appears in none of them. Plugin manifests
appear to validate non-strictly by default, so this is likely just silently ignored rather than
harmful — but it's dead/invented metadata.

**Fix:** Remove the field, or confirm via a real Claude Code install whether it has any effect
before keeping it.

---

## TM-10 — Skill/agent content duplication is a two-source-of-truth risk (Low, design)

**Files:** `skills/<role>/SKILL.md` vs `agents/<role>.md` for all six roles

Each role's skill file and agent file independently restate the same deliverable formats, quality
gates, and procedures. Nothing enforces they stay in sync — a future edit to one is likely to
silently drift from the other.

**Fix:** Consider having one be the source of truth and the other reference/import it, or accept
the duplication but add a checklist item to the release process ("did you update both?").

---

## Priority order

1. TM-1, TM-2 — both "advertised feature doesn't work at all" (Urgent)
2. TM-3, TM-4 — silent data corruption (High)
3. TM-5 — fixes the detection gap that let TM-1–TM-4 ship undetected (Medium)
4. TM-6 (Medium), TM-7/TM-8/TM-9/TM-10 (Low, polish)
