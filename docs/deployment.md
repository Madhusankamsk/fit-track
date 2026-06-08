# Deployment

## Docker Compose (Production)

The full stack is defined in `docker-compose.yml`:

| Service | Image / Build | Port |
|---------|--------------|------|
| postgres | `postgis/postgis:16-3.4` | host **5433** → container 5432 |
| redis | `redis:7-alpine` | host **6380** → container 6379 |
| nginx | Build from `nginx/Dockerfile` | host **8080** (HTTP), **8443** (HTTPS) |
| auth-user-service | Build from Dockerfile | internal 5001 |
| activity-ingestion-api | Build from Dockerfile | internal 5002 |
| spatial-processing-worker | Build from Dockerfile | — |
| analytics-service | Build from Dockerfile | internal 5003 |

### Quick Start

```powershell
docker compose up -d
```

Environment variables are defined in `docker-compose.yml` with defaults. Override secrets before production:

```powershell
# Optional local overrides (not required for deploy)
copy .env.docker.example .env
```

### Portainer

Deploy from the **full Git repository** (not paste-only compose). Portainer must build service images and include the `nginx/` folder — bind-mounting `nginx.conf` fails when the file is missing on the server.

Stacks do **not** need a `.env` file on disk. In Portainer → **Stacks** → your stack → **Environment variables**, set at minimum:

| Variable | Example |
|----------|---------|
| `DB_PASSWORD` | strong random password |
| `JWT_SECRET` | 256-bit random string |
| `JWT_REFRESH_SECRET` | different 256-bit string |
| `SEED_ON_STARTUP` | `true` (optional, for a default login) |

Redeploy the stack after updating `docker-compose.yml` (no `env_file: .env` dependency).

### Postgres / dependency startup

Services no longer block on a Postgres **health check** (often flaky on Portainer). The auth service waits for Postgres TCP port `5432`, then runs migrations. Other services use `restart: unless-stopped` and connect once Postgres/Redis are up.

If the stack fails after a **previous partial deploy**, reset volumes:

1. Portainer → **Stacks** → stop stack → enable **Remove volumes** → remove.
2. Redeploy with a consistent `DB_PASSWORD` (do not change it after the first successful boot).
3. Check **fittrack_postgres** logs for `FATAL`, `PANIC`, or disk-space errors.

First PostGIS boot can take **1–3 minutes** on slow VPS hosts — wait before checking `fittrack_auth` logs.

### Platform mismatch (`exec format error` / `platform does not match`)

Caused by **cached images built for a different CPU** than the server, or forcing `linux/amd64` on an **ARM** host (builds produce `arm64`).

1. Check host architecture (SSH):
   ```bash
   uname -m
   ```
   - `x86_64` — Intel/AMD VPS
   - `aarch64` — ARM VPS (Oracle Ampere, Raspberry Pi, etc.)

2. **Remove `DOCKER_PLATFORM` from Portainer** — `docker-compose.yml` builds for the host CPU automatically.

3. **Clean redeploy** (SSH in repo root):
   ```bash
   chmod +x scripts/portainer-redeploy.sh
   ./scripts/portainer-redeploy.sh
   ```

   Or manually: stop stack → delete all `fit-track-*` and `fittrack/*` images in Portainer → redeploy with `IMAGE_TAG=v3`.

### 502 Bad Gateway on `/api/v1/auth/login`

Nginx is up but **`fittrack_auth` is not listening** (container crashed or still starting).

1. Portainer → **Containers** → `fittrack_auth` → **Logs**
2. Look for the last successful line or error:

| Log | Meaning |
|-----|---------|
| `=== [auth] Starting server ===` then `Server listening at http://0.0.0.0:5001` | Auth is healthy — check nginx rebuild |
| `Timed out waiting for postgres` | Postgres not ready — check `fittrack_postgres` |
| `migrate deploy` / `P1000` / `password authentication failed` | `DB_PASSWORD` mismatch vs existing volume |
| `type "geography" does not exist` | PostGIS not enabled — use `postgis/postgis:16-3.4` image |
| `Seed failed` | DB connection or schema issue |

3. **Rebuild** `auth-user-service` after code changes.
4. Keep `DB_PASSWORD` consistent, or remove volumes and redeploy fresh.
5. Use a simple `DB_PASSWORD` (letters/numbers only) to avoid `DATABASE_URL` parsing issues.

The auth service runs `prisma migrate deploy` on startup before listening.

### Dev Overrides

`docker-compose.dev.yml` adds volume mounts and `node --watch` for hot reload:

```powershell
docker compose -f docker-compose.yml -f docker-compose.dev.yml up
```

## Docker Builds

Each service Dockerfile expects the **repo root** as build context:

```powershell
docker build -f auth-user-service/Dockerfile .
docker build -f activity-ingestion-api/Dockerfile .
docker build -f spatial-processing-worker/Dockerfile .
docker build -f analytics-service/Dockerfile .
```

Dockerfiles copy `prisma/` and run `prisma generate` during build.

## Nginx Reverse Proxy

Configuration: `nginx/nginx.conf`

Routes external traffic on port 80 to internal services. Key features:
- Per-route rate limiting (auth: 10/min, ingest: 60/min, api: 200/min)
- 50 MB body limit on ingest endpoint
- Kudos/comments routed to analytics (regex location block)

### SSL

Place certificates in `nginx/ssl/` and configure Nginx for HTTPS (port 443). Use Let's Encrypt / Certbot in production.

## Local Dev Gateway

For development without Docker, use `dev-gateway` on port 8080 instead of Nginx. It implements the same routing rules against `localhost` upstreams.

## Monitoring

`monitoring/prometheus.yml` defines scrape targets for the three HTTP services. To enable:

1. Add Prometheus and Grafana services to Docker Compose
2. Point Grafana at Prometheus on port 9090
3. Import dashboards for Fastify metrics

Default ports (from `.env`):
- Prometheus: 9090
- Grafana: 3000

## Production Checklist

- [ ] Set strong `JWT_SECRET` and `DB_PASSWORD`
- [ ] Lock CORS origins (replace `origin: '*'` in Fastify configs)
- [ ] Enable Nginx SSL with valid certificates
- [ ] Set `NODE_ENV=production`
- [ ] Configure Postgres backups
- [ ] Set Redis `maxmemory` policy (already `allkeys-lru` in compose)
- [ ] Run PostGIS index script after migrations
- [ ] Set up log aggregation (Pino JSON logs from Fastify)
- [ ] Consider dead-letter queue for failed worker jobs

## Related Documents

- [Getting Started](getting-started.md)
- [Environment Variables](environment-variables.md)
- [Architecture](architecture.md)
