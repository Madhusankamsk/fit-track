class AppConstants {
  /// Deployed Docker API (nginx on Portainer). Local dev override:
  /// `flutter run --dart-define=API_BASE_URL=http://localhost:8080`
  static const String _deployedApiUrl = 'http://100.115.79.13:8080';

  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    return _deployedApiUrl;
  }

  static const String activityQueue = 'activity_queue';

  static const double gpsDistanceFilter = 3.0;
  static const int gpsSaveIntervalMs = 1000;

  static const String trackingBox = 'tracking_waypoints';
  static const String settingsBox = 'settings';

  static const List<String> activityTypes = [
    'run',
    'ride',
    'swim',
    'walk',
    'hike',
    'workout',
  ];
}
