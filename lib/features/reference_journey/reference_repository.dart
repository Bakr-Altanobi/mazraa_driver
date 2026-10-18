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

class ReferenceActionTarget {
  const ReferenceActionTarget({required this.id, required this.label});
  final int id;
  final String label;
}

/// A mutating operation must always identify the server record chosen by
/// the driver. In particular it must never silently use the first offer.
bool referenceActionNeedsTarget(ReferenceAction action) => switch (action) {
  ReferenceAction.acceptShipment ||
  ReferenceAction.pickupShipment ||
  ReferenceAction.startTransit ||
  ReferenceAction.nearCustomer ||
  ReferenceAction.deliverShipment ||
  ReferenceAction.failShipment ||
  ReferenceAction.acceptOffer ||
  ReferenceAction.rejectOffer ||
  ReferenceAction.joinScheduledTrip ||
  ReferenceAction.withdrawScheduledTrip ||
  ReferenceAction.acceptReturn ||
  ReferenceAction.pickupReturn ||
  ReferenceAction.completeReturn ||
  ReferenceAction.addPickupProof ||
  ReferenceAction.addDeliveryProof ||
  ReferenceAction.requestPayout ||
  ReferenceAction.removeAvailabilityWindow => true,
  _ => false,
};

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
    ReferenceAction.addPickupProof => const {'5', '6', 'accepted', 'pickedup'},
    ReferenceAction.addDeliveryProof => const {'7', 'nearcustomer'},
    ReferenceAction.startShift ||
    ReferenceAction.endShift ||
    ReferenceAction.acceptOffer ||
    ReferenceAction.rejectOffer ||
    ReferenceAction.createIncident ||
    ReferenceAction.goOnline ||
    ReferenceAction.goOffline ||
    ReferenceAction.joinScheduledTrip ||
    ReferenceAction.withdrawScheduledTrip ||
    ReferenceAction.acceptReturn ||
    ReferenceAction.pickupReturn ||
    ReferenceAction.completeReturn ||
    ReferenceAction.saveBankAccount ||
    ReferenceAction.requestPayout ||
    ReferenceAction.markAllNotificationsRead ||
    ReferenceAction.toggleOffersPreference ||
    ReferenceAction.toggleScheduledTripsPreference ||
    ReferenceAction.addAvailabilityWindow ||
    ReferenceAction.removeAvailabilityWindow => const <String>{},
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
    Future<List<dynamic>>? shipmentsFuture;

    Future<List<dynamic>> shipments() =>
        shipmentsFuture ??= _client.get<List<dynamic>>('api/Shipments');

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

    // Different endpoints load concurrently; failures remain isolated per
    // source and the shipment list is fetched at most once per screen load.
    final results = await Future.wait(
      spec.sources.map(loadOne),
    );
    return ReferenceScreenPayload(results: results);
  }

  /// Reads only the current driver's records. The server is authoritative
  /// for ownership, expiry and valid state transitions.
  Future<List<ReferenceActionTarget>> targetsForAction(
    ReferenceAction action,
  ) async {
    if (!referenceActionNeedsTarget(action)) return const [];
    if (action == ReferenceAction.removeAvailabilityWindow) {
      final rows = await _client.get<List<dynamic>>(
        'api/driver-journey/me/availability',
      );
      return [
        for (final row in rows)
          if (row is Map && int.tryParse('${row['id'] ?? ''}') != null)
            ReferenceActionTarget(
              id: int.parse('${row['id']}'),
              label: 'يوم ${row['dayOfWeek']} · ${row['startTime']} - ${row['endTime']}',
            ),
      ];
    }
    if (action == ReferenceAction.requestPayout) {
      final rows = await _client.get<List<dynamic>>('api/driver-journey/bank-accounts');
      return [
        for (final row in rows)
          if (row is Map && int.tryParse('${row['id'] ?? ''}') != null)
            ReferenceActionTarget(
              id: int.parse('${row['id']}'),
              label: 'حساب ${row['bankName'] ?? ''} · ${row['isVerified'] == true ? 'موثّق' : 'ينتظر التوثيق'}',
            ),
      ];
    }
    if (action == ReferenceAction.acceptOffer ||
        action == ReferenceAction.rejectOffer) {
      final rows = await _client.get<List<dynamic>>('api/driver-journey/offers');
      return [
        for (final row in rows)
          if (row is Map && int.tryParse('${row['offerId'] ?? ''}') != null)
            ReferenceActionTarget(
              id: int.parse('${row['offerId']}'),
              label: 'عرض ${row['shipmentNumber'] ?? row['shipmentId'] ?? row['offerId']} · ينتهي ${row['expiresAt'] ?? 'حسب السيرفر'}',
            ),
      ];
    }
    if (action == ReferenceAction.joinScheduledTrip ||
        action == ReferenceAction.withdrawScheduledTrip) {
      final rows = await _client.get<List<dynamic>>('api/driver-journey/scheduled-trips');
      return [
        for (final row in rows)
          if (row is Map && row['trip'] is Map)
            if (int.tryParse('${(row['trip'] as Map)['id'] ?? ''}') != null)
              if (action == ReferenceAction.joinScheduledTrip
                  ? (row['participation'] == null ||
                      {'3', 'withdrawn', '2', 'rejected'}.contains(
                        _normalizedStatus((row['participation'] as Map?)?['status']),
                      ))
                  : (row['participation'] is Map &&
                      !{'1', 'approved', '3', 'withdrawn'}.contains(
                        _normalizedStatus((row['participation'] as Map)['status']),
                      )))
                ReferenceActionTarget(
                  id: int.parse('${(row['trip'] as Map)['id']}'),
                  label: 'رحلة ${(row['trip'] as Map)['id']} · ${(row['trip'] as Map)['plannedDepartureAt'] ?? ''}',
                ),
      ];
    }
    if (action == ReferenceAction.acceptReturn ||
        action == ReferenceAction.pickupReturn ||
        action == ReferenceAction.completeReturn) {
      final rows = await _client.get<List<dynamic>>('api/driver-journey/returns');
      final allowed = switch (action) {
        ReferenceAction.acceptReturn => const {'0', 'assigned'},
        ReferenceAction.pickupReturn => const {'1', 'accepted'},
        ReferenceAction.completeReturn => const {'2', 'pickedup'},
        _ => const <String>{},
      };
      return [
        for (final row in rows)
          if (row is Map &&
              int.tryParse('${row['id'] ?? ''}') != null &&
              allowed.contains(_normalizedStatus(row['status'])))
            ReferenceActionTarget(
              id: int.parse('${row['id']}'),
              label: 'مرتجع #${row['id']} · الحالة ${row['status']}',
            ),
      ];
    }
    final rows = await _client.get<List<dynamic>>('api/Shipments');
    return [
      for (final row in rows)
        if (row is Map &&
            selectShipmentIdForAction([row], action) != null)
          ReferenceActionTarget(
            id: selectShipmentIdForAction([row], action)!,
            label: 'شحنة ${row['shipmentNumber'] ?? row['id']} · الحالة ${row['status']}',
          ),
    ];
  }

  Future<void> runShipmentAction(
    ReferenceAction action, {
    int? targetId,
    String? reason,
    Map<String, dynamic>? fields,
  }) async {
    if (referenceActionNeedsTarget(action) && targetId == null) {
      throw StateError('حدد العرض أو الشحنة أو الرحلة أو المرتجع قبل تنفيذ الإجراء.');
    }
    if (action == ReferenceAction.toggleOffersPreference ||
        action == ReferenceAction.toggleScheduledTripsPreference) {
      final preference = await _client.get<Map<String, dynamic>>(
        'api/driver-journey/me/preferences',
      );
      const keys = [
        'acceptScheduledTrips',
        'acceptPrivateDeliveries',
        'acceptBatchDeliveries',
        'isAvailableForOffers',
        'offerRadiusKm',
        'offerTimeoutSeconds',
      ];
      if (keys.any((key) => !preference.containsKey(key))) {
        throw StateError('رد تفضيلات السائق غير مكتمل؛ لن يتم استبداله بقيم افتراضية.');
      }
      final body = {for (final key in keys) key: preference[key]};
      if (action == ReferenceAction.toggleOffersPreference) {
        body['isAvailableForOffers'] =
            preference['isAvailableForOffers'] != true;
      } else {
        body['acceptScheduledTrips'] =
            preference['acceptScheduledTrips'] != true;
      }
      await _client.put<dynamic>(
        'api/driver-journey/me/preferences',
        data: body,
      );
      return;
    }
    if (action == ReferenceAction.addAvailabilityWindow ||
        action == ReferenceAction.removeAvailabilityWindow) {
      final raw = await _client.get<List<dynamic>>(
        'api/driver-journey/me/availability',
      );
      if (raw.any((row) => row is! Map ||
          row['id'] == null ||
          row['dayOfWeek'] == null ||
          row['startTime'] == null ||
          row['endTime'] == null)) {
        throw StateError('تعذر الحفاظ على الجدول الأسبوعي الحالي من بيانات السيرفر.');
      }
      final body = <Map<String, dynamic>>[
        for (final row in raw)
          if (row is Map &&
              !(action == ReferenceAction.removeAvailabilityWindow &&
                int.tryParse('${row['id']}') == targetId))
            {
              'dayOfWeek': row['dayOfWeek'],
              'startTime': row['startTime'],
              'endTime': row['endTime'],
              'isActive': row['isActive'] ?? true,
            },
      ];
      if (action == ReferenceAction.removeAvailabilityWindow &&
          body.length == raw.length) {
        throw StateError('نافذة التوفر المحددة لم تعد موجودة.');
      }
      if (action == ReferenceAction.addAvailabilityWindow) {
        final day = int.tryParse('${fields?['dayOfWeek'] ?? ''}');
        final start = fields?['startTime']?.toString().trim() ?? '';
        final end = fields?['endTime']?.toString().trim() ?? '';
        final timeFormat = RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$');
        if (day == null || day < 0 || day > 6 ||
            !timeFormat.hasMatch(start) || !timeFormat.hasMatch(end) ||
            start.compareTo(end) >= 0) {
          throw StateError('حدد يومًا 0–6 ووقت بداية ونهاية بصيغة HH:mm مرتبين.');
        }
        body.add({
          'dayOfWeek': day,
          'startTime': '$start:00',
          'endTime': '$end:00',
          'isActive': true,
        });
      }
      await _client.put<dynamic>(
        'api/driver-journey/me/availability',
        data: body,
      );
      return;
    }
    if (action == ReferenceAction.markAllNotificationsRead) {
      await _client.post<dynamic>('api/notifications/mark-all-read');
      return;
    }
    if (action == ReferenceAction.saveBankAccount) {
      final data = fields ?? const <String, dynamic>{};
      if (['bankName', 'accountHolderName', 'iban'].any(
        (key) => (data[key]?.toString().trim().isEmpty ?? true),
      )) {
        throw StateError('بيانات الحساب البنكي غير مكتملة.');
      }
      await _client.put<dynamic>('api/driver-journey/bank-account', data: data);
      return;
    }
    if (action == ReferenceAction.requestPayout) {
      final amount = num.tryParse('${fields?['amount'] ?? ''}');
      if (amount == null || amount <= 0) {
        throw StateError('أدخل مبلغ سحب صالحًا أكبر من الصفر.');
      }
      final wallet = await _client.get<Map<String, dynamic>>('api/wallets/me');
      final currency = wallet['currency']?.toString() ??
          wallet['currencyCode']?.toString();
      if (currency == null || currency.isEmpty) {
        throw StateError('تعذر تحديد عملة المحفظة من السيرفر.');
      }
      await _client.post<dynamic>('api/driver-journey/payouts', data: {
        'bankAccountId': targetId,
        'amount': amount,
        'currency': currency,
      });
      return;
    }
    if (action == ReferenceAction.goOnline ||
        action == ReferenceAction.goOffline) {
      final online = action == ReferenceAction.goOnline;
      await _client.put<dynamic>(
        'api/driver-journey/me/status',
        data: {'operationalStatus': online ? 3 : 1, 'isAcceptingOrders': online},
      );
      return;
    }
    if (action == ReferenceAction.startShift ||
        action == ReferenceAction.endShift) {
      final verb = action == ReferenceAction.startShift ? 'start' : 'end';
      await _client.post<dynamic>(
        'api/driver-journey/shifts/$verb',
        data: const {'latitude': null, 'longitude': null},
      );
      return;
    }
    if (action == ReferenceAction.acceptOffer ||
        action == ReferenceAction.rejectOffer) {
      final verb = action == ReferenceAction.acceptOffer ? 'accept' : 'reject';
      await _client.post<dynamic>(
        'api/driver-journey/offers/$targetId/$verb',
      );
      return;
    }
    if (action == ReferenceAction.joinScheduledTrip ||
        action == ReferenceAction.withdrawScheduledTrip) {
      final verb = action == ReferenceAction.joinScheduledTrip ? 'join' : 'withdraw';
      await _client.post<dynamic>(
        'api/driver-journey/scheduled-trips/$targetId/$verb',
      );
      return;
    }
    if (action == ReferenceAction.acceptReturn ||
        action == ReferenceAction.pickupReturn ||
        action == ReferenceAction.completeReturn) {
      final verb = switch (action) {
        ReferenceAction.acceptReturn => 'accept',
        ReferenceAction.pickupReturn => 'pickup',
        _ => 'complete',
      };
      await _client.post<dynamic>(
        'api/driver-journey/returns/$targetId/$verb',
      );
      return;
    }
    if (action == ReferenceAction.createIncident) {
      throw ArgumentError.value(action);
    }

    // Re-read eligibility before the mutation; the API will independently
    // enforce driver ownership and reject stale state/expired offers.
    final rows = await _client.get<List<dynamic>>('api/Shipments');
    final selected = rows.where((row) =>
        row is Map && int.tryParse('${row['id'] ?? ''}') == targetId);
    if (selectShipmentIdForAction(selected, action) != targetId) {
      throw StateError('تغيرت حالة الشحنة أو لم تعد مؤهلة لهذا الإجراء. حدّث الشاشة.');
    }
    if (action == ReferenceAction.addPickupProof ||
        action == ReferenceAction.addDeliveryProof) {
      final reference = fields?['verificationReference']?.toString().trim() ?? '';
      final recipient = fields?['recipientName']?.toString().trim() ?? '';
      if (reference.isEmpty &&
          (action == ReferenceAction.addPickupProof || recipient.isEmpty)) {
        throw StateError('أدخل مرجع التحقق أو اسم المستلم قبل حفظ الإثبات.');
      }
      await _client.post<dynamic>('api/Shipments/$targetId/proof', data: {
        'type': action == ReferenceAction.addPickupProof ? 0 : 1,
        if (reference.isNotEmpty) 'verificationReference': reference,
        if (recipient.isNotEmpty) 'recipientName': recipient,
        'notes': fields?['notes']?.toString().trim(),
      });
      return;
    }
    final actionName = switch (action) {
      ReferenceAction.acceptShipment => 'accept',
      ReferenceAction.pickupShipment => 'pickup',
      ReferenceAction.startTransit => 'depart',
      ReferenceAction.nearCustomer => 'near-customer',
      ReferenceAction.deliverShipment => 'deliver',
      ReferenceAction.failShipment => 'fail',
      _ => throw ArgumentError.value(action),
    };
    await _client.post<dynamic>(
      'api/Shipments/$targetId/$actionName',
      data: action == ReferenceAction.failShipment
          ? {
              'reason': reason?.trim().isEmpty ?? true
                  ? 'تعذر الوصول للعميل'
                  : reason!.trim(),
            }
          : null,
    );
  }

  Future<void> createIncident({
    required String subject,
    required String message,
  }) async {
    final rows = await _client.get<List<dynamic>>('api/Shipments');
    int? shipmentId;
    for (final row in rows) {
      if (row is Map && row['id'] != null) {
        shipmentId = int.tryParse(row['id'].toString());
        if (shipmentId != null) break;
      }
    }
    await _client.post<dynamic>(
      'api/driver-journey/incidents',
      data: {
        'category': 'driver-report',
        'title': subject.trim(),
        'description': message.trim(),
        'isEmergency': false,
        if (shipmentId != null) 'shipmentId': shipmentId,
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
