# YouTube KPIs & Benchmarks

Reference targets for content performance. Used in briefs (success criteria),
postmortems (vs. actual), and growth skill analytics capture.

Sources: YouTube Creator Academy, industry benchmarks, VidIQ/TubeBuddy published data.

---

## CTR (Click-Through Rate)

Measures how often people who see your thumbnail click it.

| Tier | CTR | Interpretation |
|---|---|---|
| Poor | <2% | Thumbnail or title problem — not compelling in feed |
| Below average | 2–4% | Common for new channels or non-optimized thumbnails |
| Average | 4–6% | Typical for established channels |
| Good | 6–9% | Strong thumbnail + title alignment |
| Excellent | >9% | Top-tier CTR — sustainable only with strong content |

**Target for this channel:** ≥8%

**Note:** CTR is heavily influenced by impression volume. High-impression videos
(suggested/browse) naturally have lower CTR than search-discovered videos.
Always compare CTR within the same traffic source.

---

## Average View Duration (AVD)

How long the average viewer watches before leaving.

| % of video length | Interpretation |
|---|---|
| <30% | Severe hook or pacing problem |
| 30–40% | Below average — content or structure issue |
| 40–50% | Average for most YouTube content |
| 50–60% | Good — strong structure and pacing |
| >60% | Excellent — highly engaging content |

**Target:** ≥45% of total video length

For a 10-minute video: AVD target = 4.5 minutes

---

## Retention by timestamp

Critical retention checkpoints:

| Timestamp | Benchmark | Risk if below |
|---|---|---|
| 0:30 | 75–85% | Hook is failing |
| 1:00 | 65–75% | Intro too long |
| 2:00 | 55–65% | Content not delivering on promise |
| Midpoint | 40–55% | Pacing issue or open loop not sustained |
| End | 20–35% | Normal — very few viewers watch to the end |

**Key insight:** The drop from thumbnail click to 30-second retention is the most
important metric to optimize. Everything else follows from a strong hook.

---

## Engagement Rate

| Metric | Average | Good | Excellent |
|---|---|---|---|
| Like rate (likes/views) | 1–3% | 3–5% | >5% |
| Comment rate (comments/views) | 0.1–0.5% | 0.5–1% | >1% |
| Subscriber conversion (new subs/views) | 0.5–1% | 1–2% | >2% |

**Note:** Comment rate is highly content-dependent. Tutorial/how-to videos get fewer
comments than opinion/controversial content. Don't optimize for comments specifically.

---

## View velocity (first 48 hours)

Early velocity signals are used by YouTube's algorithm to decide ranking.

| Hours post-publish | Views target (est. by channel size) |
|---|---|
| 1h | ~1–2% of subscriber count |
| 24h | ~5–10% of subscriber count |
| 48h | ~10–15% of subscriber count |

These are rough heuristics. Track your own channel's baseline and compare each video
to your personal average, not industry averages.

---

## Channel-level health metrics

Review monthly:

| Metric | Healthy signal |
|---|---|
| Subscriber growth rate | >1% month-over-month |
| Upload frequency | Consistent cadence (1–4x/month) |
| Impressions trend | Stable or growing over 90 days |
| Revenue per mille (RPM) | Channel-dependent; track trend not absolute |
| Watch time hours (total) | Growing month-over-month |

---

## Postmortem scoring

Use this table in `state/projects/<id>/postmortem.md`:

```markdown
| Metric | Target | Actual | Delta | Grade |
|---|---|---|---|---|
| CTR | 8% | X% | +/-X% | A/B/C/D/F |
| AVD | 45% | X% | +/-X% | A/B/C/D/F |
| Retention @2min | 55% | X% | +/-X% | A/B/C/D/F |
| Like rate | 3% | X% | +/-X% | A/B/C/D/F |
| Sub conversion | 1% | X% | +/-X% | A/B/C/D/F |
```

Grade scale: A ≥ target+20% | B ≥ target | C ≥ target−15% | D ≥ target−30% | F < target−30%

---

## Tools for analytics

| Tool | Free tier | Best for |
|---|---|---|
| YouTube Studio Analytics | Full free | Official data, all metrics |
| TubeBuddy | Free + paid | SEO, A/B thumbnail testing, bulk processing |
| VidIQ | Free + paid | Keyword research, competitor analysis, trend alerts |
| Social Blade | Free | Historical channel growth tracking |
| Morningfa.me | Paid | Deep analytics, custom benchmarks |
| YouTube Data API v3 | Free (quota) | Programmatic access — used in this plugin |

See `resources/links/tools-and-resources.md` for direct links.
