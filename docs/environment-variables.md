# Environment Variables

All services read from a shared `.env` file at the repository root. Copy `.env.example` to `.env` and never commit `.env` to version control.

## Database

| Variable | Default | Description |
|----------|---------|-------------|
| `DATABASE_URL` | `postgresql://fittrack:strongpassword@localhost:5432/fittrack_db` | PostgreSQL connection string used by Prisma |
| `DB_PASSWORD` | `strongpassword` | Postgres password (used by Docker Compose) |

## Redis

| Variable | Default | Description |
|----------|---------|-------------|
| `REDIS_URL` | `redis://localhost:6379` | Redis connection for queue and cache |
| `ACTIVITY_QUEUE_NAME` | `activity_queue` | Redis list name for GPS ingest jobs |

## JWT Authentication

| Variable | Default | Description |
|----------|---------|-------------|
| `JWT_SECRET` | *(required)* | Secret for signing access tokens |
| `JWT_REFRESH_SECRET` | *(optional)* | Separate refresh secret (reserved for future use) |
| `JWT_EXPIRES_IN` | `15m` | Access token lifetime |
| `JWT_REFRESH_EXPIRES_IN` | `30d` | Refresh token lifetime |

Generate a secure secret:

```powershell
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

## Service Ports

| Variable | Default | Description |
|----------|---------|-------------|
| `AUTH_SERVICE_PORT` | `5001` | Auth & user service |
| `INGESTION_API_PORT` | `5002` | Activity ingestion API |
| `ANALYTICS_SERVICE_PORT` | `5003` | Analytics service |
| `DEV_GATEWAY_PORT` | `8080` | Local dev reverse proxy |

## Application Config

| Variable | Default | Description |
|----------|---------|-------------|
| `NODE_ENV` | `development` | Runtime environment |
| `BCRYPT_ROUNDS` | `12` | Password hashing cost factor |
| `MAX_WAYPOINTS_PER_ACTIVITY` | `100000` | Max GPS points per ingest request |

## Monitoring (Optional)

| Variable | Default | Description |
|----------|---------|-------------|
| `PROMETHEUS_PORT` | `9090` | Prometheus scrape port |
| `GRAFANA_PORT` | `3000` | Grafana dashboard port |

## Docker Compose Notes

In Docker, service hostnames change:
- `DATABASE_URL=postgresql://fittrack:${DB_PASSWORD}@postgres:5432/fittrack_db`
- `REDIS_URL=redis://redis:6379`

The `.env.example` uses `localhost` for local Node.js development.

## Related Documents

- [Getting Started](getting-started.md)
- [Security](security.md)
