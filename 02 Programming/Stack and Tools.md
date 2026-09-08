---
created: 2026-08-06
updated: 2026-08-08
tags: [programming/stack]
---

# Stack and Tools

What Mackenzie actually uses, and the decisions behind it.

## Known installed (observed 2026-08-06)

- Obsidian 1.12.7
- Claude Code (`~/.claude`)
- Docker Desktop
- Ollama (`~/.ollama`)
- Cursor, GitHub Copilot, Codex configs present
- .NET SDK

## Languages

**Fluent:** TypeScript, JavaScript, Java, PHP, SQL, Node.js
**Learning:** React.js, Python

## Conventions

_TBD — formatter, linter, package manager preferences_

### jarvis-hud

- **Tests:** pytest, TDD throughout. Run `.venv/Scripts/python -m pytest -q`.
- **Secrets:** `.env` at the repo root, gitignored. Values are bare — no `Bearer ` prefix.
- **Comments explain WHY, not what.** The codebase is consistent about this; match it.
- **Every integration degrades gracefully.** A dead service broadcasts a `status` message and the HUD keeps running rather than crashing.

## Decisions

> Format: date — decision — why — what we rejected

- **2026-08-06 — Graphical web HUD, not a terminal TUI.** The pastel/pixel look needs real graphics — glows, a particle sphere, an animated graph — that text cells can't draw. *Rejected:* Python + Textual (the original plan), Electron (same fidelity, heavier to package).
- **2026-08-06 — Code lives outside the vault**, in its own repo. A `.venv`, `__pycache__`, a ~150 MB Whisper model and a `.env` full of secrets have no business in a notes vault that Obsidian indexes and graphs. *Rejected:* a `jarvis-hud/` folder inside the vault.
- **2026-08-06 — The brain routes through the Claude Code CLI, not the Anthropic API.** The CLI is what gives Jarvis the vault, MCP and tools; the raw API is a bare model call with no memory. *Rejected:* direct API — faster, but it would have broken the whole point.
- **2026-08-07 — Push-to-talk, not open mic.** Automatic endpointing was tuned three times (0.6s → 1.5s → 2.0s, plus start/continue hysteresis) and still cut Mackenzie off. Releasing a key *is* the end of the turn, so the guess disappears entirely. *Rejected:* a fourth round of threshold tuning.
- **2026-08-07 — Measured: the ~5s voice latency is not tunable.** haiku 5.00s vs sonnet 5.15s; disabling MCP was *slower* (4.73s vs 4.15s). It is fixed CLI startup, not model or MCP time. Mitigated with a spoken "thinking" filler instead of a model swap. *Rejected:* switching to haiku, which would have gained nothing.
- **2026-08-07 — Bash is allowlisted, not open.** A voice assistant acting on a misheard phrase must not get an unrestricted shell.
- **2026-08-08 — One writer task per websocket**, not a shared lock. Makes concurrent `send_json` on a socket impossible by construction. *Rejected:* a lock around broadcast — it was left un-held during client catch-up, a real interleaving bug.

Related: [[Projects]], [[Jarvis Home]], [[Jarvis HUD Design]], [[Jarvis HUD Runbook]]
