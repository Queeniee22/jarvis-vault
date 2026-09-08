#!/usr/bin/env bash
# Patches the obsidian MCP server entry directly into ~/.claude.json.
# Bypasses the CLI argument-splitting bug entirely.  (macOS / Linux)
# Windows equivalent: fix-mcp-config.ps1
#
#   ./fix-mcp-config.sh
#
# The API key is NOT stored here - it lives in .env.local (gitignored).

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Load the key: environment first, then .env.local beside this script ---
key="${OBSIDIAN_API_KEY:-}"
if [ -z "$key" ] && [ -f "$here/.env.local" ]; then
    key="$(sed -n 's/^[[:space:]]*OBSIDIAN_API_KEY[[:space:]]*=[[:space:]]*//p' "$here/.env.local" \
           | head -1 | tr -d '"\r')"
fi
if [ -z "$key" ]; then
    echo "No OBSIDIAN_API_KEY found." >&2
    echo "Create $here/.env.local containing:" >&2
    echo "  OBSIDIAN_API_KEY=<key from Obsidian - Settings - Local REST API>" >&2
    exit 1
fi

path="$HOME/.claude.json"
[ -f "$path" ] || { echo "Not found: $path" >&2; exit 1; }

# Back up first - this rewrites the whole file.
backup="$path.backup-$(date +%Y%m%d-%H%M%S)"
cp "$path" "$backup"
echo "Backup: $backup"

python3 - "$path" "$key" <<'PY'
import json, sys

path, key = sys.argv[1], sys.argv[2]

with open(path, encoding="utf-8") as f:
    data = json.load(f)

data.setdefault("mcpServers", {})["obsidian"] = {
    "type": "stdio",
    "command": "npx",
    "args": [
        "-y",
        "mcp-remote@latest",
        "https://127.0.0.1:27124/mcp/",
        "--header",
        "Authorization:${AUTH_HEADER}",
    ],
    "env": {
        "AUTH_HEADER": f"Bearer {key}",
        "NODE_TLS_REJECT_UNAUTHORIZED": "0",
    },
}

with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
PY

echo "Patched $path"
echo
echo "Now restart Claude Code, then run: claude mcp list"
