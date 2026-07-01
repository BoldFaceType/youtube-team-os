# Workflow: Weekly Planning

## Trigger
Run every Monday (or start of content week): `/youtube-team-os:orchestrator plan week`

## Procedure

1. **Scan open projects**
   - List all `state/projects/*/status.md` where stage ≠ POSTMORTEM/COMPLETE
   - Group by stage

2. **Check role inboxes**
   - List pending items in each `state/roles/*/inbox.md`

3. **Check calendar**
   - Read `state/notes/content-calendar.md`
   - Flag any video with a publish date within 7 days that hasn't reached THUMBNAIL stage

4. **Output weekly plan**
   - Write `state/notes/weekly-plan-<YYYY-WNN>.md`
   - Format:

```markdown
# Weekly Plan — Week <NN>, <YYYY>

## This Week's Priority Videos
| Project | Stage | Next action | Role |
|---|---|---|---|

## At-Risk (publish date < 7 days)
|...|

## Role Queue
- Producer: <N> pending
- Writer: <N> pending
- Editor: <N> pending
- Thumbnail: <N> pending
- Growth: <N> pending

## New Ideas to Brief
-

## Carry-Forward
-
```

5. **Dispatch highest priority** to appropriate role inbox.
