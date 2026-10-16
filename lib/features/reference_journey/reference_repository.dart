import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazraa_driver/core/network/api_client.dart';
import 'package:mazraa_driver/core/network/providers.dart';
import 'package:mazraa_driver/features/reference_journey/reference_catalog.dart';

class ReferenceSourceResult {
  const ReferenceSourceResult({
    required this.source,
    required this.endpoint,
    this.payload,
    this.error,
    this.emptyMessage,
  });

  final ReferenceDataSource source;
  final String endpoint;
  final Object? payload;
  final String? error;
  final String? emptyMessage;

  bool get succeeded => error == null;
}

class ReferenceScreenPayload {
  const ReferenceScreenPayload({required this.results});

  final List<ReferenceSourceResult> results;
}

class ReferenceLoadKey {
  const ReferenceLoadKey(this.screenNumber, this.userId);

  final int screenNumber;
  final int userId;

  @override
  bool operator ==(Object other) =>
      other is ReferenceLoadKey &&
      other.screenNumber == screenNumber &&
      other.userId == userId;

  @override
  int get hashCode => Object.hash(screenNumber, userId);
}

int? selectShipmentIdForAction(
  Iterable<dynamic> rows,
  ReferenceAction action,
) {
  final allowed = switch (action) {
    ReferenceAction.pickupShipment => const {'5', 'accepted'},
    ReferenceAction.deliverShipment => const {'7', 'nearcustomer'},
    ReferenceAction.failShipment => const {'1', '6', '7', 'intransit', 'pickedup', 'nearcustomer'},
    ReferenceAction.createIncident => const <String>{},
  };
  for (final row in rows) {
    if (row is! Map || row['id'] == null) continue;
    final status = row['status']?.toString().replaceAll('_', '').replaceAll(' ', '').toLowerCase();
    if (status != null && allowed.contains(status)) {
      return int.tryParse(row['id'].toString());
    }
  }
  return null;
}

class ReferenceRepository {
  const ReferenceRepository(this._client);

  final ApiClient _client;

  Future<ReferenceScreenPayload> load(
    ReferenceScreenSpec spec,
    int userId,
  ) async {
    List<dynamic>? shipmentsCache;

    Future<List<dynamic>> shipments() async {
      return shipmentsCache ??=
          await _client.get<List<dynamic>>('api/Shipments');
    }

    Future<int?> preferredShipmentId() async {
      final rows = await shipments();
      for (final action in spec.actions) {
        if (action == ReferenceAction.createIncident) continue;
        final eligible = selectShipmentIdForAction(rows, action);
        if (eligible != null) return eligible;
      }
      for (final row in rows) {
        if (row is Map && row['id'] != null) {
          return int.tryParse(row['id'].toString());
        }
      }
      return null;
    }

    Future<ReferenceSourceResult> loadOne(ReferenceDataSource source) async {
      String endpoint = _endpointFor(source, userId);
      try {
        Object? payload;
        String? emptyMessage;
        switch (source) {
          case ReferenceDataSource.driver:
            payload = await _client.get<dynamic>(endpoint);
          case ReferenceDataSource.shipments:
            payload = await shipments();
          case ReferenceDataSource.shipmentDetail:
            final id = await preferredShipmentId();
            if (id == null) {
              emptyMessage = 'لا توجد شحنة فعلية في حساب السائق لعرض تفاصيلها.';
              endpoint = 'api/Shipments/{shipmentId}';
            } else {
              endpoint = 'api/Shipments/$id';
              payload = await _client.get<dynamic>(endpoint);
            }
          case ReferenceDataSource.tracking:
            final id = await preferredShipmentId();
            if (id == null) {
              emptyMessage = 'لا توجد شحنة فعلية في حساب السائق لبدء التتبع.';
              endpoint = 'api/Shipments/{shipmentId}/tracking';
            } else {
              endpoint = 'api/Shipments/$id/tracking';
              payload = await _client.get<dynamic>(endpoint);
            }
          case ReferenceDataSource.wallet:
            payload = await _client.get<dynamic>(endpoint);
          case ReferenceDataSource.walletTransactions:
            payload = await _client.get<dynamic>(
              endpoint,
              queryParameters: const {'page': 1, 'perPage': 50},
            );
          case ReferenceDataSource.notifications:
            payload = await _client.get<dynamic>(
              endpoint,
              queryParameters: const {'page': 1, 'pageSize': 50},
            );
          case ReferenceDataSource.vehicle:
            payload = await _client.get<dynamic>(endpoint);
          case ReferenceDataSource.supportFaqs:
            payload = await _client.get<dynamic>(endpoint);
          case ReferenceDataSource.supportTickets:
            payload = await _client.get<dynamic>(endpoint);
          case ReferenceDataSource.chats:
            payload = await _client.get<dynamic>(endpoint);
          case ReferenceDataSource.deliveryZones:
            payload = await _client.get<dynamic>(endpoint);
        }
        return ReferenceSourceResult(
          source: source,
          endpoint: endpoint,
          payload: payload,
          emptyMessage: emptyMessage,
        );
      } catch (error) {
        return ReferenceSourceResult(
          source: source,
          endpoint: endpoint,
          error: error.toString(),
        );
      }
    }

    final results = <ReferenceSourceResult>[];
    for (final source in spec.sources) {
      results.add(await loadOne(source));
    }
    return ReferenceScreenPayload(results: results);
  }

