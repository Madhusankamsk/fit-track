# Flutter Mobile App

**Directory:** `strava_alternative_app/`  
**Package name:** `fittrack_pro`

## Architecture

```
main.dart
  └── ProviderScope
        └── FitTrackBootstrap (restores JWT from secure storage)
              └── FitTrackApp (MaterialApp.router)
                    └── GoRouter
                          ├── /login, /register
                          └── MainShell (bottom nav)
                                ├── /feed
                                ├── /track, /save-activity
                                ├── /profile
                                └── /segments
```

## State Management

Riverpod providers in `lib/core/di.dart`:

| Provider | Purpose |
|----------|---------|
| `secureStorageProvider` | flutter_secure_storage instance |
| `dioProvider` | Configured Dio client with JWT interceptor |
| `authServiceProvider` | Login, register, logout |
| `syncServiceProvider` | Hive → API sync |
| `authTokenProvider` | In-memory JWT for router guards |
| `routerProvider` | GoRouter with auth redirect |

## Services

### AuthService (`services/auth_service.dart`)
- Register and login against `/api/v1/auth/*`
- Persists `auth_token` and `refresh_token` in secure storage

### ApiClient (`services/api_client.dart`)
- Creates Dio with base URL from `AppConstants.baseUrl`
- Attaches JWT to every request
- On 401, attempts token refresh via `/api/v1/auth/refresh`

### TrackingService (`services/tracking_service.dart`)
- Configures `flutter_background_service`
- GPS stream via `geolocator` with 3 m distance filter
- Writes waypoints to Hive box `tracking_waypoints`
- Broadcasts live updates to UI via service invoke

### SyncService (`services/sync_service.dart`)
- Harvests Hive waypoints on activity save
- POSTs to `/api/v1/ingest`
- Clears Hive on `202`; retains on failure

## Feature Screens

### Auth (`features/auth/`)
- **LoginScreen** — Email/password login
- **RegisterScreen** — Username, email, password registration

### Tracking (`features/tracking/`)
- **TrackingScreen** — Live map (flutter_map + OSM tiles), HUD with time/speed, START/STOP
- **SaveActivityScreen** — Title, activity type picker, sync trigger

Background GPS listener is attached only when tracking starts (not on screen load) to support widget tests on desktop.

### Feed (`features/feed/`)
- **FeedScreen** — Paginated activity list from `/api/v1/feed`
- **ActivityCard** — Mini map with route polyline, stats chips, kudos button

### Profile (`features/profile/`)
- **ProfileScreen** — Stats from `/api/v1/stats/me`, personal records, logout

### Segments (`features/segments/`)
- **SegmentsScreen** — Segment list from `/api/v1/segments`
- **SegmentLeaderboardScreen** — Ranked efforts for a segment

## Configuration

Edit `lib/core/constants.dart`:

```dart
static const String baseUrl = 'http://10.0.2.2:8080';  // Android emulator
```

| Environment | baseUrl |
|-------------|---------|
| Android emulator | `http://10.0.2.2:8080` |
| iOS simulator | `http://localhost:8080` |
| Physical device | `http://<LAN_IP>:8080` |

## Models

| Model | File | Maps from API |
|-------|------|---------------|
| User | `models/user.dart` | Auth responses |
| Activity | `models/activity.dart` | Feed/detail (snake_case fields) |
| Waypoint | `models/waypoint.dart` | Hive → ingest payload |

## Android Permissions

Configured in `android/app/src/main/AndroidManifest.xml`:
- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`
- `ACCESS_BACKGROUND_LOCATION`
- `FOREGROUND_SERVICE` / `FOREGROUND_SERVICE_LOCATION`
- `INTERNET`

## Running

```powershell
cd strava_alternative_app
flutter pub get
flutter run                  # Device/emulator
flutter test                   # Widget tests
```

### Windows Note
Enable **Developer Mode** for Flutter plugin symlink support (`start ms-settings:developers`).

## Dependencies

Key packages from `pubspec.yaml`:
- `flutter_riverpod` — State management
- `dio` — HTTP client
- `hive_flutter` — Offline waypoint storage
- `flutter_secure_storage` — Token storage
- `flutter_background_service` + `geolocator` — Background GPS
- `flutter_map` + `latlong2` — Map rendering
- `go_router` — Navigation

## Related Documents

- [Getting Started](getting-started.md)
- [Activity Pipeline](activity-pipeline.md)
- [API Reference](api-reference.md)
