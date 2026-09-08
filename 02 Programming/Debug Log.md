---
created: 2026-08-06
updated: 2026-08-08
tags: [programming/debugging]
---

# Debug Log

Problems that cost real time, and how they were actually fixed. Check here before debugging anything that feels familiar.

## Format

```
### <symptom as you'd search for it>
- **Date:**
- **Context:** project, environment
- **Cause:** the real one, not the first guess
- **Fix:**
- **Tell:** how to recognise it faster next time
```

---

### `ValueError: Separator is found, but chunk is longer than limit` / `asyncio.LimitOverrunError` when streaming subprocess output

- **Date:** 2026-08-06
- **Context:** `jarvis-hud`, `jarvis/services/brain.py` — `ask()` streaming `stream-json` lines from the Claude CLI. Surfaced during Phase 4 (ears/mic) live testing.
- **Cause:** `async for line in proc.stdout` iterates an asyncio `StreamReader`, which calls `readline()`. If a line exceeds the reader's limit, `readline()` raises `ValueError` and `async for` lets it escape. Raising `limit=` alone is **not** a fix — it only moves the ceiling. The real bug is that there was no handler, and `ask()` is launched with `asyncio.create_task()`, so the exception died inside the orphaned task: no traceback in the console, no reply in chat, no `done` sentinel, so the HUD's chat line stayed open forever.
- **Fix:** a `brain.iter_lines()` wrapper that calls `readline()` in a loop and catches `ValueError` / `LimitOverrunError`. `readline()` already drains the offending data before it raises, so the bad line can simply be skipped and reading continues (verified against a real subprocess, not just a mock). Plus: `try/except/finally` in `ask()` broadcasting a friendly error and *always* emitting `done: True`; concurrent `stderr` drain; a cap on consecutive read errors.
- **Tell:** chat goes silent for exactly one turn with **no traceback anywhere** → look for an exception escaping a fire-and-forget `create_task()`. Any `create_task()` whose coroutine can raise needs its own handler; nothing upstream will catch it. And a `limit=` bump is a mitigation, never the fix.

#### Two traps worth remembering

- **Unread `stderr=PIPE` is a deadlock.** `ask()` opened a stderr pipe and never read it. A chatty subprocess fills the OS pipe buffer and blocks mid-reply, forever. If you open a pipe, drain it.
- **Retrying without an `await` wedges the event loop.** An `except: continue` on a path with no await point spins the loop at 100% instead of merely failing — worse than the crash it replaces. Guard retry loops with a bail-out count.

---

### Graph tab spinner never resolves to real data (jarvis-hud)

- **Date:** 2026-08-08
- **Context:** `jarvis-hud`, graph tab. `static/js/graph.js` used to fall back to an animated mock node/link simulation whenever `state.graph` was `null`, so it always looked "alive" even with zero real data.
- **First diagnosis — wrong, both branches disproven (2026-08-08).** Suspected `vault.run()`'s `if not _api_key(): ... return` bail-out, either because the key was unset (a) or because the running process predated it (b). Probed every boundary instead of guessing: `OBSIDIAN_API_KEY` is set (64 chars), the Obsidian REST API on 27126 answers `200`, `list_files()` returns 22 files, `build_graph()` returns 22 nodes / 56 links. Connecting a websocket to the *live* server confirmed it emits `graph` and `vault` messages. The vault was never broken and no restart was needed.
- **Actual cause:** a delivery bug, not a vault bug — and the same one as the calendar-offline notice. `vault.run()` broadcasts the graph ~1.7s after startup, before any browser has connected, and `ConnectionHub` had no memory of what it had sent. The page then waited up to 60s for the next cycle, which reads as "spins forever".
- **Fix:** `ConnectionHub` now caches the last state per service and replays it at `hub.add()`. Separately, `applyStatus()` in `static/js/hud.js` now renders vault outages (it only handled calendar), and `static/js/graph.js` draws "vault offline — <reason>" instead of spinning a lie.
- **Follow-on found while fixing:** the hub caches the last status forever, but no service ever broadcast recovery — one transient failure at boot meant every future client was told the vault was offline. `vault.run()` now reports transitions (`online`/`offline`) instead of re-broadcasting offline every cycle. **`gcal.py` still has this gap.**
- **Tell:** a panel that is empty or spinning with no error is a *delivery* question before it is a service question. Check whether the service broadcast before anyone was listening, and whether a stale cached status is outliving the condition it described.

