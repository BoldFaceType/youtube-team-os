# Workflow: Postmortem

## Trigger
30 days after publish date. Run: `/youtube-team-os:growth <id> postmortem`

## Procedure

1. Load `state/projects/<id>/brief.md` for original goals
2. Load `state/records/analytics-<id>.md` for actual metrics
3. Compare actuals vs. targets from brief
4. Write `state/projects/<id>/postmortem.md` (see growth SKILL.md for template)
5. Extract top learning → append to `state/notes/channel-learnings.md`
6. Update `state/notes/content-calendar.md` row → Stage: COMPLETE
7. Update `state/projects/<id>/status.md` → Stage: POSTMORTEM → COMPLETE

## What Makes a Good Postmortem
- Numbers first, impressions second
- One specific thing that worked (reproducible)
- One specific thing that didn't (avoidable)
- One hypothesis for the next video to test
