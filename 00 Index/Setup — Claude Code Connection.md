---
created: 2026-08-06
updated: 2026-08-06
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
- Auth: bearer token in `.obsidian/plugins/obsidian-local-rest-api/data.json`
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