---

### Voice endpointing cuts me off mid-sentence

- **Date:** 2026-08-07
- **Context:** `jarvis-hud`, `jarvis/services/ears.py`. Open-mic mode decided end-of-turn by watching for a run of quiet audio blocks.
- **Cause:** there isn't a correct threshold. Speech has a wide dynamic range — soft syllables, trailing word endings, breaths between phrases all dip under any bar you pick, and a quiet mic (peak frame ~0.0084) sits close to the bar to begin with. Tuned 0.6s → 1.5s → 2.0s and added start/continue hysteresis; it still interrupted.
- **Fix:** deleted the heuristic. **Push-to-talk**: hold `SPACE`, release to send. Releasing *is* the end of the turn, so there is no threshold, no hysteresis and nothing to infer. Kept a 0.3s pre-roll so reaction time doesn't clip the first syllable.
- **Tell:** when a heuristic needs its **third** round of tuning and you cannot reproduce the failure locally, stop tuning. Remove the guess — change the interaction so the ambiguity can't arise.

---

### Transcription silently never runs (no error, mic clearly working)

- **Date:** 2026-08-07
- **Context:** `jarvis-hud`, `ears.py`, immediately after rewriting the capture loop for push-to-talk.
- **Cause:** self-inflicted. Rewriting the surrounding block left the whole transcribe-and-dispatch section indented *inside* an `if not has_speech(audio): continue` branch — i.e. after a `continue`, therefore unreachable. Python raises nothing for this. The mic captured, levels moved, and the code that turned audio into words was simply dead.
- **Fix:** re-indented to the loop body. Added an AST check that scans for statements following a `continue`/`return`/`raise` in the same block.
- **Tell:** "the input side clearly works but nothing downstream happens, and there is no error" → suspect unreachable code before suspecting logic. After any large re-indentation, verify the moved block is still at the depth you think it is.

---

### Auth fails silently with a valid-looking API key

- **Date:** 2026-08-06
- **Context:** `jarvis-hud` → Obsidian Local REST API. Endpoint answered `200` but reported `authenticated: false`.
- **Cause:** the `.env` value had been pasted **with** its `Bearer ` prefix, and the client adds its own. The wire carried `Authorization: Bearer Bearer <key>`.
- **Fix:** store the bare key; `config.py` also strips a leading `Bearer ` defensively.
- **Tell:** a 200 with `authenticated: false` is a *malformed* credential, not a wrong one. Print the header's shape (never the value) before assuming the key itself is bad. Same class of bug as an ElevenLabs `VOICE_ID` that is syntactically fine but not in your account.

---

### Canvas clicks land on the wrong element

- **Date:** 2026-08-08
- **Context:** `jarvis-hud`, `static/js/graph.js` — making vault graph nodes clickable.
- **Cause:** the canvas has an internal buffer size (640×640) and a *different* CSS display size (284×284 in split view — scale 2.25). `offsetX`/`offsetY` are in CSS pixels; the node positions are in buffer pixels. Using them directly puts every hit test off by the scale factor, worse the further from the origin.
- **Fix:** convert explicitly — `(e.clientX - rect.left) * (canvas.width / rect.width)`, same for Y.
- **Tell:** any canvas with `max-width`/`max-height`/responsive CSS has two coordinate systems. If clicks feel "off toward the edges", it's the scale factor, not your hit radius.

---

### A panel stays empty because nobody was listening yet

- **Date:** 2026-08-08
- **Context:** `jarvis-hud`. Calendar and vault status broadcast once at startup; the browser connects a moment later and never sees them. Also the graph-spinner entry above.
- **Cause:** `ConnectionHub.broadcast()` sends to whoever is currently connected. Services start before any page loads, so startup messages went to zero clients and were gone.
- **Fix:** the hub remembers the latest *stateful* message per service and replays it to each new connection. Transient messages (mic level, chat deltas, speech amplitude) are deliberately **not** replayed — a fresh page must not render a stale conversation.
- **Tell:** "it works if I restart at the right moment" is a delivery-timing bug. Ask whether the producer ran before the consumer existed.

