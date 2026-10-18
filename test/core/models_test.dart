import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/core/utils/shipment_state_machine.dart';

void main() {
  group('API models', () {
    test('parses production auth response without a role field', () {
      final session = AuthSession.fromJson({
        'token': 'access',
        'refreshToken': 'refresh',
        'userId': 6,
        'email': 'driver@example.com',
        'role': null,
        'roles': null,
      });

      expect(session.isUsable, isTrue);
      expect(session.userId, 6);
      expect(session.role, isEmpty);
      expect(session.roles, isEmpty);
    });

    test('parses shipment enum from numeric and string payloads', () {
      expect(parseShipmentStatus(4), ShipmentStatus.assigned);
      expect(parseShipmentStatus('NearCustomer'), ShipmentStatus.nearCustomer);
      expect(parseShipmentStatus('picked_up'), ShipmentStatus.pickedUp);
      expect(parseShipmentStatus('not-a-status'), ShipmentStatus.unknown);
    });

    test('uses delivery timestamp from API and never assumes creation is delivery', () {
      final completed = Shipment.fromJson({
        'id': 13,
        'shipmentNumber': 'SHP-13',
        'status': 'Delivered',
        'createdAt': '2026-10-17T22:00:00Z',
        'deliveredAt': '2026-10-18T02:30:00Z',
      });
      final missing = Shipment.fromJson({
        'id': 14,
        'shipmentNumber': 'SHP-14',
        'status': 'Delivered',
        'createdAt': '2026-10-18T02:00:00Z',
      });
      expect(completed.deliveredAt, DateTime.utc(2026, 10, 18, 2, 30));
      expect(missing.deliveredAt, isNull);
    });

    test('parses tracking wrapper and coordinates', () {
      final shipment = Shipment.fromJson({
        'shipment': {
          'id': 42,
          'shipmentNumber': 'SHP-42',
          'salesOrderId': 18,
          'status': 'InTransit',
          'storeLatitude': 24.7,
          'storeLongitude': 46.6,
          'customerLatitude': 24.8,
          'customerLongitude': 46.7,
        },
        'driverLocation': {'latitude': 24.75, 'longitude': 46.65},
        'distanceKm': 8.4,
        'etaMinutes': 17,
      });

      expect(shipment.id, 42);
      expect(shipment.status, ShipmentStatus.inTransit);
      expect(shipment.storeLocation?.latitude, 24.7);
      expect(shipment.driverLocation?.longitude, 46.65);
      expect(shipment.etaMinutes, 17);
    });
  });

  group('shipment state machine', () {
    test('matches accepted pickup flow', () {
      expect(
        ShipmentStateMachine.canTransition(
          ShipmentStatus.assigned,
          ShipmentStatus.accepted,
        ),
        isTrue,
      );
      expect(
        ShipmentStateMachine.canTransition(
          ShipmentStatus.accepted,
          ShipmentStatus.pickedUp,
        ),
        isTrue,
      );
    });

    test('documents required but unreachable in-transit step', () {
      expect(
        ShipmentStateMachine.canTransition(
          ShipmentStatus.pickedUp,
          ShipmentStatus.nearCustomer,
        ),
        isFalse,
      );
      expect(
        ShipmentStateMachine.canTransition(
          ShipmentStatus.pickedUp,
          ShipmentStatus.inTransit,
        ),
        isTrue,
      );
    });

    test('closed shipment cannot transition', () {
      expect(
        ShipmentStateMachine.canTransition(
          ShipmentStatus.delivered,
          ShipmentStatus.failed,
        ),
        isFalse,
      );
    });
  });
}
