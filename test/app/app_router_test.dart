import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/app/app_router.dart';
import 'package:mazraa_driver/features/auth/auth_controller.dart';

void main() {
  group('resolveAuthRedirect', () {
    test('keeps splash while restoring the session', () {
      expect(
        resolveAuthRedirect(
          authState: AuthState.restoring,
          location: '/splash',
        ),
        isNull,
      );
    });

    test('keeps restored sessions on splash while home data preloads', () {
      expect(
        resolveAuthRedirect(
          authState: AuthState.preparingHome,
          location: '/splash',
        ),
        isNull,
      );
    });

    test('keeps login mounted while post-login home data preloads', () {
      expect(
        resolveAuthRedirect(
          authState: AuthState.preparingHome,
          location: '/login',
        ),
        isNull,
      );
    });

    test('moves bootstrap failures to retry UI on splash', () {
      expect(
        resolveAuthRedirect(
          authState: AuthState.bootstrapFailed,
          location: '/login',
        ),
        '/splash',
      );
      expect(
        resolveAuthRedirect(
          authState: AuthState.bootstrapFailed,
          location: '/splash',
        ),
        isNull,
      );
    });

    test('fresh signed-out sessions start at reference onboarding', () {
      expect(
        resolveAuthRedirect(
          authState: AuthState.signedOut,
          location: '/splash',
        ),
        '/onboarding',
      );
    });

    test('authenticated drivers continue at reference screen 03', () {
      expect(
        resolveAuthRedirect(
          authState: AuthState.authenticated,
          location: '/splash',
        ),
        '/journey/03',
      );
      expect(
        resolveAuthRedirect(
          authState: AuthState.authenticated,
          location: '/login',
        ),
        '/journey/03',
      );
    });

    test('protects private pages for signed-out drivers', () {
      expect(
        resolveAuthRedirect(
          authState: AuthState.signedOut,
          location: '/shipments',
        ),
        '/login',
      );
    });
  });
}
