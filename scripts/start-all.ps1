# FitTrack Pro — start all backend services
# Usage:
#   .\scripts\start-all.ps1
#   .\scripts\start-all.ps1 -PostgresPassword "your_postgres_password"

param(
    [string]$PostgresPassword = $env:POSTGRES_ADMIN_PASSWORD
)

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

# Load root .env into process env
$envFile = Join-Path $Root ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*([^#=]+)=(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            Set-Item -Path "env:$name" -Value $value
        }
    }
}

function Write-Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }

# ── 1. Redis ────────────────────────────────────────────────────────────────
Write-Step "Starting Redis"
$redisExe = Get-ChildItem "$Root\.tools\redis" -Filter redis-server.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $redisExe) {
    Write-Host "Redis not found. Run: .\scripts\download-redis.ps1" -ForegroundColor Yellow
} else {
    $redisRunning = Test-NetConnection localhost -Port 6379 -WarningAction SilentlyContinue | Select-Object -ExpandProperty TcpTestSucceeded
    if (-not $redisRunning) {
        Start-Process -FilePath $redisExe.FullName -ArgumentList "--port 6379" -WindowStyle Minimized
        Start-Sleep -Seconds 2
        Write-Host "Redis started on :6379"
    } else {
        Write-Host "Redis already running on :6379"
    }
}

# ── 2. PostgreSQL setup (optional) ───────────────────────────────────────────
if ($PostgresPassword) {
    Write-Step "Setting up PostgreSQL database"
    $psql = "C:\Program Files\PostgreSQL\18\bin\psql.exe"
    if (-not (Test-Path $psql)) { $psql = (Get-Command psql -ErrorAction SilentlyContinue).Source }
    if ($psql) {
        $env:PGPASSWORD = $PostgresPassword
        & $psql -U postgres -h localhost -c "DO `$`$ BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'fittrack') THEN CREATE USER fittrack WITH PASSWORD 'strongpassword'; END IF; END `$`$;" 2>&1
        & $psql -U postgres -h localhost -c "SELECT 1 FROM pg_database WHERE datname = 'fittrack_db'" -tAc "SELECT 1" | Out-Null
        if ($LASTEXITCODE -ne 0) {
            & $psql -U postgres -h localhost -c "CREATE DATABASE fittrack_db OWNER fittrack;"
        }
        & $psql -U postgres -h localhost -d fittrack_db -c "CREATE EXTENSION IF NOT EXISTS postgis;"
        Write-Host "Database fittrack_db ready"
        npx prisma migrate deploy --schema=prisma/schema.prisma 2>&1
        if ($LASTEXITCODE -eq 0) {
            & $psql -U fittrack -h localhost -d fittrack_db -f "$Root\prisma\migrations\postgis_indexes.sql" 2>&1
        }
    } else {
        Write-Host "psql not found — skip DB setup or install PostgreSQL" -ForegroundColor Yellow
    }
} else {
    Write-Host "`nTip: Set POSTGRES_ADMIN_PASSWORD env var or pass -PostgresPassword to auto-create fittrack_db" -ForegroundColor Yellow
    Write-Host "     Example: `$env:POSTGRES_ADMIN_PASSWORD='yourpass'; .\scripts\start-all.ps1" -ForegroundColor Yellow
}

# ── 3. Start Node services ───────────────────────────────────────────────────
Write-Step "Starting backend services"

$services = @(
    @{ Name = "auth";       Script = "dev:auth";       Port = 5001 },
    @{ Name = "ingest";     Script = "dev:ingest";     Port = 5002 },
    @{ Name = "analytics";  Script = "dev:analytics";  Port = 5003 },
    @{ Name = "worker";     Script = "dev:worker";      Port = $null },
    @{ Name = "gateway";    Script = "dev:gateway";     Port = $(if ($env:DEV_GATEWAY_PORT) { [int]$env:DEV_GATEWAY_PORT } else { 8081 }) }
)

foreach ($svc in $services) {
    if ($svc.Port) {
        $inUse = Test-NetConnection localhost -Port $svc.Port -WarningAction SilentlyContinue | Select-Object -ExpandProperty TcpTestSucceeded
        if ($inUse) {
            Write-Host "$($svc.Name) already listening on :$($svc.Port)" -ForegroundColor DarkGray
            continue
        }
    }
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$Root'; npm run $($svc.Script)" -WindowStyle Minimized
    Write-Host "Started $($svc.Name)"
    Start-Sleep -Milliseconds 800
}

Write-Step "FitTrack Pro backend starting"
$gwPort = if ($env:DEV_GATEWAY_PORT) { $env:DEV_GATEWAY_PORT } else { 8081 }
Write-Host "Gateway:  http://localhost:$gwPort/health"
Write-Host "Auth:     http://localhost:5001/health"
Write-Host "Ingest:   http://localhost:5002/health"
Write-Host "Analytics: http://localhost:5003/health"
Write-Host "`nFlutter app: cd strava_alternative_app; flutter run"
