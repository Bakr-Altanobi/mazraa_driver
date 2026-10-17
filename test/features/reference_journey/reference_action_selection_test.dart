import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/core/network/api_client.dart';
import 'package:mazraa_driver/features/reference_journey/reference_catalog.dart';
import 'package:mazraa_driver/features/reference_journey/reference_repository.dart';

class _NoNetworkApiClient implements ApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Network must not be called without an explicit target');
}

class _RecordingApiClient implements ApiClient {
  final posts = <(String, Object?)>[];

  @override
  Future<T> get<T>(String path, {Map<String, dynamic>? queryParameters}) async {
    if (path != 'api/Shipments') throw StateError('Unexpected GET: $path');
    return <dynamic>[
      {'id': 31, 'status': 'NearCustomer', 'shipmentNumber': 'SHIP-31'},
      {'id': 55, 'status': 'Assigned', 'shipmentNumber': 'SHIP-55'},
    ] as T;
  }

  @override
  Future<T> post<T>(String path, {Object? data}) async {
    posts.add((path, data));
    return null as T;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected client operation');
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

  test('reference delivery forwards exact selected shipment and recipient proof', () async {
    final client = _RecordingApiClient();
    final repository = ReferenceRepository(client);

    await repository.runShipmentAction(
      ReferenceAction.deliverShipment,
      shipmentId: 31,
      numericCode: ' 012345 ',
    );
    expect(client.posts, hasLength(1));
    expect(client.posts.single.$1, 'api/Shipments/31/deliver');
    expect(client.posts.single.$2, {
      'numericCode': '012345',
      'qrToken': null,
    });

    client.posts.clear();
    await repository.runShipmentAction(
      ReferenceAction.deliverShipment,
      shipmentId: 31,
      qrToken: '  qr-from-customer  ',
    );
    expect(client.posts.single.$1, 'api/Shipments/31/deliver');
    expect(client.posts.single.$2, {
      'numericCode': null,
      'qrToken': 'qr-from-customer',
    });
  });

  test('reference delivery never mutates a non-eligible shipment', () async {
    final client = _RecordingApiClient();
    final repository = ReferenceRepository(client);

    await expectLater(
      repository.runShipmentAction(
        ReferenceAction.deliverShipment,
        shipmentId: 55,
        numericCode: '123456',
      ),
      throwsStateError,
    );
    expect(client.posts, isEmpty);
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
