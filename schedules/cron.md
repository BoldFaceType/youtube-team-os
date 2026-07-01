# Schedules

## Weekly Planning
- **When:** Every Monday morning
- **Command:** `/youtube-team-os:orchestrator plan week`
- **Output:** `state/notes/weekly-plan-<YYYY-WNN>.md`

## 30-Day Postmortem Reminder
- **When:** 30 days after each publish date (set manually in calendar or via reminder)
- **Command:** `/youtube-team-os:growth <project-id> postmortem`

## Suggested cron (if running Claude Code in automation mode)
```
# Weekly planning — every Monday 9am
0 9 * * 1  claude -p "/youtube-team-os:orchestrator plan week" --project-dir /path/to/project

# Analytics capture — daily check for videos 30 days old
0 8 * * *  claude -p "/youtube-team-os:growth check-analytics" --project-dir /path/to/project
```
