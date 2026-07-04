# End-to-End Runbook (manual)

This is the actual proof that the plugin works — the six role skills
(orchestrator, producer, writer, editor, thumbnail, growth) are markdown instructions
executed by an LLM, not deterministic code, so `bin/smoke-test.ps1`/`.sh` cannot exercise
them. This runbook is a documented manual procedure, not a CI job — a real headless run
costs API tokens/time and its pass/fail is a human judgment call ("does this deliverable
look reasonable"), which doesn't belong as a per-commit gate. Run it by hand:

- After landing any change to a skill, agent, or the state-handoff contract between roles.
- Before tagging a release.
- Whenever `bin/smoke-test.ps1`/`.sh` passes but you want to confirm the LLM-driven layer
  still works end to end.

## Before you start

1. Run `bin/validate.ps1` (or `.sh`) — must be clean (0 errors) before trusting an e2e run.
2. Pick a scratch directory outside the real repo, e.g. `C:\tmp\yt-os-e2e` /
   `/tmp/yt-os-e2e`, so this run never touches the real `state/` tree.
3. Prefix the test topic with `smoke-test-` so it's never mistaken for real content in
   the content calendar or channel learnings.

## Command sequence

Run each step, inspect the checklist item below it, then proceed. Replace
`<project-id>` with whatever ID the orchestrator actually creates in step 1 (it follows
`YYYY-MM-ep##-slug`).

```bash
# 1. INTAKE — orchestrator creates the project
claude -p '/youtube-team-os:orchestrator "smoke-test-pricing-mistakes"' \
  --plugin-dir . --project-dir /tmp/yt-os-e2e

# 2. BRIEF — producer
claude -p '/youtube-team-os:producer <project-id>' \
  --plugin-dir . --project-dir /tmp/yt-os-e2e

# 3. OUTLINE + SCRIPT — writer
claude -p '/youtube-team-os:writer <project-id>' \
  --plugin-dir . --project-dir /tmp/yt-os-e2e

# 4. EDIT NOTES — editor
claude -p '/youtube-team-os:editor <project-id>' \
  --plugin-dir . --project-dir /tmp/yt-os-e2e

# 5. THUMBNAIL + TITLE — thumbnail
claude -p '/youtube-team-os:thumbnail <project-id>' \
  --plugin-dir . --project-dir /tmp/yt-os-e2e

# 6. PUBLISH PLAN — growth
claude -p '/youtube-team-os:growth <project-id> publish' \
  --plugin-dir . --project-dir /tmp/yt-os-e2e
```

This mirrors `workflows/idea-to-upload.md`'s stage diagram and the `claude -p` headless
pattern already used in `schedules/cron.md`.

## Pass/fail checklist (check after each step)

- [ ] `state/projects/<project-id>/status.md` shows the expected `stage:` for this step
      (INTAKE → BRIEF → SCRIPT → EDIT → THUMBNAIL → PUBLISH), and `owner:` matches the
      next role in the chain.
- [ ] The role's own deliverable file is non-empty and no longer says
      "Not yet written" (`brief.md`, then `outline.md`+`script.md`, then
      `edit-notes.md`, then `thumbnail-options.md`, then `publish-plan.md`).
- [ ] `state/projects/<project-id>/activity.log` got a new timestamped stage-transition
      line for this step.
- [ ] The **next** role's `state/roles/<next-role>/inbox.md` got a new handoff entry
      referencing `<project-id>`.
- [ ] **No cross-role file mutation** (CLAUDE.md hard rule #2): confirm the role that just
      ran did NOT edit a deliverable file owned by a different role (e.g. writer must not
      have touched `brief.md`, editor must not have touched `script.md`).
- [ ] `state/records/session.log` and `writes.log` gained new entries for this step
      (confirms hooks fired during a real session, not just in the smoke test).

## After the full run

- [ ] Confirm `state/notes/content-calendar.md` has a 5-column row for `<project-id>`
      that a plain-text scan can visually align under the header (TM-4 regression, now
      exercised by a real LLM-authored row instead of just the scripted one).
- [ ] Confirm no role skipped a stage or wrote another role's deliverable — the full
      chain orchestrator → producer → writer → editor → thumbnail → growth should be
      visible in `activity.log` in order.
- [ ] Delete the scratch directory (`/tmp/yt-os-e2e` or equivalent) — this run's output is
      throwaway, not meant to be committed anywhere.

## Recording the result

There's no dashboard for this yet — note the date, plugin git commit SHA, and pass/fail
per checklist item in the PR description or commit message for whatever change prompted
the run. If something fails, file it the same way the original code review's findings
were tracked (see `TASK_MANIFEST.md` and the linked Linear issues) rather than silently
patching around it.
