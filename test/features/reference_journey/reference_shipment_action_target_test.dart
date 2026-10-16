import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/features/reference_journey/reference_catalog.dart';
import 'package:mazraa_driver/features/reference_journey/reference_repository.dart';

void main() {
  const rows = <Map<String, Object>>[
    {'id': 10, 'status': 'Pending'},
    {'id': 11, 'status': 'Accepted'},
    {'id': 12, 'status': 6},
    {'id': 13, 'status': 'InTransit'},
    {'id': 14, 'status': 7},
    {'id': 15, 'status': 'Delivered'},
  ];

  test('pickup targets only an Accepted shipment', () {
    expect(selectShipmentIdForAction(rows, ReferenceAction.pickupShipment), 11);
  });

  test('deliver targets only a NearCustomer shipment', () {
    expect(selectShipmentIdForAction(rows, ReferenceAction.deliverShipment), 14);
  });

  test('fail targets only a state accepted by the server state machine', () {
    expect(selectShipmentIdForAction(rows, ReferenceAction.failShipment), 12);
  });

  test('action never falls back to an unrelated first shipment', () {
    const unrelated = <Map<String, Object>>[
      {'id': 20, 'status': 'Pending'},
      {'id': 21, 'status': 'Delivered'},
    ];
    expect(
      selectShipmentIdForAction(unrelated, ReferenceAction.pickupShipment),
      isNull,
    );
    expect(
      selectShipmentIdForAction(unrelated, ReferenceAction.deliverShipment),
      isNull,
    );
    expect(
      selectShipmentIdForAction(unrelated, ReferenceAction.failShipment),
      isNull,
    );
  });
}
