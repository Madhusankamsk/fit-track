import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di.dart';
import 'segment_leaderboard_screen.dart';

class SegmentsScreen extends ConsumerStatefulWidget {
  const SegmentsScreen({super.key});

  @override
  ConsumerState<SegmentsScreen> createState() => _SegmentsScreenState();
}

class _SegmentsScreenState extends ConsumerState<SegmentsScreen> {
  List<Map<String, dynamic>> _segments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSegments();
  }

  Future<void> _loadSegments() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/api/v1/segments');
      setState(() {
        _segments = (res.data['segments'] as List)
            .map((s) => Map<String, dynamic>.from(s as Map))
            .toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Segments')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _segments.isEmpty
              ? const Center(child: Text('No segments yet'))
              : ListView.builder(
                  itemCount: _segments.length,
                  itemBuilder: (context, i) {
                    final seg = _segments[i];
                    return ListTile(
                      title: Text(seg['name'] as String? ?? 'Segment'),
                      subtitle: Text(
                        '${(((seg['distance_meters'] as num?) ?? 0) / 1000).toStringAsFixed(2)} km',
                      ),
                      trailing: const Icon(Icons.leaderboard),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SegmentLeaderboardScreen(
                            segmentId: seg['id'] as int,
                            segmentName: seg['name'] as String? ?? 'Segment',
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
