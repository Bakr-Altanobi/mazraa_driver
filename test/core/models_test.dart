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

    test('maps driver status and vehicle enums exactly as backend defines them', () {
      Map<String, dynamic> profile(int approval, int operational, int vehicle) => {
        'userId': 15,
        'name': 'Courier',
        'email': 'driver@example.com',
        'phone': '777777777',
        'approvalStatus': approval,
        'operationalStatus': operational,
        'vehicleType': vehicle,
        'isAcceptingOrders': true,
      };
      final available = DriverProfile.fromJson(profile(2, 3, 0));
      expect(available.approvalStatus, 'Approved');
      expect(available.isApproved, isTrue);
      expect(available.operationalStatus, 'Available');
      expect(available.vehicleType, 'Car');
      final suspended = DriverProfile.fromJson(profile(4, 4, 1));
      expect(suspended.approvalStatus, 'Suspended');
      expect(suspended.isApproved, isFalse);
      expect(suspended.operationalStatus, 'Busy');
      expect(suspended.vehicleType, 'Bike');
      final offline = DriverProfile.fromJson(profile(1, 1, 2));
      expect(offline.approvalStatus, 'Pending');
      expect(offline.operationalStatus, 'Offline');
      expect(offline.vehicleType, 'Van');
    });
    test('parses shipment enum from numeric and string payloads', () {
      expect(parseShipmentStatus(4), ShipmentStatus.assigned);
      expect(parseShipmentStatus('NearCustomer'), ShipmentStatus.nearCustomer);
      expect(parseShipmentStatus('picked_up'), ShipmentStatus.pickedUp);
      expect(parseShipmentStatus('not-a-status'), ShipmentStatus.unknown);
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
