---
created: 2026-08-06
updated: 2026-08-08
tags: [programming/jarvis, design]
---

# Jarvis HUD Design

> Supersedes the earlier terminal-TUI plan. Decided 2026-08-06: **graphical web HUD**, not Textual. The pixel/pastel references (V.A.U.L.T.-style command centers) need real graphics — glows, pixel-art, a particle-sphere core, an animated graph — that a text-cell TUI can't render.

## Aesthetic
- Pixelated, pink, pastel, cute.
- **Palette:** lilac `#C9B6E4`, blush `#F7B7CE`, cotton `#F9D5E5`, mint `#B8E6C4`, butter `#F7E5A0`, cream bg `#FFF5FA`, ink `#6B5876`, deep `#8A5A7A`.
- Pixel fonts: **Press Start 2P** (logo/headers), **Pixelify Sans** (body). Bundled locally, no CDN.
- Soft layered glows, never harsh neon. `image-rendering: pixelated`.
- HUD frame is pastel; the **core panel is dark plum** so the glowing particles have contrast (pastel-on-cream washes out — this was the fix).

## Architecture

Three local layers on Windows:

```
FRONTEND — pastel-pixel HUD (browser, fullscreen F11)
  HTML/CSS/JS, no framework. Canvas for core + graph.
  Talks to backend over ws://localhost + REST.
        │
BACKEND — Python (FastAPI + uvicorn), one `python jarvis.py`
  ├ vitals    psutil → CPU/RAM/disk, pushed live over WS
  ├ brain     shells out to `claude -p --output-format stream-json`,
  │           streams tokens into chat; passes history + Jarvis
  │           personality system prompt each turn
  ├ ears      faster-whisper (local) → mic audio to text; emits live
  │           mic amplitude for the pink waveform
  ├ voice     ElevenLabs API → TTS audio out; emits output amplitude
  │           so the core sphere reacts while speaking
  ├ vault     Obsidian MCP client → projects/threads + note/link graph
  └ calendar  Google Calendar OAuth (read-only) → today's events
```

Browser HUD over Electron: same visual fidelity, nothing to package, open fullscreen like a kiosk.

## Layout (single screen)

- **Header** (full width): pixel logo, live **12-hour AM/PM** clock.
- **Left rail:** System vitals (CPU/RAM/disk bars) · Today (calendar) · Voice (mic dot + pink waveform).
- **Center (dominant):** the CORE — takes the middle of the screen. Tabbed:
  - **✿ CORE** — rotating particle-sphere (Fibonacci-distributed point cloud, depth-shaded, pastel glow). **Swells + brightens when the assistant speaks** (driven by ElevenLabs output amplitude).
  - **✿ GRAPH** — force-directed render of the **real Obsidian vault** (notes = nodes, `[[wikilinks]]` = edges) pulled via the Obsidian MCP, styled pastel. Same second-brain, our renderer (Obsidian's own graph pane isn't embeddable).
- **Right rail:** Vault status · Skills · Chat (Claude Code stream + text input).

## Reactive elements
- **Core sphere** ↔ TTS output amplitude (speaking → swell/brighten/glow).
- **Pink mic waveform** ↔ live mic input amplitude (listening).
- Backend streams both amplitude signals over the WebSocket.

## Integrations & setup (Mackenzie does the keyed/OAuth parts)
- **Brain:** Claude Code CLI, `claude -p ... --output-format stream-json`. Fresh invocation per turn → pass conversation history + personality prompt each time. Higher per-turn latency than raw API; acceptable.
- **Ears:** faster-whisper; first run downloads a model (~150 MB, `small`). Needs a working mic.
- **Voice:** ElevenLabs. `ELEVENLABS_API_KEY` in `.env` (Mackenzie sets it; Claude never handles the key). Reply text goes to ElevenLabs cloud; everything else stays local.
- **Vault:** Obsidian MCP (existing server, ports 27126/27125). Panel + graph show a friendly "offline" state if it's down.
- **Calendar:** Google Calendar read-only via OAuth. One-time setup Mackenzie clicks through (Google Cloud project → `credentials.json` → consent flow). Scripted, but she consents in-browser.
- **Secrets:** `.env`, gitignored. No keys in code.

## Graceful degradation
Every integration degrades independently — a dead MCP, unset ElevenLabs key, or un-authed calendar shows an "offline" panel and never takes down the HUD. Shell + vitals + chat work even before voice/calendar are configured.

Degrading only works if the "offline" message actually arrives, which is a property of `ConnectionHub` (`jarvis/hub.py`), not of the services:

