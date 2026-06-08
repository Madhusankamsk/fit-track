import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants.dart';
import '../../services/tracking_service.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  FlutterBackgroundService? _service;
  StreamSubscription<Position>? _positionSub;
  final MapController _mapController = MapController();
  final List<LatLng> _routePoints = [];

  bool _isTracking = false;
  double _currentSpeed = 0.0;
  int _elapsedSeconds = 0;
  DateTime? _startTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (usesBackgroundTrackingService) {
      _service = FlutterBackgroundService();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionSub?.cancel();
    super.dispose();
  }

  void _listenToGpsUpdates() {
    _service?.on('update').listen((data) {
      if (data == null) return;
      final point = LatLng(
        data['latitude'] as double,
        data['longitude'] as double,
      );
      setState(() {
        _routePoints.add(point);
        _currentSpeed = (data['speed'] as double?) ?? 0.0;
      });
      _mapController.move(point, 16.0);
    });
  }

  Future<void> _requestPermissions() async {
    await Permission.notification.request();
    await Permission.location.request();
    await Permission.locationAlways.request();
  }

  Future<void> _startAndroidTracking() async {
    final box = await openTrackingBox();
    await box.clear();

    try {
      final current = await Geolocator.getCurrentPosition();
      final point = LatLng(current.latitude, current.longitude);
      await box.add(waypointFromPosition(current));
      if (mounted) {
        setState(() => _routePoints.add(point));
        _mapController.move(point, 16.0);
      }
    } catch (_) {}

    final settings = AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: AppConstants.gpsDistanceFilter.toInt(),
      foregroundNotificationConfig: ForegroundNotificationConfig(
        notificationTitle: 'FitTrack Pro',
        notificationText: 'Tracking your activity...',
        notificationChannelName: 'Activity Tracking',
        setOngoing: true,
      ),
    );

    _positionSub = Geolocator.getPositionStream(locationSettings: settings).listen(
      (position) async {
        await box.add(waypointFromPosition(position));

        final point = LatLng(position.latitude, position.longitude);
        if (!mounted) return;
        setState(() {
          _routePoints.add(point);
          _currentSpeed = position.speed;
        });
        _mapController.move(point, 16.0);
      },
    );
  }

  Future<void> _startTracking() async {
    if (!isMobileTrackingSupported) return;
    await _requestPermissions();

    if (usesBackgroundTrackingService) {
      _listenToGpsUpdates();
      await _service!.startService();
    } else {
      await _startAndroidTracking();
    }

    _startTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
    });
    setState(() => _isTracking = true);
  }

  Future<void> _stopTracking() async {
    if (usesBackgroundTrackingService) {
      _service?.invoke('stopService');
    } else {
      await _positionSub?.cancel();
      _positionSub = null;
    }

    _timer?.cancel();
    setState(() => _isTracking = false);
    if (mounted) {
      context.push('/save-activity', extra: {
        'startTime': _startTime,
        'durationSeconds': _elapsedSeconds,
      });
    }
  }

  String get _formattedTime {
    final h = _elapsedSeconds ~/ 3600;
    final m = (_elapsedSeconds % 3600) ~/ 60;
    final s = _elapsedSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildMobileFallback() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.gps_off, size: 72, color: Colors.orange),
            SizedBox(height: 24),
            Text(
              'GPS Tracking is only available on Mobile Devices.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text(
              'Use the FitTrack Pro app on Android or iOS to record activities with live GPS.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isMobileTrackingSupported) {
      return Scaffold(
        appBar: AppBar(title: const Text('Track')),
        body: _buildMobileFallback(),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _routePoints.isNotEmpty
                  ? _routePoints.last
                  : const LatLng(6.9271, 79.8612),
              initialZoom: 16.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.fittrack.pro',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    color: Colors.orange,
                    strokeWidth: 4.0,
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 32,
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(label: 'Time', value: _formattedTime),
                        _StatItem(
                          label: 'Speed',
                          value: '${(_currentSpeed * 3.6).toStringAsFixed(1)} km/h',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isTracking ? _stopTracking : _startTracking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isTracking ? Colors.red : Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _isTracking ? 'STOP' : 'START',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
