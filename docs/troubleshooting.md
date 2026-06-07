# Troubleshooting

## npm install fails with ENOTEMPTY

**Symptom:** `npm error ENOTEMPTY: directory not empty, rmdir '...node_modules/...'`

**Cause:** Interrupted previous install left a corrupted `node_modules`.

**Fix:**
```powershell
Remove-Item -Recurse -Force node_modules
npm install
```

Repeat for individual service directories if needed.

---

## Prisma Client Not Found

**Symptom:** `Cannot find module '@prisma/client'`

**Fix:**
```powershell
npm run prisma:generate
```

Run from repo root after any schema change.

---

## Database Connection Refused

**Symptom:** `Can't reach database server at localhost:5432`

**Checks:**
1. PostgreSQL service is running
2. `DATABASE_URL` in `.env` matches your credentials
3. Database `fittrack_db` exists
4. In Docker: use host `postgres` not `localhost`

---

## PostGIS Extension Missing

**Symptom:** `type "geography" does not exist`

**Fix:**
```sql
CREATE EXTENSION IF NOT EXISTS postgis;
```

Then apply indexes:
```powershell
psql $env:DATABASE_URL -f prisma/migrations/postgis_indexes.sql
```

---

## Redis Connection Refused

**Symptom:** `ECONNREFUSED 127.0.0.1:6379`

**Checks:**
1. Redis/Memurai is running
2. `redis-cli ping` returns `PONG`
3. `REDIS_URL=redis://localhost:6379` in `.env`

Ingest and worker services require Redis.

---

## Activity Not Appearing in Feed

**Checks:**
1. Spatial worker is running (`npm run dev:worker`)
2. Worker logs show successful processing
3. Activity has `is_public = true` (default)
4. For other users' activities: you must follow them
5. Wait a few seconds after ingest (async processing)

---

## Flutter: Symlink / Developer Mode Error

**Symptom:** `Building with plugins requires symlink support`

**Fix:** Enable Developer Mode in Windows Settings:
```powershell
start ms-settings:developers
```

Toggle **Developer Mode** on, then retry `flutter run`.

---

## Flutter: Cannot Connect to API

**Symptom:** Network errors, login fails on device

**Fixes by target:**

| Target | Set `AppConstants.baseUrl` to |
|--------|-------------------------------|
| Android emulator | `http://10.0.2.2:8080` |
| iOS simulator | `http://localhost:8080` |
| Physical device | `http://<YOUR_PC_LAN_IP>:8080` |

Ensure dev gateway is running and Windows Firewall allows port 8080.

---

## Flutter: Background GPS Not Working

**Checks:**
1. Location permissions granted (including background on Android 10+)
2. Testing on a real device (emulator GPS is limited)
3. `flutter_background_service` is Android/iOS only — not supported on desktop

---

## 401 Unauthorized on API Calls

**Checks:**
1. Token included: `Authorization: Bearer <token>`
2. Token not expired (15 min default) — use refresh endpoint
3. All services use the same `JWT_SECRET`

---

## Gateway Returns 404

**Symptom:** Valid API path returns `{ "error": "Route not found" }`

**Checks:**
1. Dev gateway is running on port 8080
2. Target microservice is running on its port
3. Path matches routing rules in [Architecture](architecture.md#gateway-routing-rules)

---

## Docker Build Fails

**Symptom:** `COPY ../prisma` or missing schema errors

**Fix:** Build from repo root:
```powershell
docker build -f auth-user-service/Dockerfile .
```

Not from inside the service directory.

---

## npm audit warnings

Several Fastify dependencies may report moderate/high vulnerabilities in dev transitive packages. Run `npm audit` for details. For production, keep dependencies updated and review advisories.

## Related Documents

- [Getting Started](getting-started.md)
- [Environment Variables](environment-variables.md)
- [Testing](testing.md)
