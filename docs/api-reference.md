# API Reference

Base URL (local dev): `http://localhost:8080`

All authenticated endpoints require:
```
Authorization: Bearer <access_token>
```

## Authentication

### POST /api/v1/auth/register

Create a new account.

**Request:**
```json
{
  "username": "runner1",
  "email": "runner1@example.com",
  "password": "Securepass1!"
}
```

**Response `201`:**
```json
{
  "user": { "id": 1, "username": "runner1", "email": "runner1@example.com", "createdAt": "..." },
  "token": "eyJ..."
}
```

**Validation:**
- `username`: 3–50 chars, alphanumeric + underscore
- `password`: 8–72 chars

---

### POST /api/v1/auth/login

**Request:**
```json
{ "email": "runner1@example.com", "password": "Securepass1!" }
```

**Response `200`:**
```json
{
  "token": "eyJ...",
  "refreshToken": "eyJ...",
  "user": { "id": 1, "username": "runner1", "email": "...", "profilePictureUrl": null }
}
```

---

### POST /api/v1/auth/refresh

**Request:**
```json
{ "refreshToken": "eyJ..." }
```

**Response `200`:**
```json
{ "token": "eyJ..." }
```

---

## Users

### GET /api/v1/users/:id

Returns profile, follower/following counts, and up to 20 recent public activities.

### PUT /api/v1/users/me

**Request:**
```json
{ "bio": "Marathon trainee", "username": "newname" }
```

### POST /api/v1/users/:id/follow

Follow a user. Returns `201 { "success": true }`.

### DELETE /api/v1/users/:id/follow

Unfollow a user. Returns `200 { "success": true }`.

---

## Activities

### POST /api/v1/ingest

Submit a GPS activity for async processing. Returns immediately.

**Request:**
```json
{
  "title": "Morning Run",
  "activityType": "run",
  "startTime": "2026-06-07T06:00:00.000Z",
  "durationSeconds": 3600,
  "coordinates": [
    {
      "latitude": 6.9271,
      "longitude": 79.8612,
      "timestamp": "2026-06-07T06:00:01.000Z",
      "elevation": 10.5,
      "heartRate": 145,
      "speed": 3.2,
      "accuracy": 5.0
    }
  ]
}
```

**Activity types:** `run`, `ride`, `swim`, `walk`, `hike`, `workout`

**Response `202`:**
```json
{ "accepted": true, "queuedAt": "2026-06-07T07:00:00.000Z" }
```

Minimum 2 coordinates required. Maximum controlled by `MAX_WAYPOINTS_PER_ACTIVITY` (default 100,000).

---

### GET /api/v1/feed

**Query params:** `page` (default 1), `limit` (default 20)

**Response `200`:**
```json
{
  "activities": [
    {
      "id": 1,
      "title": "Morning Run",
      "activity_type": "run",
      "distance_meters": 5200.5,
      "duration_seconds": 1800,
      "elevation_gain_meters": 45.0,
      "average_pace_sec_per_km": 346.2,
      "start_time": "...",
      "created_at": "...",
      "user_id": 1,
      "username": "runner1",
      "profile_picture_url": null,
      "route_geojson": { "type": "LineString", "coordinates": [[79.86, 6.92], ...] },
      "kudos_count": 3,
      "comments_count": 1,
      "viewer_has_kudoed": false
    }
  ],
  "page": 1,
  "limit": 20
}
```

---

### GET /api/v1/activities/:id

Single activity with full detail and GeoJSON route.

### DELETE /api/v1/activities/:id

Delete own activity. Returns `204 No Content`.

---

## Stats

### GET /api/v1/stats/me

**Response `200`:**
```json
{
  "stats": {
    "total_activities": 42,
    "total_distance_meters": 210000,
    "total_duration_seconds": 72000,
    "total_elevation_gain": 3500,
    "avg_pace_sec_per_km": 343.0,
    "longest_run_meters": 21097.5
  },
  "personalRecords": [
    { "recordType": "longest_run", "value": 21097.5, "achievedAt": "..." }
  ]
}
```

Cached in Redis for 5 minutes.

---

## Segments

### GET /api/v1/segments

List up to 100 segments with GeoJSON routes.

### POST /api/v1/segments

**Request:**
```json
{
  "name": "Park Loop",
  "startLatitude": 6.9271,
  "startLongitude": 79.8612,
  "endLatitude": 6.9300,
  "endLongitude": 79.8650,
  "routeCoordinates": [
    { "latitude": 6.9271, "longitude": 79.8612 },
    { "latitude": 6.9300, "longitude": 79.8650 }
  ]
}
```

### GET /api/v1/segments/:id/leaderboard

Returns top 50 efforts ranked by best time. Cached 1 minute.

---

## Social

### POST /api/v1/activities/:id/kudos

Idempotent — giving kudo twice has no duplicate effect. Returns `201 { "success": true }`.

### POST /api/v1/activities/:id/comments

**Request:**
```json
{ "text": "Great run!" }
```

**Response `201`:** Comment object with user info.

---

## Error Responses

| Status | Meaning |
|--------|---------|
| 400 | Validation error (Zod flatten in `error` field) |
| 401 | Missing or invalid JWT |
| 403 | Forbidden (e.g., deleting another user's activity) |
| 404 | Resource not found |
| 409 | Conflict (duplicate email/username) |

## Rate Limiting

Applied at both Nginx (production) and Fastify layers:
- Auth endpoints: 10 req/min
- Ingest: 60 req/min
- General API: 200 req/min

## Related Documents

- [Backend Services](backend-services.md)
- [Security](security.md)
- [Activity Pipeline](activity-pipeline.md)
