import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/features/auth/auth_screens.dart';
import 'package:mazraa_driver/features/reference_journey/reference_catalog.dart';
import 'package:mazraa_driver/features/reference_journey/reference_screen.dart';

void main() {
  testWidgets('reference onboarding screen 01 renders', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: OnboardingScreen()),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('onboardingScreen')), findsOneWidget);
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

        // With no authenticated test session we deliberately do not override
        // or manufacture API data. The production screen must render the
        // session/server state honestly instead.
        if (spec.sources.isNotEmpty) {
          expect(find.text('الجلسة غير جاهزة'), findsOneWidget);
        }

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        imageCache.clear();
        imageCache.clearLiveImages();
      }
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
