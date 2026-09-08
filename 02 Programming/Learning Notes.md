---
created: 2026-08-06
updated: 2026-08-08
tags: [programming/learning]
---

# Learning Notes

Concepts Mackenzie is working through. Claude: when he asks you to explain something twice, that's a signal to write it down here in his terms, not textbook terms.

---

## From building Jarvis (2026-08-08)

Concepts that came up in real code, worth carrying to other projects. The specific
incidents are in [[Debug Log]]; these are the general lessons.

### Fire-and-forget async tasks swallow their exceptions

`asyncio.create_task(f())` with no one awaiting the result means an exception inside
`f` goes **nowhere** — no traceback, no crash, just a thing that silently stopped.
Three separate Jarvis bugs came from this shape.

- Any `create_task` whose coroutine can raise needs its own `try/except`.
- The event loop keeps only **weak** references to tasks, so a task object you don't
  store can be garbage collected mid-run. Keep them in a set.
- `except CancelledError: raise` is **not** cleanup. Anything opened (subprocess,
  audio stream, pipe) needs a `finally`.

### `return` inside `finally` swallows the exception on its way out

```python
try:
    ...
finally:
    if cancelled:
        return x     # <-- discards the in-flight CancelledError
```
This turned a cancelled task into a silent normal return. Use a guard
(`if not cancelled:`) instead of returning from `finally`.

### Piping a command hides its exit code

`pytest -q | tail -2 && git commit` **always commits** — the exit status is `tail`'s,
not pytest's. Cost two bad commits before it was spotted. Run the check as its own
step and read the result, or use `set -o pipefail`.

### Canvas has two coordinate systems

A `<canvas width=640>` displayed at 284px via CSS has a 2.25× scale factor. `offsetX`
is in CSS pixels; anything you drew is in buffer pixels. Convert explicitly:

```js
const x = (e.clientX - rect.left) * (canvas.width / rect.width);
```
Symptom of getting it wrong: clicks land near the target but drift worse toward the
edges.

### Don't test an absolute threshold you never measured

Two separate bugs from guessed constants: a mic gate whose threshold sat above normal
speech, and a "settled" check of `energy < 0.05` on a layout that asymptotes at 0.365
and can never go lower — so the state was **unreachable by construction**.

Log what the value actually does over time before writing `x < someConstant`. If a
state is never observed in testing, suspect unreachable rather than rare.

### Make the failure mode of forgetting *visible*

An opt-in list ("these message types get replayed") failed silently three times as new
features forgot to register. Inverting it — list the exceptions, default everything else
to the safe behaviour — removed the whole class. Ask which way round a default should
be, based on what happens when someone forgets.

### Remove the guess instead of tuning it

Voice endpointing was tuned three times (0.6s → 1.5s → 2.0s, plus hysteresis) and still
cut him off mid-sentence. Push-to-talk deleted the question entirely: releasing a key
*is* the end of the turn. When a heuristic needs its third round of tuning and you can't
reproduce the failure, change the interaction so the ambiguity can't arise.

Related: [[Stack and Tools]], [[Debug Log]], [[Jarvis Home]]
