# Connects Claude Code to the Obsidian Jarvis vault via MCP.
# Obsidian must be running. Re-run if the connection is ever lost.
#
#   powershell -ExecutionPolicy Bypass -File "$PSScriptRoot\connect-jarvis.ps1"
#
# The API key is NOT stored here — it lives in .env.local (gitignored).
# See "Setup - New Machine" in the vault if .env.local is missing.

$ErrorActionPreference = "Stop"

# --- Load the key: environment first, then .env.local beside this script ---
$key = $env:OBSIDIAN_API_KEY
if (-not $key) {
    $envFile = Join-Path $PSScriptRoot ".env.local"
    if (Test-Path $envFile) {
        Get-Content $envFile | ForEach-Object {
            if ($_ -match '^\s*OBSIDIAN_API_KEY\s*=\s*(.+?)\s*$') { $key = $Matches[1].Trim('"') }
        }
    }
}
if (-not $key) {
    Write-Host "No OBSIDIAN_API_KEY found." -ForegroundColor Red
    Write-Host "Create $PSScriptRoot\.env.local containing:" -ForegroundColor Yellow
    Write-Host "  OBSIDIAN_API_KEY=<key from Obsidian - Settings - Local REST API>" -ForegroundColor Yellow
    throw "Missing OBSIDIAN_API_KEY"
}

$port = if ($env:OBSIDIAN_PORT) { $env:OBSIDIAN_PORT } else { "27125" }
$url  = "http://127.0.0.1:$port/mcp/"

Write-Host "Checking the server is listening..." -ForegroundColor Cyan
try {
    $r = Invoke-RestMethod -Uri "http://127.0.0.1:$port/" -Headers @{ Authorization = "Bearer $key" }
    Write-Host "  version:       $($r.versions.self)"
    Write-Host "  authenticated: $($r.authenticated)"
    if (-not $r.authenticated) { throw "Not authenticated - wrong vault or wrong key." }
    if ($r.versions.self -ne "5.0.3") { Write-Warning "Unexpected version - may be a different vault's plugin." }
} catch {
    Write-Host "Server not reachable. Is Obsidian open on the Jarvis vault?" -ForegroundColor Red
    throw
}

claude mcp remove --scope user obsidian 2>$null
claude mcp add --scope user --transport http obsidian $url --header "Authorization: Bearer $key"

Write-Host ""
claude mcp list
