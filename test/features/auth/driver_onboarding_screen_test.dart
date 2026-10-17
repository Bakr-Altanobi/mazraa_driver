import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mazraa_driver/features/auth/driver_onboarding_screen.dart';

void main() {
  GoRouter createRouter() => GoRouter(
        initialLocation: '/onboarding',
        routes: [
          GoRoute(
            path: '/onboarding',
            builder: (_, _) => const DriverOnboardingScreen(),
          ),
          GoRoute(
            path: '/register-driver',
            builder: (_, _) => const Scaffold(
              body: Center(child: Text('Real registration destination')),
            ),
          ),
          GoRoute(
            path: '/login',
            builder: (_, _) => const Scaffold(
              body: Center(child: Text('Real login destination')),
            ),
          ),
        ],
      );

  testWidgets('skip opens the real login route', (tester) async {
    final router = createRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.byKey(const Key('onboardingScreen')), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboardingSkipButton')));
    await tester.pumpAndSettle();
    expect(find.text('Real login destination'), findsOneWidget);
  });

  testWidgets('all three onboarding slides lead to login', (tester) async {
    final router = createRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    expect(find.byKey(const Key('onboardingTitle0')), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboardingNextButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('onboardingTitle1')), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboardingNextButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('onboardingTitle2')), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboardingNextButton')));
    await tester.pumpAndSettle();
    expect(find.text('Real login destination'), findsOneWidget);
  });
  testWidgets('new drivers can reach the registration path', (tester) async {
    final router = createRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.byKey(const Key('onboardingRegisterButton')));
    await tester.pumpAndSettle();
    expect(find.text('Real registration destination'), findsOneWidget);
  });

}
