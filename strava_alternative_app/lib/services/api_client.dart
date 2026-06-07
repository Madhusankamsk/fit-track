import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';

Dio createDio(FlutterSecureStorage storage, void Function(String?) onTokenUpdate) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await storage.read(key: 'auth_token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        final refreshToken = await storage.read(key: 'refresh_token');
        if (refreshToken != null) {
          try {
            final res = await Dio().post(
              '${AppConstants.baseUrl}/api/v1/auth/refresh',
              data: {'refreshToken': refreshToken},
            );
            final newToken = res.data['token'] as String;
            await storage.write(key: 'auth_token', value: newToken);
            onTokenUpdate(newToken);
            error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            final retry = await dio.fetch(error.requestOptions);
            return handler.resolve(retry);
          } catch (_) {
            await storage.deleteAll();
            onTokenUpdate(null);
          }
        }
      }
      handler.next(error);
    },
  ));

  return dio;
}
