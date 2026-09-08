---
created: 2026-08-08
updated: 2026-08-08
tags: [skill]
skill: true
name: Vault Cleanup
description: Fixes frontmatter, broken links and orphan notes. Never deletes anything.
icon: "~"
---

# Vault Cleanup

## Prompt

Read the Run log at the bottom of this note first, and apply anything learned there.

Tidy the vault without changing meaning:

1. Every note needs `created`, `updated` and `tags` frontmatter. Add what is missing;
   set `updated` only on notes you actually edit.
2. Find broken `[[wikilinks]]` -- targets that do not exist. Fix obvious typos; list
   the rest rather than guessing.
3. Find orphan notes (nothing links to them) and link them from the right index,
   or say why they should stay unlinked.
4. Do NOT delete anything. Report what looks deletable and let Mackenzie decide.

Report what you changed in one short paragraph, then a bulleted list of anything
you deliberately left alone and why.

## Run log

_Jarvis appends what it learned after each run. Read this before running._

### 2026-08-08
Frontmatter was already complete vault-wide and no wikilinks were actually broken -- the only "broken link" on record (`[[create a link]]`) lived in Obsidian's default `Welcome.md`, which had already been deleted since the last manual pass, so I just dropped the now-stale "Unfiled" note about it from Jarvis Home. The real find was orphans: the four skill notes plus `06 Skills/README.md` and the newest daily note (`2026-08-08`) had zero inbound links -- nothing pointed at the Skills folder from Jarvis Home at all. Fixed by adding a `## Skills` section there and bumping the "most recent daily note" pointer.
Next time: check Jarvis Home's Skills section stays in sync when a new skill note is added -- there's no automatic linkage, so a new skill file is an instant orphan until someone (me) links it by hand.
