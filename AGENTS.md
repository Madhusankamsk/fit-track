# FitTrack Pro — Agent Guide

## Documentation

Full project docs: [docs/README.md](docs/README.md)

## Single Source of Truth

**Always consult [MASTER_BLUEPRINT.md](MASTER_BLUEPRINT.md) before generating or modifying code.** Do not contradict the blueprint's architecture, API paths, schema, or security rules.

## Architecture

```
Flutter App → Dev Gateway (:8080) / Nginx (:80)
  ├── Auth Service (:5001) — register, login, users, follow
  ├── Ingestion API (:5002) — POST /ingest → Redis, feed reads
  └── Analytics Service (:5003) — stats, segments, kudos, comments

Ingestion → Redis (activity_queue) → Spatial Worker → PostgreSQL + PostGIS
```

## Local Dev Ports

| Service | Port |
|---------|------|
| Auth | 5001 |
| Ingestion | 5002 |
| Analytics | 5003 |
| Dev Gateway | 8080 |
| PostgreSQL | 5432 |
| Redis | 6379 |

## Implementation Order

1. Prisma schema + PostGIS indexes
2. Auth service → Ingestion API → Spatial worker → Analytics
3. Dev gateway (mirrors nginx routing)
4. Flutter mobile client
5. Docker Compose + monitoring (production path)

## Key Rules

- PostGIS geography fields: write via `$executeRaw`, read via `ST_AsGeoJSON()`
- Ingest endpoint returns **202** immediately — no DB writes on hot path
- JWT access tokens 15min, refresh tokens 30d stored in DB
- All request bodies validated with Zod before processing
