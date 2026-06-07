# Backend Services

## Auth & User Service

**Directory:** `auth-user-service/`  
**Port:** 5001  
**Health:** `GET /health`

### Dependencies
Fastify, `@fastify/jwt`, `@fastify/cors`, `@fastify/rate-limit`, bcrypt, Zod, Prisma

### Routes

| Method | Path | Auth | Handler |
|--------|------|------|---------|
| POST | `/api/v1/auth/register` | No | Create account, return JWT |
| POST | `/api/v1/auth/login` | No | Login, return access + refresh tokens |
| POST | `/api/v1/auth/refresh` | No | Exchange refresh token for new access token |
| GET | `/api/v1/users/:id` | Yes | Profile with recent public activities |
| PUT | `/api/v1/users/me` | Yes | Update bio/username |
| POST | `/api/v1/users/:id/follow` | Yes | Follow a user |
| DELETE | `/api/v1/users/:id/follow` | Yes | Unfollow a user |

### Key Files
- `routes/auth.routes.js` — Register, login, refresh
- `routes/users.routes.js` — Profile and follow system
- `validators/auth.schema.js` — Zod schemas
- `middleware/authenticate.js` — JWT verification hook

### Run
```powershell
cd auth-user-service
npm run dev    # node --watch server.js
```

---

## Activity Ingestion API

**Directory:** `activity-ingestion-api/`  
**Port:** 5002  
**Health:** `GET /health`

### Dependencies
Fastify, `@fastify/jwt`, ioredis, Zod, Prisma

### Routes

| Method | Path | Auth | Handler |
|--------|------|------|---------|
| POST | `/api/v1/ingest` | Yes | Queue GPS batch → Redis, return 202 |
| GET | `/api/v1/feed` | Yes | Paginated feed with GeoJSON routes |
| GET | `/api/v1/activities/:id` | Yes | Single activity detail |
| DELETE | `/api/v1/activities/:id` | Yes | Delete own activity |

### Ingest Behavior
The hot path performs **zero database writes**. Payload is validated, pushed to Redis `activity_queue`, and acknowledged immediately with `202 Accepted`.

### Feed Query
Uses raw SQL with PostGIS `ST_AsGeoJSON`, joins kudos/comments counts, and filters to public activities from followed users plus the viewer's own activities.

### Run
```powershell
cd activity-ingestion-api
npm run dev
```

---

## Spatial Processing Worker

**Directory:** `spatial-processing-worker/`  
**Type:** Background daemon (no HTTP port)

### Dependencies
ioredis, Prisma

### Processing Steps
1. `redis.blpop('activity_queue', 0)` — blocking wait for jobs
2. Build WKT LineString from coordinate array
3. Insert activity row with `ST_GeogFromText`
4. Bulk insert waypoints in chunks of 1000
5. Compute distance via `ST_Length(route)`
6. Update `distance_meters` and `average_pace_sec_per_km`
7. Upsert personal records

### Error Handling
Bad payloads are logged and skipped; the daemon never crashes on a single failed job (1-second backoff on error).

### Key Files
- `worker.js` — Main consumer loop
- `processors/routeProcessor.js` — WKT building, elevation, pace
- `processors/waypointProcessor.js` — Bulk inserts, personal records

### Run
```powershell
cd spatial-processing-worker
npm start
```

---

## Analytics Service

**Directory:** `analytics-service/`  
**Port:** 5003  
**Health:** `GET /health`

### Routes

| Method | Path | Auth | Handler |
|--------|------|------|---------|
| GET | `/api/v1/stats/me` | Yes | Lifetime stats + personal records (cached 5 min) |
| GET | `/api/v1/segments` | Yes | List segments |
| POST | `/api/v1/segments` | Yes | Create segment with PostGIS route |
| GET | `/api/v1/segments/:id/leaderboard` | Yes | Top 50 efforts (cached 1 min) |
| POST | `/api/v1/activities/:id/kudos` | Yes | Give kudo (idempotent upsert) |
| POST | `/api/v1/activities/:id/comments` | Yes | Post comment |

### Run
```powershell
cd analytics-service
npm run dev
```

---

## Dev Gateway

**Directory:** `dev-gateway/`  
**Port:** 8080

Lightweight Fastify proxy for local development. Mirrors Nginx path routing — see [Architecture](architecture.md#gateway-routing-rules).

```powershell
cd dev-gateway
node server.js
```

## Related Documents

- [API Reference](api-reference.md)
- [Activity Pipeline](activity-pipeline.md)
- [Deployment](deployment.md)