  Future<void> runShipmentAction(
    ReferenceAction action, {
    String? reason,
  }) async {
    final rows = await _client.get<List<dynamic>>('api/Shipments');
    final shipmentId = selectShipmentIdForAction(rows, action);
    if (shipmentId == null) {
      throw StateError(
        'لا توجد شحنة فعلية في حالة تسمح بتنفيذ هذه العملية حسب قواعد السيرفر.',
      );
    }
    final actionName = switch (action) {
      ReferenceAction.pickupShipment => 'pickup',
      ReferenceAction.deliverShipment => 'deliver',
      ReferenceAction.failShipment => 'fail',
      ReferenceAction.createIncident => throw ArgumentError.value(action),
    };
    await _client.post<dynamic>(
      'api/Shipments/$shipmentId/$actionName',
      data: action == ReferenceAction.failShipment
          ? {'reason': reason?.trim().isEmpty ?? true ? 'تعذر الوصول للعميل' : reason!.trim()}
          : null,
    );
  }

  Future<void> createIncident({
    required String subject,
    required String message,
  }) async {
    await _client.post<dynamic>(
      'api/support/complaints',
      data: {
        'subject': subject.trim(),
        'message': message.trim(),
        'priority': 'high',
      },
    );
  }

  static String _endpointFor(ReferenceDataSource source, int userId) {
    return switch (source) {
      ReferenceDataSource.driver => 'api/Drivers/$userId',
      ReferenceDataSource.shipments => 'api/Shipments',
      ReferenceDataSource.shipmentDetail => 'api/Shipments/{shipmentId}',
      ReferenceDataSource.tracking => 'api/Shipments/{shipmentId}/tracking',
      ReferenceDataSource.wallet => 'api/wallets/me',
      ReferenceDataSource.walletTransactions => 'api/wallets/transactions',
      ReferenceDataSource.notifications => 'api/notifications',
      ReferenceDataSource.vehicle => 'api/Vehicles/my-current',
      ReferenceDataSource.supportFaqs => 'api/support/faqs',
      ReferenceDataSource.supportTickets => 'api/support/tickets',
      ReferenceDataSource.chats => 'api/chats',
      ReferenceDataSource.deliveryZones => 'api/DeliveryZones',
    };
  }
}

final referenceRepositoryProvider = Provider<ReferenceRepository>(
  (ref) => ReferenceRepository(ref.watch(apiClientProvider)),
);

final referenceScreenPayloadProvider =
    FutureProvider.family<ReferenceScreenPayload, ReferenceLoadKey>((ref, key) {
  final spec = ReferenceCatalog.screen(key.screenNumber);
  return ref.watch(referenceRepositoryProvider).load(spec, key.userId);
});