---

### Two Claude sessions editing one file

- **Date:** 2026-08-08
- **Context:** `jarvis-hud`, `jarvis/hub.py`. A background session and the main session were both fixing the same race.
- **Cause:** running two agents against one file. The tree ended up with one session's tests and the other's implementation — five failures that were pure collision, not real breakage.
- **Fix:** stopped editing, let the background session land its commit, then re-verified. Its design (one writer task per socket) was better than the main session's (a lock, which had been left un-held during catch-up — a genuine interleaving bug).
- **Tell:** don't parallelise two agents onto the same file. If it happens, the fix is to *stop and let one land*, not to race it. Check `git status` before assuming a test failure is real.


---

### A threshold that can never be reached ("SIM STABLE" never appears)

- **Date:** 2026-08-08
- **Context:** `jarvis-hud`, `static/js/graph.js`. The graph tab's NODES/LINKS/FPS readout was hardcoded mockup text (902 nodes, 3611 links, 60 fps) that never changed. While wiring it to real values, the settling indicator was given a "stable if per-node energy < 0.05" test.
- **Cause:** guessed constant. Measured afterwards: this force layout starts around 0.77 per-node energy, decays, and **asymptotes at ~0.365** — constant repulsion balanced against springs leaves permanent residual motion, so it never approaches zero. The readout would have said SETTLING forever, on any vault.
- **Fix:** stop testing an absolute value; test whether the value has stopped *changing*. Keep the last 12 samples and call it settled when `(max - min) / mean < 0.05`. Works for any vault size and any equilibrium value.
- **Tell:** before writing `x < someConstant`, log what `x` actually does over time. This is the same mistake as the mic gate — two guessed thresholds in one project, both wrong, both cheap to have measured first. If a state is never observed in testing, suspect it is unreachable rather than rare.

#### Also worth knowing

**`requestAnimationFrame` does not run in a hidden tab.** FPS read 0 and the layout never settled while testing through a non-displayed browser pane — measured 1 rAF tick/second versus ~60 when visible. Not a bug in the code under test. When frame-rate-dependent behaviour looks broken in automation, check `document.visibilityState` before debugging the logic.


---

### Resources leaked on cancellation (orphaned processes, claimed mic)

- **Date:** 2026-08-08
- **Context:** `jarvis-hud`. Found by auditing lifecycle paths rather than by a symptom — all of these were invisible in normal use.
- **Causes and fixes:**
  - `brain.ask()` caught `asyncio.CancelledError` and re-raised **without killing the `claude` subprocess** — the kill only lived in the `except Exception` branch. Every cancelled turn orphaned a Node process. Now killed in `finally`, along with the `stderr` reader task.
  - The `finally` block still emitted a reply and queued **TTS during shutdown**, scheduling work onto a loop that was going away.
  - `ears.run()` never stopped its `InputStream`, so PortAudio kept the microphone claimed after cancellation.
  - Services were started with bare `asyncio.create_task(...)` and the task objects discarded. **The event loop keeps only weak references** — a long-running service can be garbage-collected mid-run and silently stop. Now held in a set and cancelled on shutdown.
  - `note_open`/`note_save` awaited a vault HTTP round-trip **inline in the websocket receive loop**, so a slow save blocked every later message — including the push-to-talk release. Now spawned.
- **Tell:** anything opened (subprocess, audio stream, pipe) needs a `finally`, not just an `except`. `except CancelledError: raise` is not cleanup. And a bare `create_task()` whose result you drop is a task you may lose.

#### The trap that bit the fix itself

**`return` inside `finally` swallows the exception on its way out.** The first fix used `if cancelled: return reply` in the `finally` block, which discarded the propagating `CancelledError` and turned a cancelled turn into a silent normal return — breaking the very shutdown it was meant to fix. Caught only because a test asserted the task actually raises `CancelledError`. Guard with `if not cancelled:` instead of returning.


---

### "401 Unauthorized" from ElevenLabs that was not an auth problem

