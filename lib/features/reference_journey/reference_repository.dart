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

String _normalizedStatus(dynamic value) => value
    ?.toString()
    .replaceAll('_', '')
    .replaceAll(' ', '')
    .toLowerCase() ?? '';

int? selectShipmentIdForAction(
  Iterable<dynamic> rows,
  ReferenceAction action,
) {
  final allowed = switch (action) {
    ReferenceAction.acceptShipment => const {'4', 'assigned'},
    ReferenceAction.pickupShipment => const {'5', 'accepted'},
    ReferenceAction.startTransit => const {'6', 'pickedup'},
    ReferenceAction.nearCustomer => const {'1', 'intransit'},
    ReferenceAction.deliverShipment => const {'7', 'nearcustomer'},
    ReferenceAction.failShipment => const {
        '1',
        '6',
        '7',
        'intransit',
        'pickedup',
        'nearcustomer',
      },
    ReferenceAction.startShift ||
    ReferenceAction.endShift ||
    ReferenceAction.acceptOffer ||
    ReferenceAction.rejectOffer ||
    ReferenceAction.createIncident => const <String>{},
  };
  for (final row in rows) {
    if (row is! Map || row['id'] == null) continue;
    if (allowed.contains(_normalizedStatus(row['status']))) {
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
          case ReferenceDataSource.journeyMe:
          case ReferenceDataSource.preferences:
          case ReferenceDataSource.availability:
          case ReferenceDataSource.offers:
          case ReferenceDataSource.scheduledTrips:
          case ReferenceDataSource.currentTrips:
          case ReferenceDataSource.shifts:
          case ReferenceDataSource.documents:
          case ReferenceDataSource.vehicleMaintenance:
          case ReferenceDataSource.bankAccounts:
          case ReferenceDataSource.payouts:
          case ReferenceDataSource.incentives:
          case ReferenceDataSource.referral:
          case ReferenceDataSource.incidents:
          case ReferenceDataSource.returns:
          case ReferenceDataSource.performance:
          case ReferenceDataSource.wallet:
          case ReferenceDataSource.vehicle:
          case ReferenceDataSource.supportFaqs:
          case ReferenceDataSource.supportTickets:
          case ReferenceDataSource.chats:
          case ReferenceDataSource.deliveryZones:
            payload = await _client.get<dynamic>(endpoint);
          case ReferenceDataSource.shipments:
            payload = await shipments();
          case ReferenceDataSource.shipmentDetail:
          case ReferenceDataSource.tracking:
          case ReferenceDataSource.shipmentProofs:
            final id = await preferredShipmentId();
            if (id == null) {
              emptyMessage = switch (source) {
                ReferenceDataSource.tracking =>
                  'لا توجد شحنة فعلية في حساب السائق لبدء التتبع.',
                ReferenceDataSource.shipmentProofs =>
                  'لا توجد شحنة فعلية في حساب السائق لعرض إثباتاتها.',
                _ => 'لا توجد شحنة فعلية في حساب السائق لعرض تفاصيلها.',
              };
              endpoint = switch (source) {
                ReferenceDataSource.tracking =>
                  'api/Shipments/{shipmentId}/tracking',
                ReferenceDataSource.shipmentProofs =>
                  'api/Shipments/{shipmentId}/proofs',
                _ => 'api/Shipments/{shipmentId}',
              };
            } else {
              endpoint = switch (source) {
                ReferenceDataSource.tracking => 'api/Shipments/$id/tracking',
                ReferenceDataSource.shipmentProofs =>
                  'api/Shipments/$id/proofs',
                _ => 'api/Shipments/$id',
              };
              payload = await _client.get<dynamic>(endpoint);
            }
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

  /// A reference action must have a user-selected, server-issued target. Never
  /// silently mutate the first eligible order or offer in an account.
  Future<List<Map<String, dynamic>>> eligibleActionTargets(
    ReferenceAction action,
  ) async {
    if (action == ReferenceAction.acceptOffer ||
        action == ReferenceAction.rejectOffer) {
      final rows = await _client.get<List<dynamic>>('api/driver-journey/offers');
      return rows.whereType<Map<String, dynamic>>().where((row) {
        final id = int.tryParse('${row['offerId'] ?? row['id'] ?? ''}');
        final expiry = DateTime.tryParse('${row['expiresAt'] ?? ''}');
        return id != null && expiry != null && expiry.isAfter(DateTime.now());
      }).toList(growable: false);
    }
    final rows = await _client.get<List<dynamic>>('api/Shipments');
    return rows.whereType<Map<String, dynamic>>().where(
      (row) => selectShipmentIdForAction([row], action) != null,
    ).toList(growable: false);
  }

  Future<void> runShipmentAction(
    ReferenceAction action, {
    String? reason,
    int? shipmentId,
    int? offerId,
    String? numericCode,
    String? qrToken,
  }) async {
    if (action == ReferenceAction.startShift) {
      await _client.post<dynamic>(
        'api/driver-journey/shifts/start',
        data: const {'latitude': null, 'longitude': null},
      );
      return;
    }
    if (action == ReferenceAction.endShift) {
      await _client.post<dynamic>(
        'api/driver-journey/shifts/end',
        data: const {'latitude': null, 'longitude': null},
      );
      return;
    }
    if (action == ReferenceAction.acceptOffer ||
        action == ReferenceAction.rejectOffer) {
      if (offerId == null || offerId <= 0) {
        throw StateError('اختر عرض توصيل حقيقيًا قبل إرسال هذا القرار.');
      }
      final eligible = await eligibleActionTargets(action);
      if (!eligible.any(
        (row) => int.tryParse('${row['offerId'] ?? row['id']}') == offerId,
      )) {
        throw StateError('العرض المحدد لم يعد متاحًا على السيرفر.');
      }
      final verb = action == ReferenceAction.acceptOffer ? 'accept' : 'reject';
      await _client.post<dynamic>(
        'api/driver-journey/offers/$offerId/$verb',
      );
      return;
    }
    if (action == ReferenceAction.createIncident) {
      throw ArgumentError.value(action);
    }
    if (shipmentId == null || shipmentId <= 0) {
      throw StateError('اختر الشحنة المقصودة قبل تغيير حالتها.');
    }
    final rows = await eligibleActionTargets(action);
    if (!rows.any(
      (row) => int.tryParse('${row['id']}') == shipmentId,
    )) {
      throw StateError('حالة الشحنة المحددة لم تعد تسمح بتنفيذ العملية.');
    }
    final actionName = switch (action) {
      ReferenceAction.acceptShipment => 'accept',
      ReferenceAction.pickupShipment => 'pickup',
      ReferenceAction.startTransit => 'depart',
      ReferenceAction.nearCustomer => 'near-customer',
      ReferenceAction.deliverShipment => 'deliver',
      ReferenceAction.failShipment => 'fail',
      ReferenceAction.startShift ||
      ReferenceAction.endShift ||
      ReferenceAction.acceptOffer ||
      ReferenceAction.rejectOffer ||
      ReferenceAction.createIncident => throw ArgumentError.value(action),
    };
    await _client.post<dynamic>(
      'api/Shipments/$shipmentId/$actionName',
      data: action == ReferenceAction.failShipment
          ? {
              'reason': reason?.trim().isEmpty ?? true
                  ? 'تعذر الوصول للعميل'
                  : reason!.trim(),
            }
          : action == ReferenceAction.deliverShipment &&
                  ((numericCode?.trim().isNotEmpty ?? false) ||
                      (qrToken?.trim().isNotEmpty ?? false))
              ? {
                  'numericCode': numericCode?.trim().isEmpty == true
                      ? null
                      : numericCode?.trim(),
                  'qrToken': qrToken?.trim().isEmpty == true
                      ? null
                      : qrToken?.trim(),
                }
              : null,
    );
  }

  Future<void> createIncident({
    required String subject,
    required String message,
  }) async {
    // A general incident must not be falsely linked to the first shipment.
    // The server accepts ShipmentId=null for driver-wide reports.
    await _client.post<dynamic>(
      'api/driver-journey/incidents',
      data: {
        'category': 'driver-report',
        'title': subject.trim(),
        'description': message.trim(),
        'isEmergency': false,
      },
    );
  }

  static String _endpointFor(ReferenceDataSource source, int userId) {
    return switch (source) {
      ReferenceDataSource.driver => 'api/Drivers/$userId',
      ReferenceDataSource.journeyMe => 'api/driver-journey/me',
      ReferenceDataSource.preferences => 'api/driver-journey/me/preferences',
      ReferenceDataSource.availability => 'api/driver-journey/me/availability',
      ReferenceDataSource.offers => 'api/driver-journey/offers',
      ReferenceDataSource.scheduledTrips =>
        'api/driver-journey/scheduled-trips',
      ReferenceDataSource.currentTrips => 'api/driver-journey/trips/current',
      ReferenceDataSource.shifts => 'api/driver-journey/shifts',
      ReferenceDataSource.shipments => 'api/Shipments',
      ReferenceDataSource.shipmentDetail => 'api/Shipments/{shipmentId}',
      ReferenceDataSource.tracking => 'api/Shipments/{shipmentId}/tracking',
      ReferenceDataSource.shipmentProofs =>
        'api/Shipments/{shipmentId}/proofs',
      ReferenceDataSource.wallet => 'api/wallets/me',
      ReferenceDataSource.walletTransactions => 'api/wallets/transactions',
      ReferenceDataSource.notifications => 'api/notifications',
      ReferenceDataSource.vehicle => 'api/Vehicles/my-current',
      ReferenceDataSource.documents => 'api/driver-journey/documents',
      ReferenceDataSource.vehicleMaintenance =>
        'api/driver-journey/vehicle-maintenance',
      ReferenceDataSource.bankAccounts => 'api/driver-journey/bank-accounts',
      ReferenceDataSource.payouts => 'api/driver-journey/payouts',
      ReferenceDataSource.incentives => 'api/driver-journey/incentives',
      ReferenceDataSource.referral => 'api/driver-journey/referral',
      ReferenceDataSource.incidents => 'api/driver-journey/incidents',
      ReferenceDataSource.returns => 'api/driver-journey/returns',
      ReferenceDataSource.performance => 'api/driver-journey/performance',
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
