class Waypoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? elevation;
  final double? speed;
  final double? accuracy;

  Waypoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.elevation,
    this.speed,
    this.accuracy,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp.toIso8601String(),
        if (elevation != null) 'elevation': elevation,
        if (speed != null) 'speed': speed,
        if (accuracy != null) 'accuracy': accuracy,
      };
}
