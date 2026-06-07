# Activity Pipeline

This document describes the end-to-end flow from GPS recording on the mobile device to a processed activity appearing in the feed.

## Pipeline Overview

```
Mobile (Hive) → POST /ingest → Redis Queue → Spatial Worker → PostgreSQL → GET /feed
     │              │                │              │              │
  Offline OK    202 ACK          BLPOP         PostGIS TX      GeoJSON
```

## Stage 1: Mobile Recording

1. User taps **START** on the tracking screen.
2. `flutter_background_service` starts a GPS stream via `geolocator`.
3. Each position is written to a Hive box (`tracking_waypoints`) immediately — safe if the app loses connectivity.
4. Live updates are broadcast to the UI for map rendering and HUD stats.

**Hive waypoint shape:**
```json
{
  "latitude": 6.9271,
  "longitude": 79.8612,
  "timestamp": "2026-06-07T06:00:01.000Z",
  "elevation": 10.5,
  "speed": 3.2,
  "accuracy": 5.0
}
```

## Stage 2: Sync (Ingest API)

When the user saves an activity, `SyncService`:

1. Reads all waypoints from Hive
2. POSTs to `/api/v1/ingest` with title, activity type, start time, duration, and coordinates
3. On `202 Accepted`, clears the Hive box
4. On network failure, retains Hive data for retry

The ingestion API:
- Validates the payload with Zod (min 2 coordinates, max 100k)
- Builds a job payload: `{ userId, title, activityType, startTime, durationSeconds, coordinates, receivedAt }`
- `redis.rpush('activity_queue', JSON.stringify(payload))`
- Returns `{ accepted: true, queuedAt: "..." }` — **no database write**

## Stage 3: Queue (Redis)

Jobs sit in a Redis list named `activity_queue` (configurable via `ACTIVITY_QUEUE_NAME`). The spatial worker uses blocking `BLPOP` — zero CPU spin while waiting.

Properties:
- FIFO ordering
- Decouples ingest latency from processing time
- Survives brief worker downtime (jobs accumulate in Redis)

## Stage 4: Spatial Worker

For each dequeued job, the worker runs a single Prisma transaction:

### 4a. Create Activity
```sql
INSERT INTO activities (user_id, title, activity_type, start_time, duration_seconds,
  elapsed_time_seconds, elevation_gain_meters, max_heart_rate, average_heart_rate, route)
VALUES (..., ST_GeogFromText('LINESTRING(lon lat, ...)')))
```

### 4b. Insert Waypoints
Bulk insert in chunks of 1000:
```sql
INSERT INTO activity_waypoints (activity_id, time_stamp, ..., location)
VALUES (..., ST_GeogFromText('POINT(lon lat)'))
```

### 4c. Compute Distance
```sql
SELECT ST_Length(route) AS distance_meters FROM activities WHERE id = ?
```
`ST_Length` on geography uses geodesic (ellipsoidal) calculation.

### 4d. Update Stats
```sql
UPDATE activities SET distance_meters = ?, average_pace_sec_per_km = ? WHERE id = ?
```

### 4e. Personal Records
Upserts `longest_run` and `fastest_pace_per_km` if the new activity beats existing records.

## Stage 5: Feed Read

When a client calls `GET /api/v1/feed`, the ingestion API runs a PostGIS query:

```sql
SELECT ..., ST_AsGeoJSON(a.route)::json AS route_geojson, ...
FROM activities a
WHERE a.is_public = true
  AND (a.user_id = :viewer OR a.user_id IN (SELECT following_id FROM follows WHERE follower_id = :viewer))
ORDER BY a.created_at DESC
```

The Flutter feed screen parses `route_geojson` into map polylines.

## Timing Expectations

| Stage | Typical Latency |
|-------|----------------|
| Ingest ACK | < 50 ms |
| Worker processing (1k points) | 1–3 s |
| Worker processing (10k points) | 5–15 s |
| Feed visibility | After worker commit |

## Failure Modes

| Failure | Behavior |
|---------|----------|
| Redis down | Ingest returns 500; Hive data retained on mobile |
| Worker crash mid-job | Job lost (not acked back to queue); consider adding retry/dead-letter in production |
| Bad coordinates | Worker logs error, skips job, continues loop |
| Duplicate sync | Creates duplicate activities (client should clear Hive only on 202) |

## Related Documents

- [Database](database.md)
- [Backend Services](backend-services.md)
- [Flutter Mobile App](flutter-mobile.md)
