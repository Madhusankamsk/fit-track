# Deployment

## Docker Compose (Production)

The full stack is defined in `docker-compose.yml`:

| Service | Image / Build | Port |
|---------|--------------|------|
| postgres | `postgis/postgis:16-3.4` | 5432 |
| redis | `redis:7-alpine` | 6379 |
| nginx | `nginx:alpine` | 80, 443 |
| auth-user-service | Build from Dockerfile | internal 5001 |
| activity-ingestion-api | Build from Dockerfile | internal 5002 |
| spatial-processing-worker | Build from Dockerfile | — |
| analytics-service | Build from Dockerfile | internal 5003 |

### Quick Start

```powershell
copy .env.example .env
# Edit .env — set DB_PASSWORD, JWT_SECRET

docker compose up -d
```

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
