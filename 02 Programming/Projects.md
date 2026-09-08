---
created: 2026-08-06
updated: 2026-08-08
tags: [programming/projects]
---

# Projects

One section per project. Claude: keep `Status` and `Next` current; they're what you read first.

## Template

```
### <Project name>
- **Repo/path:**
- **Stack:**
- **Status:** active | paused | shipped | dead
- **Purpose:** one line
- **Next:** the single next action
- **Gotchas:** things that bit us before
```

---

##### Jarvis — Personal AI Assistant
- **Repo/path:** vault `C:\Users\Mackenzie\Jarvis` · code `C:\Users\Mackenzie\jarvis-hud` (separate git repo, deliberately outside the vault)
- **Stack:** Python 3.13 + FastAPI/uvicorn backend, vanilla JS + Canvas frontend. Claude Code CLI as the brain, faster-whisper (local STT), ElevenLabs (cloud TTS), Obsidian Local REST API, Google Calendar. Detail in [[Jarvis HUD Design]]; how to run it in [[Jarvis HUD Runbook]].
- **Status:** active — built and running daily. 132 backend + 56 frontend tests passing.
- **Purpose:** A personal Jarvis — voice interface, coding/debugging assistant, job search helper, daily reminders, productivity/learning optimization
- **Next:** use it for a week and fix what actually annoys you. Nothing is blocked.
- **Gotchas:**
  - MCP port conflict with the Cheat Sheet vault — fixed, Jarvis owns 27126 (HTTPS) / 27125 (HTTP)
  - `mcp-remote` argument-splitting bug with spaces in the auth header — sidestepped via native `--transport http`
  - ~~voice pause detection cuts in mid-sentence~~ — **resolved 2026-08-07** by dropping automatic endpointing for push-to-talk, see [[Debug Log]]
  - `.env` values must be bare: an `OBSIDIAN_API_KEY` pasted with a `Bearer ` prefix sent `Bearer Bearer <key>` and failed auth silently
  - a leftover server holding port 8770 will serve **stale code** and make you debug a change that already works — `run.py` refuses to start and names the PID, so read its output
  - the ElevenLabs free tier is 10,000 chars/month; past that it returns `401` (not 429) and Jarvis falls back to the local Windows voice
- **Inspiration:** Similar setups seen online combining Claude Code with a voice/UI frontend
