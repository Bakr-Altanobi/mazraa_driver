import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/core/network/api_client.dart';
import 'package:mazraa_driver/features/reference_journey/reference_catalog.dart';
import 'package:mazraa_driver/features/reference_journey/reference_repository.dart';

class _NoNetworkApiClient implements ApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Network must not be called without an explicit target');
}

void main() {
  final repository = ReferenceRepository(_NoNetworkApiClient());

  test('reference offer acceptance rejects missing selection before network', () async {
    await expectLater(
      repository.runShipmentAction(ReferenceAction.acceptOffer),
      throwsStateError,
    );
    await expectLater(
      repository.runShipmentAction(ReferenceAction.rejectOffer),
      throwsStateError,
    );
  });

  test('every reference shipment mutation rejects a missing target', () async {
    for (final action in [
      ReferenceAction.acceptShipment,
      ReferenceAction.pickupShipment,
      ReferenceAction.startTransit,
      ReferenceAction.nearCustomer,
      ReferenceAction.deliverShipment,
      ReferenceAction.failShipment,
    ]) {
      await expectLater(repository.runShipmentAction(action), throwsStateError);
    }
  });

  test('shipment eligibility is checked for each exact row, not any other row', () {
    final rows = <Map<String, dynamic>>[
      {'id': 101, 'status': 'Assigned'},
      {'id': 102, 'status': 'PickedUp'},
    ];
    expect(
      selectShipmentIdForAction([rows.first], ReferenceAction.startTransit),
      isNull,
    );
    expect(
      selectShipmentIdForAction([rows.last], ReferenceAction.startTransit),
      102,
    );
  });
}
