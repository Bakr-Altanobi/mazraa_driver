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

    test('leaves splash for login when no session exists', () {
      expect(
        resolveAuthRedirect(
          authState: AuthState.signedOut,
          location: '/splash',
        ),
        '/login',
      );
    });

    test('moves authenticated drivers from splash to home', () {
      expect(
        resolveAuthRedirect(
          authState: AuthState.authenticated,
          location: '/splash',
        ),
        '/home',
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
