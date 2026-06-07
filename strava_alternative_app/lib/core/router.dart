import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/feed/feed_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/segments/segments_screen.dart';
import '../features/tracking/save_activity_screen.dart';
import '../features/tracking/tracking_screen.dart';
import 'di.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authToken = ref.watch(authTokenProvider);

  return GoRouter(
    initialLocation: authToken != null ? '/feed' : '/login',
    redirect: (context, state) {
      final loggedIn = ref.read(authTokenProvider) != null;
      final onAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!loggedIn && !onAuth) return '/login';
      if (loggedIn && onAuth) return '/feed';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/feed', builder: (_, __) => const FeedScreen()),
          GoRoute(path: '/track', builder: (_, __) => const TrackingScreen()),
          GoRoute(
            path: '/save-activity',
            builder: (_, __) => const SaveActivityScreen(),
          ),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(path: '/segments', builder: (_, __) => const SegmentsScreen()),
        ],
      ),
    ],
  );
});

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    int index = 0;
    if (location.startsWith('/track') || location.startsWith('/save-activity')) {
      index = 1;
    } else if (location.startsWith('/profile')) {
      index = 2;
    } else if (location.startsWith('/segments')) {
      index = 3;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/feed');
            case 1:
              context.go('/track');
            case 2:
              context.go('/profile');
            case 3:
              context.go('/segments');
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Feed'),
          NavigationDestination(icon: Icon(Icons.directions_run), label: 'Track'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
          NavigationDestination(icon: Icon(Icons.route), label: 'Segments'),
        ],
      ),
    );
  }
}
