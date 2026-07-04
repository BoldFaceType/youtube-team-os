#!/usr/bin/env node
// check-postmortem-due.js — Remind when postmortem is due (28–32 days post-publish)
// Checks activity.log for PUBLISH stage transition date

const fs = require('fs');
const path = require('path');

const pluginRoot = process.env.CLAUDE_PLUGIN_ROOT || path.join(__dirname, '..');
const projectsDir = path.join(pluginRoot, 'state', 'projects');

if (!fs.existsSync(projectsDir)) process.exit(0);

const today = new Date();
today.setHours(0, 0, 0, 0);
const reminders = [];

const projects = fs.readdirSync(projectsDir, { withFileTypes: true })
  .filter(d => d.isDirectory())
  .map(d => d.name);

for (const projectId of projects) {
  const statusPath = path.join(projectsDir, projectId, 'status.md');
  const activityPath = path.join(projectsDir, projectId, 'activity.log');
  const postmortemPath = path.join(projectsDir, projectId, 'postmortem.md');

  if (!fs.existsSync(statusPath)) continue;

  const status = fs.readFileSync(statusPath, 'utf8');
  const stageMatch = status.match(/stage:\s*(\w+)/);
  if (!stageMatch) continue;

  const stage = stageMatch[1].toUpperCase();
  if (stage !== 'PUBLISH') continue; // Only check published-but-not-postmortemed

  // Find publish date in activity log
  if (!fs.existsSync(activityPath)) continue;
  const activity = fs.readFileSync(activityPath, 'utf8');
  const publishMatch = activity.match(/\[(\d{4}-\d{2}-\d{2})[^\]]*\].*PUBLISH/);
  if (!publishMatch) continue;

  // See check-deadlines.js for why this doesn't use `new Date(str)` + setHours(0,0,0,0)
  // (TM-6: UTC-parse followed by local-reinterpret silently shifts the date back a day
  // in timezones behind UTC).
  const [py, pm, pd] = publishMatch[1].split('-').map(Number);
  const publishDate = new Date(py, pm - 1, pd);
  const daysSincePublish = Math.round((today - publishDate) / (1000 * 60 * 60 * 24));

  if (daysSincePublish >= 28 && daysSincePublish <= 35) {
    // Check if postmortem is still a stub
    if (fs.existsSync(postmortemPath)) {
      const pm = fs.readFileSync(postmortemPath, 'utf8');
      if (pm.includes('Not yet written') || pm.includes('[VIEWS]')) {
        reminders.push(`📊  POSTMORTEM DUE: ${projectId} (published ${daysSincePublish}d ago)`);
      }
    }
  }
}

if (reminders.length > 0) {
  console.log('\n[yt-os] Postmortem reminders:');
  reminders.forEach(r => console.log(' ', r));
  console.log('  Run /youtube-team-os:growth <project-id> postmortem\n');
}

process.exit(0);
