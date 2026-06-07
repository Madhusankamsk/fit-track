import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di.dart';

class SegmentLeaderboardScreen extends ConsumerStatefulWidget {
  final int segmentId;
  final String segmentName;

  const SegmentLeaderboardScreen({
    super.key,
    required this.segmentId,
    required this.segmentName,
  });

  @override
  ConsumerState<SegmentLeaderboardScreen> createState() =>
      _SegmentLeaderboardScreenState();
}

class _SegmentLeaderboardScreenState extends ConsumerState<SegmentLeaderboardScreen> {
  List<Map<String, dynamic>> _leaderboard = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/api/v1/segments/${widget.segmentId}/leaderboard');
      setState(() {
        _leaderboard = (res.data as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  String _formatTime(num seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).round();
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.segmentName)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _leaderboard.isEmpty
              ? const Center(child: Text('No efforts yet'))
              : ListView.builder(
                  itemCount: _leaderboard.length,
                  itemBuilder: (context, i) {
                    final entry = _leaderboard[i];
                    return ListTile(
                      leading: CircleAvatar(child: Text('${entry['rank'] ?? i + 1}')),
                      title: Text(entry['username'] as String? ?? 'Unknown'),
                      subtitle: Text('${entry['attempt_count'] ?? 0} attempts'),
                      trailing: Text(
                        _formatTime(entry['best_time_seconds'] ?? 0),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
    );
  }
}
