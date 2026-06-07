import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';
import '../models/user.dart';

class AuthService {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthService(this._dio, this._storage);

  Future<User> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final res = await _dio.post('/api/v1/auth/register', data: {
      'username': username,
      'email': email,
      'password': password,
    });
    await _saveTokens(res.data);
    return User.fromJson(res.data['user'] as Map<String, dynamic>);
  }

  Future<User> login({required String email, required String password}) async {
    final res = await _dio.post('/api/v1/auth/login', data: {
      'email': email,
      'password': password,
    });
    await _saveTokens(res.data);
    return User.fromJson(res.data['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<String?> getToken() => _storage.read(key: 'auth_token');

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  Future<void> _saveTokens(Map<String, dynamic> data) async {
    await _storage.write(key: 'auth_token', value: data['token'] as String);
    if (data['refreshToken'] != null) {
      await _storage.write(
        key: 'refresh_token',
        value: data['refreshToken'] as String,
      );
    }
  }
}
