import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';

const _authTokenKey = 'auth_token';
const _refreshTokenKey = 'refresh_token';

class JwtRefreshInterceptor extends Interceptor {
  JwtRefreshInterceptor({
    required this.storage,
    required this.dio,
    required this.onTokenUpdate,
  });

  final FlutterSecureStorage storage;
  final Dio dio;
  final void Function(String?) onTokenUpdate;

  Future<String?>? _refreshInFlight;

  bool _isAuthEndpoint(String path) {
    return path.contains('/api/v1/auth/login') ||
        path.contains('/api/v1/auth/register') ||
        path.contains('/api/v1/auth/refresh');
  }

  Future<String?> _refreshAccessToken(String refreshToken) async {
    final refreshClient = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    final response = await refreshClient.post(
      '/api/v1/auth/refresh',
      data: {'refreshToken': refreshToken},
    );

    final newToken = response.data['token'] as String;
    await storage.write(key: _authTokenKey, value: newToken);
    onTokenUpdate(newToken);
    return newToken;
  }

  Future<String?> _coordinatedRefresh(String refreshToken) {
    _refreshInFlight ??= _refreshAccessToken(refreshToken).whenComplete(() {
      _refreshInFlight = null;
    });
    return _refreshInFlight!;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await storage.read(key: _authTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final path = err.requestOptions.path;

    if (statusCode != 401 || _isAuthEndpoint(path)) {
      return handler.next(err);
    }

    if (err.requestOptions.extra['retried'] == true) {
      await storage.deleteAll();
      onTokenUpdate(null);
      return handler.next(err);
    }

    final refreshToken = await storage.read(key: _refreshTokenKey);
    if (refreshToken == null) {
      await storage.deleteAll();
      onTokenUpdate(null);
      return handler.next(err);
    }

    try {
      final newToken = await _coordinatedRefresh(refreshToken);
      if (newToken == null) {
        await storage.deleteAll();
        onTokenUpdate(null);
        return handler.next(err);
      }

      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $newToken';
      retryOptions.extra['retried'] = true;

      final response = await dio.fetch(retryOptions);
      return handler.resolve(response);
    } catch (_) {
      await storage.deleteAll();
      onTokenUpdate(null);
      return handler.next(err);
    }
  }
}

Dio createDio(FlutterSecureStorage storage, void Function(String?) onTokenUpdate) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(JwtRefreshInterceptor(
    storage: storage,
    dio: dio,
    onTokenUpdate: onTokenUpdate,
  ));

  return dio;
}
