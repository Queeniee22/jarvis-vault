# Patches the obsidian MCP server entry directly into ~/.claude.json.
# Bypasses the CLI argument-splitting bug entirely.
#
#   powershell -ExecutionPolicy Bypass -File "$PSScriptRoot\fix-mcp-config.ps1"
#
# The API key is NOT stored here - it lives in .env.local (gitignored).

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

$path = Join-Path $env:USERPROFILE ".claude.json"
if (-not (Test-Path $path)) { throw "Not found: $path" }

# Back up first - this rewrites the whole file.
$backup = "$path.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Copy-Item $path $backup -Force
Write-Host "Backup: $backup" -ForegroundColor DarkGray

$json = Get-Content $path -Raw | ConvertFrom-Json

$server = [PSCustomObject]@{
    type    = "stdio"
    command = "npx"
    args    = @(
        "-y"
        "mcp-remote@latest"
        "https://127.0.0.1:27124/mcp/"
        "--header"
        'Authorization:${AUTH_HEADER}'
    )
    env     = [PSCustomObject]@{
        AUTH_HEADER                  = "Bearer $key"
        NODE_TLS_REJECT_UNAUTHORIZED = "0"
    }
}

if (-not $json.PSObject.Properties.Name.Contains("mcpServers")) {
    $json | Add-Member -NotePropertyName mcpServers -NotePropertyValue ([PSCustomObject]@{})
}
$json.mcpServers | Add-Member -NotePropertyName obsidian -NotePropertyValue $server -Force

$json | ConvertTo-Json -Depth 100 | Set-Content $path -Encoding UTF8

Write-Host "Patched $path" -ForegroundColor Green
Write-Host ""
Write-Host "Now restart Claude Code, then run: claude mcp list" -ForegroundColor Cyan
