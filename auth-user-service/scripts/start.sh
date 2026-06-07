#!/bin/sh
set -e

echo "=== [auth] Waiting for Postgres ==="
node scripts/wait-for-tcp.js postgres 5432

echo "=== [auth] Running migrations ==="
npx prisma migrate deploy --schema=./prisma/schema.prisma

echo "=== [auth] Running seed ==="
node scripts/seed.js

echo "=== [auth] Starting server on port ${AUTH_SERVICE_PORT:-5001} ==="
exec node server.js
