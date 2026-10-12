import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mazraa_driver/features/auth/auth_controller.dart';
import 'package:mazraa_driver/features/auth/auth_screens.dart';
import 'package:mazraa_driver/features/home/home_screen.dart';
import 'package:mazraa_driver/features/notifications/notifications_screen.dart';
import 'package:mazraa_driver/features/profile/profile_screen.dart';
import 'package:mazraa_driver/features/shell/app_shell.dart';
import 'package:mazraa_driver/features/shipments/shipment_screens.dart';
import 'package:mazraa_driver/features/wallet/wallet_screen.dart';

String? resolveAuthRedirect({
  required AuthState authState,
  required String location,
}) {
  final isPublic =
      location == '/login' ||
      location == '/splash' ||
      location == '/onboarding';

  if (authState == AuthState.initial || authState == AuthState.restoring) {
    return location == '/splash' ? null : '/splash';
  }

  if (authState != AuthState.authenticated) {
    // The splash screen is only a temporary restoration route. Once session
    // restoration finishes without an authenticated driver, always leave it.
    if (location == '/splash') return '/login';
    return isPublic ? null : '/login';
  }

  return isPublic ? '/home' : null;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.read(authControllerProvider);
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: auth,
    redirect: (context, state) {
      return resolveAuthRedirect(
        authState: auth.state,
        location: state.matchedLocation,
      );
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/shipments',
                builder: (_, _) => const ShipmentsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/wallet', builder: (_, _) => const WalletScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notifications',
                builder: (_, _) => const NotificationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/shipments/:id',
        builder: (context, state) => ShipmentDetailsScreen(
          shipmentId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(path: '/support', builder: (_, _) => const SupportScreen()),
    ],
  );
});
