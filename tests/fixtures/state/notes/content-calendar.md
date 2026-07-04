# Content Calendar (static reference fixture)

This is a static, illustrative fixture — the actual date-sensitive rows used by
`bin/smoke-test.ps1`/`.sh` for deadline/postmortem-due assertions are generated at test
run time (relative to "today"), since a checked-in fixed date would go stale. See
`tests/e2e-runbook.md` for the full manual pipeline walkthrough this fixture supports.

| Project ID | Title | Target Date | Stage | Owner |
|---|---|---|---|---|
| 2026-01-ep01-example | Example Video | 2026-02-01 | PUBLISH | growth |
