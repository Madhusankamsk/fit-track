# FitTrack Pro — local Docker stack trial
# Usage: .\scripts\docker-local.ps1
#        .\scripts\docker-local.ps1 -Down

param([switch]$Down, [switch]$Logs)

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

$DockerBin = "C:\Program Files\Docker\Docker\resources\bin"
$Docker = Join-Path $DockerBin "docker.exe"
if (-not (Test-Path $Docker)) {
    $cmd = Get-Command docker -ErrorAction SilentlyContinue
    if ($cmd) { $Docker = $cmd.Source } else {
        Write-Error "Docker not found. Install Docker Desktop: https://docs.docker.com/desktop/setup/install/windows-install/"
        exit 1
    }
} elseif ($env:PATH -notlike "*$DockerBin*") {
    $env:PATH = "$DockerBin;$env:PATH"
}

if (-not (Test-Path ".env")) {
    Write-Host "Creating .env from .env.example..." -ForegroundColor Yellow
    Copy-Item ".env.example" ".env"
}

Write-Host "Checking Docker daemon..." -ForegroundColor Cyan
& $Docker info 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker daemon is not running. Start Docker Desktop and retry."
    exit 1
}

$ComposeArgs = @(
    "compose",
    "-f", "docker-compose.yml",
    "-f", "docker-compose.local.yml"
)

if ($Down) {
    Write-Host "Stopping Docker stack..." -ForegroundColor Cyan
    & $Docker @ComposeArgs down
    exit $LASTEXITCODE
}

Write-Host "Building and starting FitTrack Pro (Docker)..." -ForegroundColor Cyan
Write-Host "  API gateway:  http://localhost:8080" -ForegroundColor Green
Write-Host "  Postgres:     localhost:5433 (user fittrack)" -ForegroundColor Green
Write-Host "  Redis:        localhost:6380" -ForegroundColor Green
Write-Host ""

& $Docker @ComposeArgs up -d --build
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if ($Logs) {
    & $Docker @ComposeArgs logs -f
} else {
    Write-Host "`nStack started. Verify:" -ForegroundColor Cyan
    Write-Host "  curl http://localhost:8080/api/v1/auth/login" -ForegroundColor DarkGray
    Write-Host "  docker compose -f docker-compose.yml -f docker-compose.local.yml ps" -ForegroundColor DarkGray
    Write-Host "`nTail logs: .\scripts\docker-local.ps1 -Logs" -ForegroundColor DarkGray
    Write-Host "Stop:      .\scripts\docker-local.ps1 -Down" -ForegroundColor DarkGray
}
