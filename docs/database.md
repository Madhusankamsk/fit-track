# Database

FitTrack Pro uses **PostgreSQL 16** with the **PostGIS 3.4** extension for spatial data. Prisma manages the schema; PostGIS geography columns require raw SQL for reads and writes.

## Schema Location

```
prisma/schema.prisma
```

## Entity Relationship Overview

```
User ──┬── Activity ──┬── ActivityWaypoint
       │              ├── Kudo
       │              ├── Comment
       │              └── SegmentEffort
       ├── Follow (follower/following)
       ├── SegmentEffort
       ├── Kudo
       ├── Comment
       └── PersonalRecord

Segment ── SegmentEffort
```

## Tables

| Table | Purpose |
|-------|---------|
| `users` | Accounts, profiles, refresh tokens |
| `follows` | Follower/following relationships |
| `activities` | Workout records with PostGIS route LineString |
| `activity_waypoints` | High-frequency GPS ticks as Point geography |
| `segments` | Named route sections with start/end points |
| `segment_efforts` | User attempts on segments |
| `kudos` | Likes on activities (unique per user+activity) |
| `comments` | Text comments on activities |
| `personal_records` | Cached PRs (longest run, fastest pace) |

## PostGIS Geography Columns

These columns are declared as `Unsupported()` in Prisma:

| Model | Column | Type |
|-------|--------|------|
| Activity | `route` | `geography(LineString, 4326)` |
| ActivityWaypoint | `location` | `geography(Point, 4326)` |
| Segment | `start_point`, `end_point` | `geography(Point, 4326)` |
| Segment | `segment_route` | `geography(LineString, 4326)` |

### Writing PostGIS Data

Use parameterized `$executeRaw` with `ST_GeogFromText()`:

```javascript
await tx.$executeRaw`
  INSERT INTO activities (..., route)
  VALUES (..., ST_GeogFromText(${lineStringWKT}))
`;
```

WKT format: `LINESTRING(lon lat, lon lat, ...)` and `POINT(lon lat)`.

### Reading PostGIS Data

Use `$queryRaw` with `ST_AsGeoJSON()`:

```sql
SELECT ST_AsGeoJSON(a.route)::json AS route_geojson FROM activities a
```

## Migrations

### Initial Migration

```powershell
npm run prisma:migrate
```

This runs `prisma migrate dev` against `prisma/schema.prisma` and creates tables.

Migration files live in `prisma/migrations/20240607000000_init/`.

### PostGIS Indexes

After the Prisma migration, apply spatial indexes manually:

```powershell
psql $env:DATABASE_URL -f prisma/migrations/postgis_indexes.sql
```

This script:
1. Enables the PostGIS extension
2. Creates GIST indexes on geography columns
3. Adds a covering index for feed queries (`user_id, created_at DESC`)

## Prisma Client Generation

```powershell
npm run prisma:generate
```

Generated client is output to root `node_modules/@prisma/client`. Each service imports `@prisma/client` after generation.

## Personal Records

The spatial worker updates these record types automatically:

| Record Type | Value Unit | Logic |
|-------------|-----------|-------|
| `longest_run` | meters | Max distance |
| `fastest_pace_per_km` | seconds/km | Min pace for runs ≥ 1 km |

## Related Documents

- [Activity Pipeline](activity-pipeline.md)
- [Backend Services](backend-services.md)
