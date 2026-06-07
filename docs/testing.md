# Testing

## Backend (Vitest)

Location: `auth-user-service/tests/auth.test.js`

### Run

```powershell
# Auth service must be running on port 5001
cd auth-user-service
npm test
```

Override test target:
```powershell
$env:TEST_AUTH_URL="http://localhost:5001"; npm test
```

### Test Cases

| Test | Expected |
|------|----------|
| Register with invalid email | `400` |
| Register with valid data | `201` + token |
| Login with wrong password | `401` |

### Adding Tests

Use Vitest with native `fetch` against running services. For unit tests that don't need a live server, mock Prisma and Redis.

Config: `auth-user-service/vitest.config.js`

---

## Flutter (Widget Tests)

Location: `strava_alternative_app/test/tracking_screen_test.dart`

### Run

```powershell
cd strava_alternative_app
flutter test
flutter test test/tracking_screen_test.dart   # Single file
```

### Test Cases

| Test | Expected |
|------|----------|
| TrackingScreen initial state | Shows START button, no STOP button |

Note: Background GPS service is initialized only on START (not in `initState`) so tests run on desktop without Android/iOS.

---

## Manual E2E Checklist

Run with all services started (auth, ingest, analytics, worker, gateway) and PostgreSQL + Redis available.

### 1. Authentication
```powershell
# Register
curl -X POST http://localhost:8080/api/v1/auth/register `
  -H "Content-Type: application/json" `
  -d '{"username":"e2euser","email":"e2e@test.com","password":"Securepass1!"}'

# Login — save token
curl -X POST http://localhost:8080/api/v1/auth/login `
  -H "Content-Type: application/json" `
  -d '{"email":"e2e@test.com","password":"Securepass1!"}'
```

### 2. Ingest Activity
```powershell
$token = "<JWT_FROM_LOGIN>"

curl -X POST http://localhost:8080/api/v1/ingest `
  -H "Content-Type: application/json" `
  -H "Authorization: Bearer $token" `
  -d '{
    "title": "Test Run",
    "activityType": "run",
    "startTime": "2026-06-07T06:00:00.000Z",
    "durationSeconds": 600,
    "coordinates": [
      {"latitude": 6.9271, "longitude": 79.8612, "timestamp": "2026-06-07T06:00:01.000Z", "elevation": 10},
      {"latitude": 6.9280, "longitude": 79.8620, "timestamp": "2026-06-07T06:01:00.000Z", "elevation": 12},
      {"latitude": 6.9290, "longitude": 79.8630, "timestamp": "2026-06-07T06:02:00.000Z", "elevation": 15}
    ]
  }'
```
Expected: `202 { "accepted": true }`

### 3. Worker Processing
Wait 2–5 seconds. Check worker terminal for:
```
[Worker] Activity 1 processed: 0.XXkm
```

### 4. Feed
```powershell
curl http://localhost:8080/api/v1/feed `
  -H "Authorization: Bearer $token"
```
Expected: Activity with `route_geojson` populated.

### 5. Kudos
```powershell
curl -X POST http://localhost:8080/api/v1/activities/1/kudos `
  -H "Authorization: Bearer $token"
```
Expected: `201 { "success": true }`. Feed should show `kudos_count: 1`.

### 6. Stats
```powershell
curl http://localhost:8080/api/v1/stats/me `
  -H "Authorization: Bearer $token"
```
Expected: `total_activities >= 1`, distance > 0.

### 7. Flutter End-to-End
1. Register/login in app
2. Start tracking → stop → save
3. Verify activity appears in feed with map route
4. Tap kudo → count increments
5. Check profile stats

---

## CI Recommendations

A future CI pipeline should:
1. Spin up PostgreSQL+PostGIS and Redis as service containers
2. Run `prisma migrate deploy` + PostGIS indexes
3. Start all Node services
4. Run Vitest integration tests
5. Run `flutter test` (headless)
6. Build Docker images

## Related Documents

- [Getting Started](getting-started.md)
- [API Reference](api-reference.md)
- [Troubleshooting](troubleshooting.md)
