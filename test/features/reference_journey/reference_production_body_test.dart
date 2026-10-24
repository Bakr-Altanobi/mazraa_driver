import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazraa_driver/features/operations/driver_live_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/features/reference_journey/reference_catalog.dart';
import 'package:mazraa_driver/features/reference_journey/reference_production_body.dart';
import 'package:mazraa_driver/features/reference_journey/reference_repository.dart';

void main() {
  testWidgets(
    'all 48 production journey bodies render their real UI contracts',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final spec in ReferenceCatalog.screens) {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              driverJourneyProvider.overrideWith((ref) async => const {}),
              driverOffersProvider.overrideWith((ref) async => const []),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: ReferenceProductionBody(
                  spec: spec,
                  payload: const ReferenceScreenPayload(results: []),
                  loading: false,
                  sessionReady: true,
                  actionBusy: false,
                  onAction: (_) {},
                  onPrevious: spec.number == 1 ? null : () {},
                  onNext: spec.number == 48 ? null : () {},
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(
          find.byKey(Key('referenceScreenContent${spec.number}')),
          findsOneWidget,
          reason: 'screen ${spec.number} did not build its production body',
        );
        expect(
          find.text(spec.titleAr),
          findsWidgets,
          reason: 'screen ${spec.number} did not expose its reference title',
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'screen ${spec.number} emitted a render exception',
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
