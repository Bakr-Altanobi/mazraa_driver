import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazraa_driver/app/app_settings.dart';
import 'package:go_router/go_router.dart';
import 'package:mazraa_driver/features/auth/auth_controller.dart';
import 'package:mazraa_driver/features/auth/auth_screens.dart';
import 'package:mazraa_driver/features/auth/driver_application_screen.dart';
import 'package:mazraa_driver/features/home/home_screen.dart';
import 'package:mazraa_driver/features/notifications/notifications_screen.dart';
import 'package:mazraa_driver/features/operations/driver_operations_widgets.dart';
import 'package:mazraa_driver/features/operations/driver_services_screen.dart';
import 'package:mazraa_driver/features/operations/driver_media_screens.dart';
import 'package:mazraa_driver/features/reference_journey/reference_screen.dart';
import 'package:mazraa_driver/features/profile/profile_screen.dart';
import 'package:mazraa_driver/features/shell/app_shell.dart';
import 'package:mazraa_driver/features/shipments/shipment_screens.dart';
import 'package:mazraa_driver/features/support/driver_support_screen.dart';
import 'package:mazraa_driver/features/wallet/wallet_screen.dart';
import 'package:mazraa_driver/features/wallet/driver_payout_screen.dart';

const _ciSmokeHome = bool.fromEnvironment(
  'CI_SMOKE_HOME',
  defaultValue: false,
);

String? resolveAuthRedirect({
  required AuthState authState,
  required String location,
  bool hasSeenOnboarding = false,
}) {
  final isPublic =
      location == '/login' ||
      location == '/splash' ||
      location == '/onboarding' ||
      location == '/apply';

  if (authState == AuthState.initial || authState == AuthState.restoring) {
    return location == '/splash' ? null : '/splash';
  }

  if (authState == AuthState.preparingHome) {
    if (location == '/splash' || location == '/login') return null;
    return '/splash';
  }

  if (authState == AuthState.bootstrapFailed) {
    return location == '/splash' ? null : '/splash';
  }

  if (authState != AuthState.authenticated) {
    if (location == '/splash') return hasSeenOnboarding ? '/login' : '/onboarding';
    return isPublic ? null : '/login';
  }

  return isPublic ? '/home' : null;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.read(authControllerProvider);
  final settings = ref.read(appSettingsProvider);
  return GoRouter(
    initialLocation: _ciSmokeHome ? '/home' : '/splash',
    refreshListenable: Listenable.merge([auth, settings]),
    redirect: (context, state) {
      if (_ciSmokeHome) {
        return state.matchedLocation == '/home' ? null : '/home';
      }
      return resolveAuthRedirect(
        authState: auth.state,
        location: state.matchedLocation,
        hasSeenOnboarding: settings.onboardingCompleted,
      );
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/apply', builder: (_, _) => const DriverApplicationScreen()),
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
      GoRoute(path: '/support', builder: (_, _) => const DriverSupportScreen()),
      GoRoute(
        path: '/chats/:id',
        builder: (context, state) => DriverChatScreen(
          chatId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(path: '/offers', builder: (_, _) => const DriverOffersScreen()),
      GoRoute(path: '/payouts', builder: (_, _) => const DriverPayoutScreen()),
      GoRoute(path: '/services', builder: (_, _) => const DriverServicesScreen()),
      GoRoute(path: '/upload-document', builder: (_, _) => const DriverDocumentUploadScreen()),
      GoRoute(
        path: '/shipments/:id/evidence',
        builder: (_, state) => DriverProofPhotoScreen(
          shipmentId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: '/journey/:number',
        builder: (_, state) {
          final number = int.tryParse(state.pathParameters['number'] ?? '');
          if (number == null || number < 1 || number > 48) {
            return const DriverServicesScreen();
          }
          return ReferenceJourneyScreen(screenNumber: number);
        },
      ),
    ],
  );
});
