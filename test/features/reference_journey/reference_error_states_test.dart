import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/core/network/api_client.dart';
import 'package:mazraa_driver/core/network/driver_api.dart';
import 'package:mazraa_driver/core/storage/secure_session_store.dart';
import 'package:mazraa_driver/features/auth/auth_controller.dart';
import 'package:mazraa_driver/features/reference_journey/reference_repository.dart';
import 'package:mazraa_driver/features/reference_journey/reference_screen.dart';
import 'package:mazraa_driver/shared/widgets/mazraa_widgets.dart';

void main() {
  testWidgets('a failed reference data request never renders a blank screen',
      (tester) async {
    final store = SecureSessionStore();
    final auth = AuthController(DriverApi(ApiClient(store), store), store)
      ..state = AuthState.authenticated
      ..profile = const DriverProfile(
        userId: 81, name: 'Known driver', email: 'driver@example.invalid',
        phone: '+967777000000', vehicleType: 'Van',
        approvalStatus: 'Approved', operationalStatus: 'Online',
        isAcceptingOrders: true, isVerified: true,
        ratingAverage: 4, ratingCount: 10,
      );
    var fetchCount = 0;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authControllerProvider.overrideWith((ref) => auth),
        referenceScreenPayloadProvider(const ReferenceLoadKey(12, 81))
            .overrideWith((ref) async {
          fetchCount++;
          throw StateError('test outage');
        }),
      ],
      child: const MaterialApp(locale: Locale('ar'), home: ReferenceJourneyScreen(screenNumber: 12)),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorState), findsOneWidget);
    expect(find.textContaining('test outage'), findsOneWidget);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(fetchCount, greaterThanOrEqualTo(2));
    expect(find.byType(ErrorState), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
