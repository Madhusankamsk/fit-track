# Architecture

## High-Level Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     Flutter Mobile App                          │
│  (Riverpod, Hive offline storage, background GPS)               │
└────────────────────────────┬────────────────────────────────────┘
                             │ HTTP (JWT)
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│              Dev Gateway (:8080) / Nginx (:80)                  │
│              Path-based reverse proxy                           │
└──────┬──────────────────────┬──────────────────────┬──────────┘
       │                      │                      │
       ▼                      ▼                      ▼
┌──────────────┐    ┌──────────────────┐    ┌──────────────────┐
│ Auth Service │    │ Ingestion API    │    │ Analytics Service│
│   :5001      │    │   :5002          │    │   :5003          │
│              │    │                  │    │                  │
│ • register   │    │ • POST /ingest   │    │ • stats          │
│ • login      │    │ • GET /feed      │    │ • segments       │
│ • users      │    │ • activities     │    │ • kudos/comments │
│ • follow     │    │                  │    │                  │
└──────┬───────┘    └────────┬─────────┘    └────────┬─────────┘
       │                     │                       │
       │                     │ rpush                 │
       │                     ▼                       │
       │            ┌─────────────────┐              │
       │            │  Redis Queue    │              │
       │            │ activity_queue  │              │
       │            └────────┬────────┘              │
       │                     │ blpop                 │
       │                     ▼                       │
       │            ┌─────────────────┐              │
       │            │ Spatial Worker  │              │
       │            │ (daemon)        │              │
       │            │ PostGIS writes  │              │
       │            └────────┬────────┘              │
       │                     │                       │
       └─────────────────────┼───────────────────────┘
                             ▼
                    ┌─────────────────┐
                    │ PostgreSQL 16   │
                    │ + PostGIS 3.4   │
                    └─────────────────┘
```

## Service Responsibilities

### Auth & User Service (`auth-user-service`, port 5001)
Handles identity and social graph at the user level:
- Registration, login, token refresh
- User profile CRUD
- Follow / unfollow

### Activity Ingestion API (`activity-ingestion-api`, port 5002)
Handles the high-throughput write path and activity reads:
- Accepts GPS batches and queues them in Redis (no DB write on ingest)
- Serves paginated activity feed with GeoJSON routes
- Activity detail and delete

### Spatial Processing Worker (`spatial-processing-worker`)
Background daemon (no HTTP port):
- Consumes jobs from Redis via blocking `BLPOP`
- Builds PostGIS LineString routes and Point waypoints
- Computes distance with `ST_Length`, elevation gain, pace
- Updates personal records

### Analytics Service (`analytics-service`, port 5003)
Stats, segments, and social interactions on activities:
- Personal lifetime stats (Redis-cached)
- Segment list, create, and leaderboards
- Kudos and comments

### Dev Gateway (`dev-gateway`, port 8080)
Local development reverse proxy that mirrors Nginx routing rules, forwarding requests to the correct upstream service on localhost.

## Gateway Routing Rules

| Path prefix | Upstream | Notes |
|-------------|----------|-------|
| `/api/v1/auth/*` | Auth (:5001) | Public register/login |
| `/api/v1/users/*` | Auth (:5001) | Profile, follow |
| `/api/v1/ingest` | Ingestion (:5002) | GPS batch upload |
| `/api/v1/feed` | Ingestion (:5002) | Activity feed |
| `/api/v1/activities/*` (GET, DELETE) | Ingestion (:5002) | Read/delete activities |
| `/api/v1/activities/:id/kudos` (POST) | Analytics (:5003) | Social |
| `/api/v1/activities/:id/comments` (POST) | Analytics (:5003) | Social |
| `/api/v1/stats/*` | Analytics (:5003) | Personal stats |
| `/api/v1/segments/*` | Analytics (:5003) | Segments |

## Data Flow: Recording an Activity

1. User starts tracking in the Flutter app; GPS waypoints stream into Hive.
2. User stops and saves; `SyncService` POSTs coordinates to `/api/v1/ingest`.
3. Ingestion API validates with Zod, pushes JSON payload to Redis, returns `202`.
4. Flutter clears local Hive cache on successful ACK.
5. Spatial worker picks up the job, runs a Prisma transaction with PostGIS raw SQL.
6. Activity appears in `/api/v1/feed` with `route_geojson` for map rendering.

## Shared Database

All services share a single PostgreSQL database via Prisma. The schema lives at `prisma/schema.prisma`. PostGIS geography columns are marked `Unsupported()` in Prisma and must be read/written via raw SQL.

## Caching Strategy

| Key pattern | TTL | Service |
|-------------|-----|---------|
| `stats:user:{id}` | 5 min | Analytics |
| `leaderboard:segment:{id}` | 1 min | Analytics |

## Related Documents

- [Activity Pipeline](activity-pipeline.md) — Detailed ingest/worker flow
- [Backend Services](backend-services.md) — Per-service implementation
- [Deployment](deployment.md) — Production topology
