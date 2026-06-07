import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/di.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Map<String, dynamic>? _stats;
  List<dynamic> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/api/v1/stats/me');
      setState(() {
        _stats = Map<String, dynamic>.from(res.data['stats'] as Map);
        _records = res.data['personalRecords'] as List? ?? [];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await ref.read(authServiceProvider).logout();
    ref.read(authTokenProvider.notifier).state = null;
    if (mounted) context.go('/login');
  }

  String _formatDistance(num meters) {
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(1)} km';
    return '${meters.toStringAsFixed(0)} m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _stats == null
              ? const Center(child: Text('Failed to load stats'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _StatCard(
                      title: 'Total Distance',
                      value: _formatDistance(_stats!['total_distance_meters'] ?? 0),
                    ),
                    _StatCard(
                      title: 'Total Activities',
                      value: '${_stats!['total_activities'] ?? 0}',
                    ),
                    _StatCard(
                      title: 'Total Elevation',
                      value: '${(_stats!['total_elevation_gain'] ?? 0).toStringAsFixed(0)} m',
                    ),
                    _StatCard(
                      title: 'Longest Run',
                      value: _formatDistance(_stats!['longest_run_meters'] ?? 0),
                    ),
                    if (_records.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text('Personal Records', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ..._records.map((r) => ListTile(
                            title: Text(r['recordType'] as String? ?? ''),
                            trailing: Text(r['value'].toString()),
                          )),
                    ],
                  ],
                ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
    );
  }
}
