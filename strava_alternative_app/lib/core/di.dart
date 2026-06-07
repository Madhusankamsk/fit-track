import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

final authTokenProvider = StateProvider<String?>((_) => null);

final dioProvider = Provider<Dio>((ref) {
  return createDio(
    ref.watch(secureStorageProvider),
    (token) => ref.read(authTokenProvider.notifier).state = token,
  );
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(dioProvider),
    ref.watch(secureStorageProvider),
  );
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    ref.watch(dioProvider),
    ref.watch(secureStorageProvider),
  );
});
