# FitTrack Pro — one-time PostgreSQL setup (Windows)
# Usage:
#   .\scripts\setup-db.ps1 -PostgresPassword "your_postgres_superuser_password"
#   $env:POSTGRES_ADMIN_PASSWORD='yourpass'; .\scripts\setup-db.ps1

param(
    [Parameter(Mandatory = $true)]
    [string]$PostgresPassword
)

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

$psql = "C:\Program Files\PostgreSQL\18\bin\psql.exe"
if (-not (Test-Path $psql)) {
    $cmd = Get-Command psql -ErrorAction SilentlyContinue
    if ($cmd) { $psql = $cmd.Source } else {
        Write-Error "psql not found. Install PostgreSQL 16+ with PostGIS."
        exit 1
    }
}

$env:PGPASSWORD = $PostgresPassword

Write-Host "Creating fittrack role and database..." -ForegroundColor Cyan
& $psql -U postgres -h localhost -v ON_ERROR_STOP=1 -c @"
DO `$`$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'fittrack') THEN
    CREATE USER fittrack WITH PASSWORD 'strongpassword';
  ELSE
    ALTER USER fittrack WITH PASSWORD 'strongpassword';
  END IF;
END `$`$;
"@ 2>&1
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$dbExists = & $psql -U postgres -h localhost -tAc "SELECT 1 FROM pg_database WHERE datname = 'fittrack_db'"
if ($dbExists -ne '1') {
    & $psql -U postgres -h localhost -v ON_ERROR_STOP=1 -c "CREATE DATABASE fittrack_db OWNER fittrack;" 2>&1
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

& $psql -U postgres -h localhost -d fittrack_db -v ON_ERROR_STOP=1 -c "CREATE EXTENSION IF NOT EXISTS postgis;" 2>&1
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Running Prisma migrations..." -ForegroundColor Cyan
npx prisma migrate deploy --schema=prisma/schema.prisma 2>&1
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$env:PGPASSWORD = 'strongpassword'
& $psql -U fittrack -h localhost -d fittrack_db -v ON_ERROR_STOP=1 -f "$Root\prisma\migrations\postgis_indexes.sql" 2>&1
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "`nDatabase ready. DATABASE_URL=postgresql://fittrack:strongpassword@localhost:5432/fittrack_db" -ForegroundColor Green
