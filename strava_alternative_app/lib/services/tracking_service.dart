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
