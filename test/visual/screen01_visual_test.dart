import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mazraa_driver/features/auth/auth_screens.dart';

void main() {
  testWidgets('screen 01 paints only the canonical reference visual plus transparent hit targets', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: OnboardingScreen())),
    );
    await tester.pump();

    final image = tester.widget<Image>(find.byType(Image));
    final provider = image.image as AssetImage;
    expect(provider.assetName, 'refrinces/screens/01_onboarding.png');
    expect(image.fit, BoxFit.fill);
    expect(image.filterQuality, FilterQuality.none);

    expect(find.byKey(const Key('onboardingSkip')), findsOneWidget);
    expect(find.byKey(const Key('onboardingStart')), findsOneWidget);
    expect(find.byKey(const Key('onboardingLogin')), findsOneWidget);
    expect(find.byType(Text), findsNothing);
    expect(find.byType(Icon), findsNothing);
    expect(find.byType(Container), findsNothing);
  });

  for (final targetKey in const [
    'onboardingSkip',
    'onboardingStart',
    'onboardingLogin',
  ]) {
    testWidgets('screen 01 $targetKey opens real login flow', (tester) async {
      final router = GoRouter(
        initialLocation: '/onboarding',
        routes: [
          GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
          GoRoute(
            path: '/login',
            builder: (_, __) => const Scaffold(
              body: SizedBox(key: Key('realLoginTarget')),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );
      await tester.pump();
      await tester.tap(find.byKey(Key(targetKey)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const Key('realLoginTarget')), findsOneWidget);
    });
  }
}
