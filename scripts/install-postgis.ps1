# Download and install PostGIS bundle for PostgreSQL 18 (Windows, no Stack Builder required).
param(
    [string]$PgRoot = "C:\Program Files\PostgreSQL\18"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Tools = Join-Path $Root ".tools\postgis"
$ZipPath = Join-Path $Tools "postgis-bundle-pg18-3.6.2x64.zip"
$Url = "https://download.osgeo.org/postgis/windows/pg18/postgis-bundle-pg18-3.6.2x64.zip"

if (-not (Test-Path $PgRoot)) {
    Write-Error "PostgreSQL not found at $PgRoot"
}

New-Item -ItemType Directory -Force -Path $Tools | Out-Null

if (-not (Test-Path $ZipPath)) {
    Write-Host "Downloading PostGIS bundle (~118 MB)..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $Url -OutFile $ZipPath
}

$Extract = Join-Path $Tools "extracted"
if (Test-Path $Extract) { Remove-Item $Extract -Recurse -Force }
Expand-Archive -Path $ZipPath -DestinationPath $Extract -Force

$BundleRoot = Get-ChildItem $Extract -Directory | Select-Object -First 1
if (-not $BundleRoot) { Write-Error "Unexpected PostGIS zip layout" }

Write-Host "Copying PostGIS files into $PgRoot ..." -ForegroundColor Cyan
Get-ChildItem $BundleRoot.FullName -Recurse | ForEach-Object {
    if ($_.PSIsContainer) { return }
    $relative = $_.FullName.Substring($BundleRoot.FullName.Length).TrimStart('\')
    $target = Join-Path $PgRoot $relative
    $targetDir = Split-Path $target -Parent
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
    }
    Copy-Item $_.FullName $target -Force
}

Write-Host "PostGIS files installed. Restart PostgreSQL service if CREATE EXTENSION still fails." -ForegroundColor Green
