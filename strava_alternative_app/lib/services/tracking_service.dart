import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants.dart';

bool get isMobileTrackingSupported =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

Future<void> initializeBackgroundService() async {
  if (!isMobileTrackingSupported) return;

  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'fittrack_tracking',
      initialNotificationTitle: 'FitTrack Pro',
      initialNotificationContent: 'Tracking your activity...',
      foregroundServiceNotificationId: 888,
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

  final box = await Hive.openBox<Map>(AppConstants.trackingBox);
  int waypointCount = 0;

  service.on('stopService').listen((event) async {
    await box.close();
    service.stopSelf();
  });

  final positionStream = Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 3,
    ),
  );

  positionStream.listen((Position position) async {
    final waypoint = {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': position.timestamp.toIso8601String(),
      'elevation': position.altitude,
      'speed': position.speed,
      'accuracy': position.accuracy,
    };

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
