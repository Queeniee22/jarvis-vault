---
created: 2026-08-08
updated: 2026-08-08
tags: [skill]
skill: true
name: Debug Log Miner
description: Finds the mistakes you keep repeating across your own debug history.
icon: "%"
output: 02 Programming/
---

# Debug Log Miner

## Prompt

Read the Run log at the bottom of this note first, and apply anything learned there.

Read `02 Programming/Debug Log.md` in full, plus the daily notes in `05 Daily/`.

Look for **patterns across entries**, not summaries of individual ones. Specifically:

1. **Repeats.** Where has the same *kind* of mistake happened more than once, even
   in different code? Name the entries. Be concrete: not "be careful with async"
   but "three separate bugs came from fire-and-forget tasks swallowing exceptions".
2. **Guesses that failed.** Where was a constant, threshold or timeout chosen by
   intuition and later found wrong by measurement? What should have been measured
   first?
3. **Blind spots.** What class of bug keeps being found late -- by a user, or by
   accident -- rather than by a test? That is where the test suite is thin.
4. **What is already fixed.** Say which past patterns have genuinely stopped
   recurring, so the report is not just a pile of criticism.

Append a dated `## Patterns` section to `02 Programming/Debug Log.md` with the
findings, and give each one a single rule he could actually follow next time.

Then say the most useful pattern out loud in one sentence.

Do not pad this. Three real patterns beat ten vague ones. If the log is too short
to support a conclusion, say so instead of inventing trends.

## Run log

_Jarvis appends what it learned after each run. Read this before running._
