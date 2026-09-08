---
created: 2026-08-08
updated: 2026-08-08
tags: [programming/jarvis, runbook]
---

# Jarvis HUD Runbook

How to run Jarvis, what it needs, and what to check when a panel goes dark.
Design rationale lives in [[Jarvis HUD Design]]; bugs and their real causes in [[Debug Log]].

## Start it

```
cd C:\Users\Mackenzie\jarvis-hud
.venv\Scripts\python run.py
```

Then open `http://127.0.0.1:8770` and press F11. Boot takes ~15s: it loads the
Whisper model, reads the vault, then greets aloud.

## Tests

Two runtimes, so two runners. One command covers both:

```
.venv\Scripts\python run_tests.py
```

Or separately:

| Suite | Command | Count |
|---|---|---|
| Backend | `.venv\Scripts\python -m pytest -q` | 132 |
| Frontend | `npm test` | 56 |

The frontend harness is Node's built-in runner plus **jsdom** — one dependency,
no build step. `tests/js/hud-dom.mjs` loads a file from `static/js` into a
throwaway DOM with a fake canvas context that *records* draw calls, so tests
assert on what was drawn rather than on pixels. Add new frontend tests as
`tests/js/<name>.test.mjs`.

Run `npm install` once before the first `npm test`.

## Using it

| Action | How |
|---|---|
| Talk to Jarvis | **Hold `SPACE`** (or hold the mic button), talk, release. Release ends the turn. |
| Interrupt him | Press the talk key while he's speaking |
| Answer a question | Click an option card, or press its **number key** |
| Read a note | **GRAPH** tab → click a node. Opens beside the graph. |
| Edit a note | Type in the note panel → **Ctrl+S** |
| Type instead of talk | The chat box in the right rail. `SPACE` types normally there. |
| Run a skill | Click it in the SKILLS panel, or say "run the morning brief". Hover for what it does. |
| Search the graph | GRAPH tab → the search box. `#tag` works. `Enter` opens the top hit, `Esc` or `x` clears. |

Spoken turns deliberately stay out of the chat panel — what he heard shows as a
fading caption under the waveform instead.

## Configuration

`.env` at the repo root, gitignored. **Values are bare — no `Bearer ` prefix.**

| Key | Purpose | If missing |
|---|---|---|
| `ELEVENLABS_API_KEY` | Voice out | Silent; chat still works |
| `VOICE_ID` | Which voice | Must be a voice **in your account** — library voices need adding to *My Voices* first |
| `OBSIDIAN_API_KEY` | Vault + graph | Vault panel and graph show offline |
| `OBSIDIAN_PORT` | `27126` (HTTPS, self-signed) | — |
| `GOOGLE_CALENDAR_ID` | `primary` | — |

Current voice: **Jessica** `cgSgspJ2msm6clMCkdW9` — a free *premade* voice, no
subscription needed.

## Skills

Repeatable work as vault notes in `06 Skills/` — see [[06 Skills/README|Skills]] for
what each one does and how to write a new one. Adding a skill needs **no code**: a
note with `skill: true` and a `## Prompt` becomes a button.

Scheduled: Morning Brief 7am · Evening Shutdown 9pm · Job Hunt Brief Mondays 9am ·
Weekly Review Sundays 6pm.

## Google Calendar setup

Done — the TODAY panel shows real events. Kept here for when the token expires.

1. [console.cloud.google.com](https://console.cloud.google.com/) → create/pick a project
2. **APIs & Services → Library** → enable **Google Calendar API**
3. **Credentials → Create Credentials → OAuth client ID → Desktop app** → download JSON as `credentials.json` in the repo root
4. **OAuth consent screen** (newer console: *Google Auth Platform → Audience*):
   - User type must be **External** — *Internal* rejects personal Gmail
   - Add `connermackenzie2003@gmail.com` under **Test users**, or the consent screen returns `Error 403: access_denied`
   - Click **PUBLISH APP** — while in *Testing*, Google expires refresh tokens after **7 days** and the calendar silently dies weekly. The "unverified app" warning at consent is expected (*Advanced → Go to (unsafe)*).
5. `.venv\Scripts\python scripts\gcal_auth.py` → consent in the browser → writes `token.json`
6. Restart the HUD

Scope is read-only. `credentials.json` and `token.json` are gitignored.

## When something goes dark

Panels never crash the HUD — a broken service shows an offline state and the
rest keeps running. The hub replays the last state to each new page, so a
refresh shows the current situation immediately instead of waiting for the next
poll.

| Symptom | Likely cause |
|---|---|
| Vault/graph offline | Obsidian isn't running, or the plugin's key changed. Check `https://127.0.0.1:27126` answers. |
| "calendar offline — not authorized" | OAuth not done — see above |
| "calendar access expired" | Refresh token died (the 7-day *Testing* expiry). Re-run `scripts/gcal_auth.py`, and publish the app to stop it recurring. |
| No voice, chat fine | `VOICE_ID` isn't in the ElevenLabs account, or no key |
| Voice sounds robotic | ElevenLabs quota used up (10k chars/month) — it fell back to the local Windows voice. Restart after the reset. Service row shows **degraded**. |
| A change doesn't show up | A leftover server is holding 8770 and serving stale code. `run.py` refuses to start and names the PID — read its output. |
| A skill did nothing | Hover it for its state; check its `## Run log` in the note. Skills run one at a time — a second click while one is running reports busy. |
| Mic seems dead | Check the waveform moves while holding `SPACE`. `scripts/mic_test.py` and `scripts/ears_test.py` test the mic and the full transcribe path. |
| Replies take ~5s | Expected. Fixed Claude CLI startup, not tunable — see [[Stack and Tools]] § Decisions. The spoken filler covers it. |

## Diagnostic scripts

- `scripts/mic_test.py` — records you, reports signal levels, verdict on whether the mic works
- `scripts/ears_test.py` — records, gates, transcribes: the exact path the HUD uses, prints the transcript
- `scripts/gcal_auth.py` — one-time Google consent

Related: [[Jarvis HUD Design]], [[Projects]], [[Debug Log]], [[Stack and Tools]], [[Jarvis Home]]
