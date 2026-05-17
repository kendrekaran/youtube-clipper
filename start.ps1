# Starts the youtube-clipper backend (port 3001) and frontend (port 3000)
# in the same PowerShell window. Press Ctrl+C to stop both.
#
# Usage (from this folder):
#   ./start.ps1
#
# If PowerShell blocks the script, run once as Administrator:
#   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned

$ErrorActionPreference = "Stop"
$ROOT = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "==> Checking prerequisites..." -ForegroundColor Cyan
foreach ($cmd in @("bun", "yt-dlp", "ffmpeg")) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-Error "Missing '$cmd'. Install with: winget install $cmd   (or see README)"
        exit 1
    }
}

# Free up ports if something is already listening
foreach ($port in @(3000, 3001)) {
    $conns = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
    foreach ($c in $conns) {
        Write-Host "==> Killing existing process on port $port (pid $($c.OwningProcess))" -ForegroundColor Yellow
        Stop-Process -Id $c.OwningProcess -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "==> Installing deps (only if needed)..." -ForegroundColor Cyan
if (-not (Test-Path "$ROOT/backend/node_modules"))  { Push-Location "$ROOT/backend";  bun install; Pop-Location }
if (-not (Test-Path "$ROOT/frontend/node_modules")) { Push-Location "$ROOT/frontend"; bun install; Pop-Location }

Write-Host "==> Starting backend on http://localhost:3001" -ForegroundColor Green
$backend = Start-Process -FilePath "bun" -ArgumentList "run", "src/index.ts" -WorkingDirectory "$ROOT/backend" -PassThru -NoNewWindow

Write-Host "==> Starting frontend on http://localhost:3000" -ForegroundColor Green
$frontend = Start-Process -FilePath "bun" -ArgumentList "run", "dev" -WorkingDirectory "$ROOT/frontend" -PassThru -NoNewWindow

# Wait for the frontend to be reachable, then open the browser once.
Start-Job -ScriptBlock {
    for ($i = 0; $i -lt 60; $i++) {
        try {
            Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing -TimeoutSec 2 | Out-Null
            Start-Process "http://localhost:3000"
            break
        } catch { Start-Sleep -Seconds 1 }
    }
} | Out-Null

Write-Host ""
Write-Host "================================================" -ForegroundColor Magenta
Write-Host "  Opening http://localhost:3000 in your browser" -ForegroundColor Magenta
Write-Host "  Press Ctrl+C to stop both servers"             -ForegroundColor Magenta
Write-Host "================================================" -ForegroundColor Magenta
Write-Host ""

try {
    Wait-Process -Id $backend.Id, $frontend.Id
} finally {
    Write-Host ""
    Write-Host "==> Shutting down..." -ForegroundColor Yellow
    Stop-Process -Id $backend.Id  -Force -ErrorAction SilentlyContinue
    Stop-Process -Id $frontend.Id -Force -ErrorAction SilentlyContinue
}
