import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_platform_interface/flutter_background_service_platform_interface.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants.dart';

bool get isMobileTrackingSupported =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

bool get usesBackgroundTrackingService =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

Map<String, dynamic> waypointFromPosition(Position position) {
  final waypoint = <String, dynamic>{
    'latitude': position.latitude,
    'longitude': position.longitude,
    'timestamp': position.timestamp.toUtc().toIso8601String(),
    'elevation': position.altitude,
  };
  if (position.speed >= 0) waypoint['speed'] = position.speed;
  if (position.accuracy >= 0) waypoint['accuracy'] = position.accuracy;
  return waypoint;
}

double _readDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.parse(value);
  throw FormatException('Invalid coordinate number: $value');
}

String _readTimestamp(dynamic value) {
  if (value is String) {
    return DateTime.parse(value).toUtc().toIso8601String();
  }
  if (value is DateTime) return value.toUtc().toIso8601String();
  throw FormatException('Invalid timestamp: $value');
}

List<Map<String, dynamic>> sanitizeCoordinatesForIngest(
  Iterable<dynamic> rawWaypoints,
) {
  final coords = rawWaypoints.map((w) {
    final m = Map<String, dynamic>.from(w as Map);
    final coord = <String, dynamic>{
      'latitude': _readDouble(m['latitude']),
      'longitude': _readDouble(m['longitude']),
      'timestamp': _readTimestamp(m['timestamp']),
    };
    final elevation = m['elevation'] as num?;
    if (elevation != null && elevation.isFinite) {
      coord['elevation'] = elevation.toDouble();
    }
    final speed = m['speed'] as num?;
    if (speed != null && speed >= 0) coord['speed'] = speed.toDouble();
    final accuracy = m['accuracy'] as num?;
    if (accuracy != null && accuracy >= 0) {
      coord['accuracy'] = accuracy.toDouble();
    }
    return coord;
  }).toList();

  // API requires at least 2 points for a route LineString.
  if (coords.length == 1) {
    final only = coords.first;
    final ts = DateTime.parse(only['timestamp'] as String);
    coords.add({
      ...only,
      'timestamp': ts.add(const Duration(seconds: 1)).toUtc().toIso8601String(),
    });
  }

  return coords;
}

Future<Box<Map>> openTrackingBox() async {
  if (Hive.isBoxOpen(AppConstants.trackingBox)) {
    return Hive.box<Map>(AppConstants.trackingBox);
  }
  return Hive.openBox<Map>(AppConstants.trackingBox);
}

Future<void> prepareMobileTracking() async {
  if (!isMobileTrackingSupported) return;

  if (defaultTargetPlatform == TargetPlatform.android) {
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke('stopService');
    }
    return;
  }

  await initializeBackgroundService();
}

Future<void> initializeBackgroundService() async {
  if (!usesBackgroundTrackingService) return;

  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      initialNotificationTitle: 'FitTrack Pro',
      initialNotificationContent: 'Tracking your activity...',
      foregroundServiceNotificationId: 888,
      foregroundServiceTypes: const [AndroidForegroundType.location],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  await Hive.initFlutter();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  await Hive.initFlutter();

  final box = await openTrackingBox();
  int waypointCount = 0;

  service.on('stopService').listen((event) async {
    if (Hive.isBoxOpen(AppConstants.trackingBox)) {
      await Hive.box<Map>(AppConstants.trackingBox).close();
    }
    service.stopSelf();
  });

  final positionStream = Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 3,
    ),
  );

  positionStream.listen((Position position) async {
    final waypoint = waypointFromPosition(position);

    await box.add(waypoint);
    waypointCount++;

    service.invoke('update', {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'speed': position.speed,
      'waypointCount': waypointCount,
      'timestamp': position.timestamp.toIso8601String(),
    });
  });
}
