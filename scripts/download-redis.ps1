$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$redisDir = Join-Path $Root ".tools\redis"
New-Item -ItemType Directory -Force -Path $redisDir | Out-Null
$zip = Join-Path $Root ".tools\redis.zip"
if (-not (Test-Path (Join-Path $redisDir "redis-server.exe"))) {
    Write-Host "Downloading Redis for Windows..."
    Invoke-WebRequest -Uri "https://github.com/tporadowski/redis/releases/download/v5.0.14.1/Redis-x64-5.0.14.1.zip" -OutFile $zip
    Expand-Archive -Path $zip -DestinationPath $redisDir -Force
    Write-Host "Redis installed to $redisDir"
} else {
    Write-Host "Redis already present at $redisDir"
}
