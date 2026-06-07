import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/activity.dart';

class ActivityCard extends StatelessWidget {
  final Activity activity;
  final VoidCallback? onKudo;

  const ActivityCard({super.key, required this.activity, this.onKudo});

  List<LatLng> _parseRoute() {
    final geojson = activity.routeGeojson;
    if (geojson == null) return [];
    final coords = geojson['coordinates'] as List?;
    if (coords == null) return [];
    return coords
        .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList();
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(2)} km';
    return '${meters.toStringAsFixed(0)} m';
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final routePoints = _parseRoute();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (routePoints.isNotEmpty)
            SizedBox(
              height: 120,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: routePoints.first,
                  initialZoom: 13,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.fittrack.pro',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(points: routePoints, color: Colors.orange, strokeWidth: 3),
                    ],
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.title, style: Theme.of(context).textTheme.titleMedium),
                Text('@${activity.username}', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Chip(label: _formatDistance(activity.distanceMeters)),
                    const SizedBox(width: 8),
                    _Chip(label: _formatDuration(activity.durationSeconds)),
                    const SizedBox(width: 8),
                    _Chip(label: '${activity.elevationGainMeters.toStringAsFixed(0)} m elev'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        activity.viewerHasKudoed ? Icons.favorite : Icons.favorite_border,
                        color: activity.viewerHasKudoed ? Colors.red : null,
                      ),
                      onPressed: onKudo,
                    ),
                    Text('${activity.kudosCount}'),
                    const SizedBox(width: 16),
                    const Icon(Icons.comment_outlined, size: 20),
                    const SizedBox(width: 4),
                    Text('${activity.commentsCount}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
