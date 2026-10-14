import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/features/auth/auth_screens.dart';
import 'package:mazraa_driver/features/reference_journey/reference_catalog.dart';
import 'package:mazraa_driver/features/reference_journey/reference_screen.dart';

void main() {
  testWidgets('reference onboarding screen 01 renders on compact viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: OnboardingScreen()),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('onboardingScreen')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reference login screen 02 renders without network data', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('loginScreen')), findsOneWidget);
    expect(find.byKey(const Key('emailField')), findsOneWidget);
    expect(find.byKey(const Key('passwordField')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'authenticated reference screens 03 through 48 all build without fake server payloads',
    (tester) async {
      for (final spec in ReferenceCatalog.screens.where(
        (screen) => screen.number >= 3,
      )) {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: ReferenceJourneyScreen(screenNumber: spec.number),
            ),
          ),
        );
        await tester.pump();

        expect(
          find.byKey(Key('referenceScreen${spec.number}')),
          findsOneWidget,
          reason: 'screen ${spec.number} failed to render',
        );
        expect(find.text(spec.titleAr), findsWidgets);
        expect(
          tester.takeException(),
          isNull,
          reason: 'screen ${spec.number} emitted a render/layout exception',
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        imageCache.clear();
        imageCache.clearLiveImages();
      }
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
