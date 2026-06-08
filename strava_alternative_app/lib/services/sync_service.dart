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

    final coordinates = sanitizeCoordinatesForIngest(box.values);
    if (coordinates.length < 2) {
      return SyncResult.failure(
        'Not enough GPS points. Walk a few meters, record again, then sync.',
      );
    }

    final token = await _storage.read(key: 'auth_token');
    if (token == null || token.isEmpty) {
      return SyncResult.failure('Not logged in. Please sign in and try again.');
    }

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
          'startTime': startTime.toUtc().toIso8601String(),
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
      final status = e.response?.statusCode;
      if (status == 400) {
        return SyncResult.failure(
          'Invalid activity data (400). Record a new activity and try again. Data kept locally.',
        );
      }
      if (status == 401) {
        return SyncResult.failure('Session expired. Log in again.');
      }
      return SyncResult.failure(
        'Sync failed (${status ?? 'network error'}). Data kept locally.',
      );
    } on FormatException catch (e) {
      return SyncResult.failure(
        'GPS data format error: ${e.message}. Record again.',
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
