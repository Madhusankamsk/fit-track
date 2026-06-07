import 'package:flutter/foundation.dart';

class AppConstants {
  /// Android emulator uses 10.0.2.2 to reach host localhost.
  static String get baseUrl {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return 'http://localhost:8081';
    }
    return 'http://10.0.2.2:8081';
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
