class Activity {
  final int id;
  final String title;
  final String activityType;
  final double distanceMeters;
  final int durationSeconds;
  final double elevationGainMeters;
  final double? averagePaceSecPerKm;
  final DateTime startTime;
  final int userId;
  final String username;
  final String? profilePictureUrl;
  final Map<String, dynamic>? routeGeojson;
  final int kudosCount;
  final int commentsCount;
  final bool viewerHasKudoed;

  Activity({
    required this.id,
    required this.title,
    required this.activityType,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.elevationGainMeters,
    this.averagePaceSecPerKm,
    required this.startTime,
    required this.userId,
    required this.username,
    this.profilePictureUrl,
    this.routeGeojson,
    required this.kudosCount,
    required this.commentsCount,
    required this.viewerHasKudoed,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as int,
      title: json['title'] as String,
      activityType: json['activity_type'] as String? ?? 'run',
      distanceMeters: (json['distance_meters'] as num?)?.toDouble() ?? 0,
      durationSeconds: json['duration_seconds'] as int? ?? 0,
      elevationGainMeters: (json['elevation_gain_meters'] as num?)?.toDouble() ?? 0,
      averagePaceSecPerKm: (json['average_pace_sec_per_km'] as num?)?.toDouble(),
      startTime: DateTime.parse(json['start_time'] as String),
      userId: json['user_id'] as int,
      username: json['username'] as String,
      profilePictureUrl: json['profile_picture_url'] as String?,
      routeGeojson: json['route_geojson'] as Map<String, dynamic>?,
      kudosCount: json['kudos_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      viewerHasKudoed: json['viewer_has_kudoed'] as bool? ?? false,
    );
  }
}
