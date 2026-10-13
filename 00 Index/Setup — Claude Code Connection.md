---
created: 2026-08-06
updated: 2026-09-08
tags: [meta/setup]
---

# Setup — Claude Code Connection

How Jarvis is wired. Keep current if anything changes.

## Vault

- Path: `C:\Users\Mackenzie\Jarvis`
- Protocol file: `CLAUDE.md` at vault root (Claude Code auto-loads it)

## Obsidian plugin

- **Local REST API with MCP** v5.0.3 — Adam Coddington
- **HTTP MCP endpoint (in use): `http://127.0.0.1:27125/mcp/`**
- HTTPS endpoint (unused): `https://127.0.0.1:27126/mcp/`
- Auth: bearer token. Canonical copy for scripts is `.env.local` at the vault root (gitignored).
  Obsidian's own copy lives in `.obsidian/plugins/obsidian-local-rest-api/data.json` — also gitignored,
  because that file holds the API key **and** the CA private key.
- **Obsidian must be running** for MCP to respond. Claude Code still reads/writes the files directly when it isn't.

## Working config

```
claude mcp add --scope user --transport http obsidian http://127.0.0.1:27125/mcp/ --header "Authorization: Bearer <API_KEY>"
```

Verify with `claude mcp list` → `obsidian … ✔ Connected`.

## Non-default ports — why

The **Cheat Sheet** vault also runs this plugin (v4.1.3) and owns the default ports 27124/27123. Only one process can bind a port, so Jarvis silently failed to start there. Jarvis was moved to **27126 (HTTPS) / 27125 (HTTP)**.

**If MCP breaks, check this first.** Symptom: the endpoint answers but reports the wrong `version` or `"authenticated": false` — that means you're talking to the other vault.

Diagnostic:

```
curl.exe -H "Authorization: Bearer <API_KEY>" http://127.0.0.1:27125/
```

Expect `"self": "5.0.3"` and `"authenticated": true`.

## Why plain HTTP and not HTTPS

The plugin's cert is self-signed, and Claude Code has no "skip verification" option. The fix would be trusting that cert in Windows — but it's a **CA certificate whose private key sits in plaintext in `data.json`**. Trusting it machine-wide would let anyone who reads that file forge a certificate for any domain.

Plain HTTP on loopback is the smaller exposure: the key never leaves 127.0.0.1, and anything able to sniff loopback could already read `data.json`.

## Two access paths

1. **Direct file access** — works offline, works when Obsidian is closed. The reliable path.
2. **MCP** — richer search and patch operations, live only while Obsidian is open.

If MCP breaks, path 1 still works. Nothing is lost.

## Lesson learned

The plugin settings UI showing "Enabled" means *configured*, not *listening*. Always verify with `curl` against the actual endpoint.

## Version control — replaces Obsidian Sync

The vault is a git repo. Obsidian Sync is paid; a private GitHub remote is free
and gives real history. Two repos, deliberately separate:

| Repo | Contents |
|---|---|
| [`jarvis-vault`](https://github.com/Queeniee22/jarvis-vault) | this vault — memory, `06 Skills/`, `CLAUDE.md`, `.claude/` config |
| [`jarvis-hud`](https://github.com/Queeniee22/jarvis-hud) | the app at `C:\Users\Mackenzie\jarvis-hud` |

### Never committed

- `.env.local` — the REST API key
- `.obsidian/plugins/` — same key plus the CA private key
- `.obsidian/workspace.json` — per-machine pane layout, conflicts constantly

`.env.local.example` is the tracked template. Copy and fill on each machine.

## Moving to a second machine

Works on Windows and macOS. The vault and the HUD must end up as **siblings** —
`Jarvis/` and `jarvis-hud/` in the same parent folder — because
`.claude/launch.json` resolves the HUD through `../jarvis-hud`.

### 1. Prerequisites

**Windows** — [Obsidian](https://obsidian.md), [Git for Windows](https://git-scm.com),
Node, Python 3.11+.

**macOS** — Obsidian, Node, Python 3.11+, then:

```
xcode-select --install        # git
brew install gh portaudio     # gh for auth; portaudio for sounddevice
```

### 2. Clone both, side by side

**Windows.** Git Credential Manager ships with Git for Windows and is already
configured (`credential.helper = manager`). A browser window opens on the first
push and the token is stored. No SSH key or PAT.

```
cd ~
git clone https://github.com/Queeniee22/jarvis-vault.git Jarvis
git clone https://github.com/Queeniee22/jarvis-hud.git
```

**macOS.** There is *no* Credential Manager — that is Windows-only. Authenticate
with `gh` first; it writes git's credential helper for you.

```
gh auth login     # GitHub.com -> HTTPS -> login with a web browser
cd ~
git clone https://github.com/Queeniee22/jarvis-vault.git Jarvis
git clone https://github.com/Queeniee22/jarvis-hud.git
```

Commit identity is per-machine and does **not** travel in the repo:

```
git config --global user.name  "Mackenzie"
git config --global user.email "connermackenzie2003@gmail.com"
```

### 3. Obsidian

Open the cloned `Jarvis` folder → *Open folder as vault*. Settings in
`.obsidian/` come with it, but **Local REST API must be reinstalled** from
Community plugins — its binary is gitignored — and it mints a **new** key.

Then `cp .env.local.example .env.local` and paste that new key in.

### 4. Claude Code

Copy `~/.claude/settings.json` from the old machine. It is only a plugin list;
Claude Code re-downloads all 28 plugins itself.

`.claude/launch.json` needs **no editing**. It carries both a
`jarvis-hud-windows` and a `jarvis-hud-mac` configuration and the paths are
relative — pick the one matching the platform.

### 5. The HUD

```
cd ~/jarvis-hud
python -m venv .venv
```

**Windows**

```
.venv\Scripts\python -m pip install -e ".[dev]"
.venv\Scripts\python run.py
```

**macOS**

```
.venv/bin/python -m pip install -e ".[dev]"
.venv/bin/python run.py
```

Recreate `jarvis-hud/.env` from its `.env.example`: ElevenLabs key, the new
Obsidian key, calendar ID. Then run `scripts/gcal_auth.py` for Google OAuth —
`token.json` and `credentials.json` are machine-bound and not in the repo.

Cross-platform notes: `pyttsx3` (the local voice fallback) uses SAPI on Windows
and NSSpeechSynthesizer on macOS, so it works on both. `sounddevice` needs
PortAudio on macOS — that is what `brew install portaudio` in step 1 is for.

### 6. Connect MCP

**Windows**

```
powershell -ExecutionPolicy Bypass -File .\connect-jarvis.ps1
```

**macOS**

```
./connect-jarvis.sh
```

The fallback patcher is paired the same way — `fix-mcp-config.ps1` /
`fix-mcp-config.sh`. All four read the key from `$OBSIDIAN_API_KEY` or
`.env.local`, and none of them contain it.

### Port collision, again

The 27125/27126 choice exists because of the **Cheat Sheet** vault (see above).
If that vault isn't on the new machine the defaults are free — but the config
carries the non-default ports regardless, so leave them alone unless something
breaks.

### Day-to-day sync

`git pull` when you sit down, `git push` when you get up. Two machines editing
the same note between pushes will conflict — markdown conflicts are readable
and resolved by hand, which is the tradeoff for not paying for Sync.

Related: [[Stack and Tools]], [[Jarvis HUD Runbook]]
