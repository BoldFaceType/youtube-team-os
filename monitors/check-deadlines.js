#!/usr/bin/env node
// check-deadlines.js — Warn on upcoming publish deadlines
// Called by monitors.json on SessionStart
// Reads state/notes/content-calendar.md, parses table, prints warnings to stdout

const fs = require('fs');
const path = require('path');

const pluginRoot = process.env.CLAUDE_PLUGIN_ROOT || path.join(__dirname, '..');
const calendarPath = path.join(pluginRoot, 'state', 'notes', 'content-calendar.md');

if (!fs.existsSync(calendarPath)) {
  process.exit(0); // No calendar yet — not an error
}

const content = fs.readFileSync(calendarPath, 'utf8');
const lines = content.split('\n');
const today = new Date();
today.setHours(0, 0, 0, 0);

const warnings = [];

for (const line of lines) {
  // Match table rows: | project-id | title | YYYY-MM-DD | stage | owner |
  const match = line.match(/^\|\s*(\S+)\s*\|\s*([^|]+)\|\s*(\d{4}-\d{2}-\d{2})\s*\|\s*(\w+)\s*\|\s*(\w+)\s*\|/);
  if (!match) continue;

  const [, projectId, , targetDateStr, stage] = match;
  // Parse the YYYY-MM-DD components directly into a local-midnight Date, rather than
  // `new Date(targetDateStr)` (parsed as UTC midnight) followed by `.setHours(0,0,0,0)`
  // (which re-interprets in local time) — that combination silently shifts the date
  // back a day in any timezone behind UTC (TM-6).
  const [ty, tm, td] = targetDateStr.split('-').map(Number);
  const targetDate = new Date(ty, tm - 1, td);

  const daysUntil = Math.round((targetDate - today) / (1000 * 60 * 60 * 24));
  const doneStages = ['PUBLISH', 'POSTMORTEM'];

  if (doneStages.includes(stage.toUpperCase())) continue;

  if (daysUntil < 0) {
    warnings.push(`⚠️  OVERDUE ${Math.abs(daysUntil)}d: ${projectId} (${stage}) — target was ${targetDateStr}`);
  } else if (daysUntil <= 3) {
    warnings.push(`⏰  DUE IN ${daysUntil}d: ${projectId} (${stage}) — target ${targetDateStr}`);
  }
}

if (warnings.length > 0) {
  console.log('\n[yt-os] Deadline alerts:');
  warnings.forEach(w => console.log(' ', w));
  console.log('  Run /youtube-team-os:orchestrator to review.\n');
}

process.exit(0);