- **One outbound queue + one writer task per socket.** Not a shared lock. A socket that stops draining (slept laptop, wedged tab) can't stall broadcasts to any other client, and the hub is never inside `send_json()` twice on one connection.
- **Catch-up is queued by `hub.add()`**, not sent by a separate call afterwards. Services broadcast on slow cycles (vault 60s, calendar 300s) and the offline notices fire once at startup before any browser exists; a late client is caught up at registration, behind which live broadcasts simply append. Ordering needs no lock because catch-up and live traffic share one queue.
- **Backlog overflow collapses, it doesn't disconnect.** The queue keeps the newest value per state type and discards superseded transients (mic amplitude, chat deltas). Dropping the client would be worse — `hud.js` opens one WebSocket with no reconnect, so a dropped client is a dead page until a manual refresh.
- Only messages classed as state are remembered and replayed. Transients are moments; replaying them would render a stale conversation on a fresh page.

## Stack
- Frontend: vanilla HTML/CSS/JS + Canvas. Pixel fonts bundled locally.
- Backend: Python — FastAPI, uvicorn, psutil, faster-whisper, subprocess for Claude Code CLI, google-api-python-client, an Obsidian MCP client.
- Run: `python jarvis.py`, open `http://localhost:<port>` fullscreen.

## Decided
- **Repo:** separate git repo `C:\Users\Mackenzie\jarvis-hud`, NOT inside the vault — keeps `.py`/`__pycache__`/`.venv`/Whisper model/`.env` out of Obsidian's index and graph.
- ~~**Listening:** open mic (always-on) + a mute button.~~ **Superseded 2026-08-07 → push-to-talk.** See below.

## As built — where reality diverged from this spec

This document is the design as *planned*. Three things changed once it ran:

1. **Push-to-talk replaced open mic.** Automatic endpointing cut Mackenzie off
   mid-sentence; three rounds of threshold tuning didn't fix it. Holding a key
   removes the guess rather than refining it. The mute button became a talk
   button. → [[Debug Log]]
2. **The core panel is dark plum, not pastel.** Glowing pastel particles on a
   cream background wash out — the sphere was invisible. Only the *inside* of
   the core went dark; the HUD frame stayed pastel.
3. **Voice latency is ~5s and can't be tuned.** Measured, not assumed: model
   choice and MCP loading are both irrelevant; it's fixed CLI startup. Covered
   with a spoken "thinking" filler. → [[Stack and Tools]] § Decisions

Features added after this spec was written:
- **Clickable option cards** — when Jarvis asks a real either/or, it renders as
  buttons (click or number key) instead of requiring a spoken answer
- **Interactive graph** — click a node to read that note beside the graph, edit
  it, Ctrl+S to save back to the vault
- **Fading "heard" caption** — shows what the mic understood, without putting a
  transcript in the chat panel
- **File access + allowlisted shell** — Jarvis can read/edit files across the
  home directory and its own source

## Skills — added 2026-08-08

The third pillar, and the only one the original spec didn't anticipate.

A skill is **a note, not code** (`06 Skills/*.md`): frontmatter (`skill: true`,
`name`, `description`, `icon`, optional `schedule`, `output`), a `## Prompt` body,
and a `## Run log`. The HUD renders one button per skill. They run headless on
click, by voice ("run the morning brief"), or on a schedule.

Notes rather than config for one reason: **Jarvis can read, run and improve them
himself**, and they appear in the vault graph like everything else.

**The loop:** after each run Jarvis appends to that skill's `## Run log` — what it
did, what was awkward, what to do differently. Every future run reads that log
first, so a skill sharpens with use.

**Deliberately not self-rewriting.** The `## Prompt` body is never edited
automatically. A silently mangled prompt is far worse than a slightly stale one and
you would have no way to notice. Learning accumulates in the log, where it is
auditable, and can be folded into the prompt by hand once a pattern is clearly right.

Schedules are a deliberately small language (`hourly`, `daily HH:MM`,
`weekly <dow> HH:MM`) — no cron dependency, and a schedule already passed today does
not fire retroactively on startup.

## Voice degradation — added 2026-08-08

ElevenLabs' free tier runs out monthly, and it reports an exhausted quota as `401
Unauthorized` — indistinguishable from a bad key unless you read the response body.
Jarvis now detects that specifically and falls back to the **local Windows voice**
(pyttsx3/SAPI): free, offline, unlimited, worse-sounding. Reported as `degraded`
rather than online or broken, because the fix differs from both.

Going silent because a monthly quota ran out is a bad failure mode for something you
talk to.

## Status

All seven phases complete plus skills. **132 backend + 56 frontend tests.** Nothing
outstanding. Day-to-day operation → [[Jarvis HUD Runbook]].

Related: [[Projects]], [[Stack and Tools]], [[Jarvis HUD Runbook]], [[Debug Log]]
