import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'tracking_service.dart';

class SyncService {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  SyncService(this._dio, this._storage);

  Future<SyncResult> syncActivity({
    required String title,
    required String activityType,
    required DateTime startTime,
    required int durationSeconds,
  }) async {
    final box = await openTrackingBox();

    if (box.isEmpty) {
      return SyncResult.failure('No GPS data recorded');
    }

    final coordinates = box.values
        .map((w) => Map<String, dynamic>.from(w))
        .toList();

    final token = await _storage.read(key: 'auth_token');

    try {
      final response = await _dio.post(
        '/api/v1/ingest',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 30),
        ),
        data: {
          'title': title,
          'activityType': activityType,
          'startTime': startTime.toIso8601String(),
          'durationSeconds': durationSeconds,
          'coordinates': coordinates,
        },
      );

      if (response.statusCode == 202) {
        await box.clear();
        return SyncResult.success();
      }
      return SyncResult.failure('Unexpected response: ${response.statusCode}');
    } on DioException catch (e) {
      return SyncResult.failure(
        'Sync failed: ${e.message}. Data kept locally.',
      );
    }
  }
}

class SyncResult {
  final bool success;
  final String? error;
  SyncResult.success() : success = true, error = null;
  SyncResult.failure(this.error) : success = false;
}
