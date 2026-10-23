import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/features/operations/driver_live_providers.dart';
import 'package:mazraa_driver/features/reference_journey/reference_catalog.dart';
import 'package:mazraa_driver/features/reference_journey/reference_production_body.dart';
import 'package:mazraa_driver/features/reference_journey/reference_repository.dart';
import 'package:mazraa_driver/core/theme/app_theme.dart';

const _driver = <String, dynamic>{
  'userId': 81,
  'name': 'Driver from API',
  'driverCode': 'DRV-81',
  'email': 'driver@example.invalid',
  'phone': '+967777000000',
  'approvalStatus': 2,
  'operationalStatus': 3,
  'isVerified': true,
  'isAcceptingOrders': true,
  'ratingAverage': 4.5,
  'ratingCount': 10,
};
const _shipment = <String, dynamic>{
  'id': 100, 'shipmentNumber': 'SHP-100',
  'salesOrderId': 200, 'customerId': 11, 'driverId': 81,
  'status': 5, 'pickupLatitude': 15.3694, 'pickupLongitude': 44.1910,
  'customerLatitude': 15.3547, 'customerLongitude': 44.2067,
  'deliveryFee': 150, 'currency': 'SAR',
};

Object sampleFor(ReferenceDataSource source) => switch (source) {
  ReferenceDataSource.driver => _driver,
  ReferenceDataSource.journeyMe => {'driver': _driver, 'vehicle': <String, dynamic>{}},
  ReferenceDataSource.shipmentDetail => _shipment,
  ReferenceDataSource.tracking => {
    'shipment': _shipment,
    'driverLocation': {'latitude': 15.365, 'longitude': 44.195},
    'distanceKm': 1.5, 'etaMinutes': 8,
  },
  ReferenceDataSource.wallet => {
    'balance': 100.0, 'currency': 'SAR', 'monthlyCredits': 20.0,
  },
  ReferenceDataSource.preferences => {
    'acceptScheduledTrips': true, 'acceptPrivateDeliveries': true,
  },
  ReferenceDataSource.referral => {
    'code': 'DRIVER-81', 'referrals': <dynamic>[],
  },
  ReferenceDataSource.performance => {
    'completedShipments': 5, 'averageRating': 4.5,
  },
  ReferenceDataSource.vehicle => {
    'id': 10, 'plateNumber': 'TEST-10', 'maxWeightKg': 1000,
  },
  _ => <dynamic>[],
};

void main() {
  for (final dark in [false, true]) {
    testWidgets('all 48 reference UIs with server-shaped data dark=$dark',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final spec in ReferenceCatalog.screens) {
        final data = ReferenceScreenPayload(results: [
          for (final source in spec.sources)
            ReferenceSourceResult(
              source: source,
              endpoint: 'test/${source.name}',
              payload: sampleFor(source),
            ),
        ]);
        await tester.pumpWidget(ProviderScope(
          overrides: [driverOffersProvider.overrideWith((ref) async => const [])],
          child: MaterialApp(
            theme: dark ? AppTheme.dark() : AppTheme.light(),
            home: Scaffold(body: ReferenceProductionBody(
              key: ValueKey(spec.number),
              spec: spec,
              payload: data,
              loading: false,
              sessionReady: true,
              actionBusy: false,
              onAction: (_) {},
              onPrevious: () {},
              onNext: () {},
            )),
          ),
        ));
        await tester.pump();
        expect(find.byKey(Key('referenceScreenContent${spec.number}')),
            findsOneWidget, reason: 'Missing reference screen ${spec.number}');
        expect(find.text(spec.titleAr), findsWidgets);
        expect(tester.takeException(), isNull,
            reason: 'Screen ${spec.number} must render loaded API-shaped data');
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        imageCache.clear();
        imageCache.clearLiveImages();
      }
    }, timeout: const Timeout(Duration(minutes: 5)));
  }
}
