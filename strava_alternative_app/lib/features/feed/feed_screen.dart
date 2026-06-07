import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di.dart';
import '../../models/activity.dart';
import 'activity_card.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  List<Activity> _activities = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() { _loading = true; _error = null; });
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/api/v1/feed');
      final list = (res.data['activities'] as List)
          .map((a) => Activity.fromJson(Map<String, dynamic>.from(a as Map)))
          .toList();
      setState(() { _activities = list; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Failed to load feed'; _loading = false; });
    }
  }

  Future<void> _giveKudo(int activityId, int index) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/v1/activities/$activityId/kudos');
      setState(() {
        final a = _activities[index];
        _activities[index] = Activity(
          id: a.id,
          title: a.title,
          activityType: a.activityType,
          distanceMeters: a.distanceMeters,
          durationSeconds: a.durationSeconds,
          elevationGainMeters: a.elevationGainMeters,
          averagePaceSecPerKm: a.averagePaceSecPerKm,
          startTime: a.startTime,
          userId: a.userId,
          username: a.username,
          profilePictureUrl: a.profilePictureUrl,
          routeGeojson: a.routeGeojson,
          kudosCount: a.kudosCount + 1,
          commentsCount: a.commentsCount,
          viewerHasKudoed: true,
        );
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadFeed),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _activities.isEmpty
                  ? const Center(child: Text('No activities yet. Start tracking!'))
                  : RefreshIndicator(
                      onRefresh: _loadFeed,
                      child: ListView.builder(
                        itemCount: _activities.length,
                        itemBuilder: (context, i) => ActivityCard(
                          activity: _activities[i],
                          onKudo: () => _giveKudo(_activities[i].id, i),
                        ),
                      ),
                    ),
    );
  }
}