- **Date:** 2026-08-08
- **Context:** `jarvis-hud`, voice prewarm. Six warnings at startup, `prewarmed 0 ack phrases`, Jarvis silent.
- **Cause:** the API key was fine. The **free tier quota was exhausted** (10,000/10,000 characters). ElevenLabs reports that as `401 Unauthorized`, which reads exactly like a revoked key. `GET /v1/user` returned 200 with `character_count: 10000 / 10000`; the TTS body said `"code": "quota_exceeded", "You have 0 credits remaining"`.
- **Fix:** detect the quota case specifically and fall back to the local Windows voice (pyttsx3/SAPI) — free, offline, unlimited. Status reports `degraded` rather than online or broken, because the fix is different from both. The cloud is not retried once the quota is known gone; that would be pure latency before every line.
- **Tell:** when an auth error appears suddenly on a key that never changed, check the *quota* before the credential. Read the response **body**, not the status code — vendors overload 401. And when adding a paid dependency, decide up front what happens when it runs out; "goes silent" is a bad answer for something you talk to.

#### The fix had its own bug

`_is_quota_error` assumed the error body's `detail` was always a dict, but ElevenLabs returns a bare string for genuine auth failures — so a *real* bad key would have crashed with `AttributeError` inside the fetch path. Caught only because a test asserted that a real auth failure is **not** misread as a quota problem. Test the negative case, not just the one you're fixing.

---

### Tests that quietly used the network (and one that cost money)

- **Date:** 2026-08-08
- **Context:** `jarvis-hud` test suite. Started as an investigation into an `InsecureRequestWarning` in the pytest output.
- **Cause:** adding a re-list-on-miss to `vault.is_known_path` made an existing unit test start making **live HTTPS calls to whatever Obsidian happened to be running**. Its result depended on the developer's machine, and it would have failed outright if the vault contained a note called `B.md`.
- **Fix:** a `conftest.py` fixture that fails any test making a real HTTP call, with `@pytest.mark.allow_network` as the opt-out.
- **What it immediately caught:** `test_ask_streams_deltas_and_closes` had been calling the **real ElevenLabs API on every run** — billed, slow, and dependent on the key being set. Nobody would ever have noticed; it just quietly worked.
- **Tell:** a warning in test output is worth ten minutes. And "my change made an *existing* test non-hermetic" is a real failure mode — when you add I/O to a function, check who already calls it. Block the network in tests by default; the leak you don't know about is the expensive one.

#### Block at the right layer

The first version blocked `socket.connect` and broke 28 tests — on Windows, asyncio uses real sockets for its own internal self-pipe, so blocking those breaks the event loop rather than catching bad tests. Blocking at the `requests` layer targets external calls only.

---

### A silent-failure design that kept recurring (three times)

- **Date:** 2026-08-08
- **Context:** `jarvis-hud`, `ConnectionHub`. Calendar status, then the vault graph, then the skill list.
- **Cause:** the hub replayed only an **opt-in list** of "stateful" message types to newly connected clients. Every new panel therefore worked in tests and failed in the browser until someone remembered to add its type to that list — and the failure was a silently empty panel, not an error.
- **Fix:** inverted it. List the *transients* (mic amplitude, chat deltas, one-off run progress) and replay everything else by default. New panels are almost always state, so the safe default is to replay. Regression test uses a deliberately unknown message type.
- **Tell:** if the same bug class arrives three times, the design is wrong, not the developers. Ask which way round the default should be: **the failure mode of forgetting should be visible, not silent.** An opt-in list where omission fails quietly is the wrong shape.

---

### Verifying against a server running stale code

- **Date:** 2026-08-08
- **Context:** added skill descriptions, confirmed the code was right, and the browser still showed "No description yet".
- **Cause:** an older server was still holding port 8770. `run.py` correctly refused to start the new one and printed exactly which PID to kill — and I didn't read its log. The stale process kept serving.
- **Fix:** none needed in the code; the port guard already existed and worked. The lesson is procedural.
- **Tell:** when a change doesn't show up in a running app, check you're talking to the process you think you are **before** debugging the change. On Windows: `netstat -ano | findstr :8770`. Kill leftover servers when you finish verifying — a stale one blocks the next person and lies to you in between.


Related: [[Projects]], [[Stack and Tools]], [[Jarvis HUD Design]], [[Jarvis HUD Runbook]], [[Learning Notes]]
