import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/di.dart';
import 'core/router.dart';
import 'services/tracking_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await initializeBackgroundService();
  runApp(const ProviderScope(child: FitTrackBootstrap()));
}

class FitTrackBootstrap extends ConsumerStatefulWidget {
  const FitTrackBootstrap({super.key});

  @override
  ConsumerState<FitTrackBootstrap> createState() => _FitTrackBootstrapState();
}

class _FitTrackBootstrapState extends ConsumerState<FitTrackBootstrap> {
  @override
  void initState() {
    super.initState();
    _bootstrapAuth();
  }

  Future<void> _bootstrapAuth() async {
    final token = await ref.read(authServiceProvider).getToken();
    if (token != null) {
      ref.read(authTokenProvider.notifier).state = token;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const FitTrackApp();
  }
}

class FitTrackApp extends ConsumerWidget {
  const FitTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'FitTrack Pro',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
