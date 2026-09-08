#!/usr/bin/env bash
# Connects Claude Code to the Obsidian Jarvis vault via MCP.  (macOS / Linux)
# Windows equivalent: connect-jarvis.ps1
#
#   ./connect-jarvis.sh
#
# Obsidian must be running. Re-run if the connection is ever lost.
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

port="${OBSIDIAN_PORT:-27125}"
url="http://127.0.0.1:$port/mcp/"

echo "Checking the server is listening..."
if ! body="$(curl -fsS --max-time 10 -H "Authorization: Bearer $key" "http://127.0.0.1:$port/")"; then
    echo "Server not reachable. Is Obsidian open on the Jarvis vault?" >&2
    exit 1
fi

version="$(printf '%s' "$body" | sed -n 's/.*"self"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
echo "  version:       ${version:-unknown}"

if printf '%s' "$body" | grep -q '"authenticated"[[:space:]]*:[[:space:]]*true'; then
    echo "  authenticated: True"
else
    echo "  authenticated: False" >&2
    echo "Not authenticated - wrong vault or wrong key." >&2
    exit 1
fi

if [ "$version" != "5.0.3" ]; then
    echo "WARNING: unexpected version - may be a different vault's plugin." >&2
fi

claude mcp remove --scope user obsidian 2>/dev/null || true
claude mcp add --scope user --transport http obsidian "$url" --header "Authorization: Bearer $key"

echo
claude mcp list
