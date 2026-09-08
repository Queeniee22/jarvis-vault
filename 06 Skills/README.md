---
created: 2026-08-08
updated: 2026-08-08
tags: [skills/index]
---

# Skills

Repeatable work, written down once and run on demand, by voice, or on a
schedule. Each skill is a note in this folder. The HUD reads this folder and
renders one button per skill.

## What each one actually does

Come here when you've forgotten what a button will do before you press it.

### ☀ Morning Brief — *runs itself at 7am*
Reads today's daily note, your open threads, your projects and today's calendar,
then writes a short `## Morning brief` into today's note: **the single most
important thing to do today and why**, anything time-bound, and any thread that
has gone quiet. Then says a two-sentence summary out loud.
**Press it when:** you want to know what to actually start on.

### \# Weekly Review — *runs itself Sundays at 6pm*
Does the weekly consolidation from `CLAUDE.md`: merges duplicate notes, fixes
stale facts, files the inbox, updates [[Jarvis Home]] so nothing is unreachable.
Then writes what genuinely changed this week, what stalled, and what you clearly
should have written down but didn't. It is told to be blunt.
**Press it when:** the vault feels messy, or you want an honest week in review.

### ~ Vault Cleanup — *only when you ask*
Housekeeping with no opinions: adds missing frontmatter, finds broken
`[[wikilinks]]`, finds orphan notes and links them from the right index.
**It never deletes anything** — it reports what looks deletable and leaves the
call to you.
**Press it when:** links are breaking or notes feel disconnected.

### ? Deep Research — *only when you ask*
Say the topic when you run it, or it will ask and stop rather than guess. It
searches the vault first (so it builds on what you already know), then writes a
new research note and links it from somewhere relevant so it isn't an orphan.
It's told to skip the encyclopaedia tone and say what matters *for your
projects* — including when something isn't worth your time.
**Press it when:** you're about to make a decision and want it thought through.

### > Job Hunt Brief — *runs itself Mondays at 9am*
Reads [[Job Hunt]] and chases what's gone quiet: any application with no contact
for a week, anything where you owe the next move. Gives you a **follow-up line you
can actually send**, not a template with blanks. If the pipeline is thin it says so
and suggests where to look for your stack.
**Press it when:** you're not sure who you're waiting on, or you've stalled.

### ! Interview Prep — *only when you ask*
Name the company and role, or it asks and stops rather than inventing a generic
interview. Pulls what the vault already knows, weights questions toward **React and
Python** since those are your live gaps, and builds answers out of *your real work* —
the Jarvis build has genuine stories in it. Then drills you on the question you're
least ready for.
**Press it when:** you have an interview booked.

### % Debug Log Miner — *only when you ask*
Reads your whole [[Debug Log]] looking for **patterns across entries**, not summaries
of them: the same kind of mistake recurring, constants guessed instead of measured,
bugs that keep being found late rather than by a test. Also says which patterns have
genuinely stopped — so it isn't just a pile of criticism.
**Press it when:** you want your own history to teach you something.

### o Evening Shutdown — *runs itself at 9pm*
The bookend to Morning Brief. Records what **actually** happened from evidence —
commits, notes edited, decisions made — not what you'd planned. Leaves the smallest
next action on anything still open, and refreshes [[Open Threads]] and [[Projects]]
so tomorrow's brief reads from something current.
**Press it when:** you're stopping for the day.

---

Every one of them appends to its own `## Run log` afterwards, and reads that log
before the next run. So they get better at your particular way of working
instead of repeating the same mistakes.

## Scheduled at a glance

| When | Skill |
|---|---|
| Daily 07:00 | Morning Brief |
| Daily 21:00 | Evening Shutdown |
| Mondays 09:00 | Job Hunt Brief |
| Sundays 18:00 | Weekly Review |
| On demand | Vault Cleanup · Deep Research · Interview Prep · Debug Log Miner |

## Anatomy of a skill

```yaml
---
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [skill]
skill: true              # required -- this is what makes it a skill
name: Morning Brief      # button label
icon: "*"                # optional, shown on the button
schedule: daily 07:00    # optional -- see below
output: 05 Daily/        # optional -- folder for the result note
---
```

Everything under `## Prompt` is what Jarvis is actually told to do.

## Schedules

| Format | Runs |
|---|---|
| `daily 07:00` | every day at 7am |
| `weekly sun 18:00` | Sundays at 6pm |
| `hourly` | on the hour |
| _omitted_ | only when you ask |

Times are local. A schedule that has already passed today does not
retroactively fire on startup.

## The loop

After a run, Jarvis appends to that skill's `## Run log`: what it did, what
was awkward, what to do differently. **Every future run reads that log first.**
That is what makes a skill sharpen with use instead of repeating the same
mistakes.

The prompt body itself is not rewritten automatically — a silently mangled
prompt is much worse than a slightly stale one. The log is where learning
accumulates, and you can fold it into the prompt yourself when a pattern is
clearly right.

## Writing a good skill

- Say what "done" looks like. A skill that ends ambiguously drifts every run.
- Name the note it should write and where. Otherwise output lands nowhere useful.
- Keep it to one job. Two jobs in one skill means neither can be scheduled alone.

Related: [[Jarvis Home]], [[Jarvis HUD Runbook]]
