import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/tracking_service.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  FlutterBackgroundService? _service;
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
    if (isMobileTrackingSupported) {
      _service = FlutterBackgroundService();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
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
    await Permission.location.request();
    await Permission.locationAlways.request();
  }

  Future<void> _startTracking() async {
    if (!isMobileTrackingSupported) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GPS tracking is only available on Android and iOS.'),
          ),
        );
      }
      return;
    }
    await _requestPermissions();
    _listenToGpsUpdates();
    await _service!.startService();
    _startTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
    });
    setState(() => _isTracking = true);
  }

  Future<void> _stopTracking() async {
    _service?.invoke('stopService');
    _timer?.cancel();
    setState(() => _isTracking = false);
    if (mounted) context.push('/save-activity', extra: {
      'startTime': _startTime,
      'durationSeconds': _elapsedSeconds,
    });
  }

  String get _formattedTime {
    final h = _elapsedSeconds ~/ 3600;
    final m = (_elapsedSeconds % 3600) ~/ 60;
    final s = _elapsedSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
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
