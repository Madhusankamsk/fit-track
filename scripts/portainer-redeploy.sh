#!/usr/bin/env bash
# Clean stale FitTrack images and redeploy on the Docker host (SSH / Portainer console).
# Fixes: exec format error, platform arm64/amd64 mismatch.
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Host architecture: $(uname -m)"
echo "==> Stopping stack..."
docker compose down --remove-orphans 2>/dev/null || true

echo "==> Removing old FitTrack images..."
docker images --format '{{.Repository}}:{{.Tag}}' \
  | grep -E '^(fit-track-|fittrack/)' \
  | xargs -r docker rmi -f 2>/dev/null || true

echo "==> Rebuilding for this host CPU..."
docker compose build --no-cache --pull

echo "==> Starting stack..."
docker compose up -d

echo "==> Done. Wait 2-3 min, then:"
echo "    curl http://localhost:8080/health/auth"
