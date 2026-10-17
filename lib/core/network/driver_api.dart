import 'package:mazraa_driver/core/constants/api_endpoints.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/core/network/api_client.dart';
import 'package:mazraa_driver/core/storage/secure_session_store.dart';

class DriverApi {
  const DriverApi(this._client, this._store);

  final ApiClient _client;
  final SecureSessionStore _store;

  Future<AuthSession> login(String email, String password) async {
    final json = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: {
        'email': email.trim(),
        'password': password,
        'deviceName': 'mazraa-driver-mobile',
      },
    );
    final session = AuthSession.fromJson(json);
    if (!session.isUsable) {
      throw const FormatException('استجابة تسجيل الدخول غير مكتملة.');
    }
    await _store.write(session);
    return session;
  }

  Future<void> logout() async {
    final session = await _store.read();
    try {
      if (session != null) {
        await _client.post<Object?>(
          ApiEndpoints.logout,
          data: {'refreshToken': session.refreshToken},
        );
      }
    } finally {
      await _store.clear();
    }
  }

  Future<DriverProfile> getDriver(int userId) async => DriverProfile.fromJson(
    await _client.get<Map<String, dynamic>>('${ApiEndpoints.drivers}/$userId'),
  );

  Future<Map<String, dynamic>> getJourneyMe() =>
      _client.get<Map<String, dynamic>>('api/driver-journey/me');

  Future<Map<String, dynamic>> updateDriverStatus({
    required int operationalStatus,
    required bool isAcceptingOrders,
    double? latitude,
    double? longitude,
  }) =>
      _client.put<Map<String, dynamic>>(
        'api/driver-journey/me/status',
        data: {
          'operationalStatus': operationalStatus,
          'isAcceptingOrders': isAcceptingOrders,
          'latitude': latitude,
          'longitude': longitude,
        },
      );

  Future<Map<String, dynamic>> getDriverPreferences() =>
      _client.get<Map<String, dynamic>>('api/driver-journey/me/preferences');

  Future<Map<String, dynamic>> updateDriverPreferences({
    required bool acceptScheduledTrips,
    required bool acceptPrivateDeliveries,
    required bool acceptBatchDeliveries,
    required bool isAvailableForOffers,
    double offerRadiusKm = 50,
    int offerTimeoutSeconds = 60,
  }) =>
      _client.put<Map<String, dynamic>>(
        'api/driver-journey/me/preferences',
        data: {
          'acceptScheduledTrips': acceptScheduledTrips,
          'acceptPrivateDeliveries': acceptPrivateDeliveries,
          'acceptBatchDeliveries': acceptBatchDeliveries,
          'isAvailableForOffers': isAvailableForOffers,
          'offerRadiusKm': offerRadiusKm,
          'offerTimeoutSeconds': offerTimeoutSeconds,
        },
      );

  Future<List<dynamic>> getDriverAvailability() =>
      _client.get<List<dynamic>>('api/driver-journey/me/availability');

  Future<void> updateDriverAvailability(List<Map<String, dynamic>> windows) =>
      _client.put<Object?>('api/driver-journey/me/availability', data: windows);

  Future<List<dynamic>> getOffers() =>
      _client.get<List<dynamic>>('api/driver-journey/offers');

  Future<void> acceptOffer(int offerId) =>
      _client.post<Object?>('api/driver-journey/offers/$offerId/accept');

  Future<void> rejectOffer(int offerId) =>
      _client.post<Object?>('api/driver-journey/offers/$offerId/reject');

  Future<List<dynamic>> getScheduledTrips() =>
      _client.get<List<dynamic>>('api/driver-journey/scheduled-trips');

  Future<void> joinScheduledTrip(int tripId) =>
      _client.post<Object?>('api/driver-journey/scheduled-trips/$tripId/join');

  Future<void> withdrawScheduledTrip(int tripId) =>
      _client.post<Object?>('api/driver-journey/scheduled-trips/$tripId/withdraw');

  Future<List<dynamic>> getCurrentTrips() =>
      _client.get<List<dynamic>>('api/driver-journey/trips/current');

  Future<Map<String, dynamic>> startShift({double? latitude, double? longitude}) =>
      _client.post<Map<String, dynamic>>(
        'api/driver-journey/shifts/start',
        data: {'latitude': latitude, 'longitude': longitude},
      );

  Future<Map<String, dynamic>> endShift({double? latitude, double? longitude}) =>
      _client.post<Map<String, dynamic>>(
        'api/driver-journey/shifts/end',
        data: {'latitude': latitude, 'longitude': longitude},
      );

  Future<List<dynamic>> getShifts() =>
      _client.get<List<dynamic>>('api/driver-journey/shifts');

  Future<List<dynamic>> getDriverDocuments() =>
      _client.get<List<dynamic>>('api/driver-journey/documents');

  Future<List<dynamic>> getVehicleMaintenance() =>
      _client.get<List<dynamic>>('api/driver-journey/vehicle-maintenance');

  Future<List<dynamic>> getBankAccounts() =>
      _client.get<List<dynamic>>('api/driver-journey/bank-accounts');

  Future<Map<String, dynamic>> putBankAccount({
    required String bankName,
    required String accountHolderName,
    required String iban,
    String? accountNumber,
  }) =>
      _client.put<Map<String, dynamic>>(
        'api/driver-journey/bank-account',
        data: {
          'bankName': bankName.trim(),
          'accountHolderName': accountHolderName.trim(),
          'iban': iban.trim(),
          'accountNumber': accountNumber?.trim(),
        },
      );

  Future<List<dynamic>> getPayouts() =>
      _client.get<List<dynamic>>('api/driver-journey/payouts');

  Future<Map<String, dynamic>> requestPayout({
    required int bankAccountId,
    required double amount,
    String currency = 'SAR',
  }) =>
      _client.post<Map<String, dynamic>>(
        'api/driver-journey/payouts',
        data: {
          'bankAccountId': bankAccountId,
          'amount': amount,
          'currency': currency,
        },
      );

  Future<List<dynamic>> getIncentives() =>
      _client.get<List<dynamic>>('api/driver-journey/incentives');

  Future<Map<String, dynamic>> getReferral() =>
      _client.get<Map<String, dynamic>>('api/driver-journey/referral');

  Future<List<dynamic>> getIncidents() =>
      _client.get<List<dynamic>>('api/driver-journey/incidents');

  Future<Map<String, dynamic>> createDriverIncident({
    required String category,
    required String title,
    required String description,
    required bool isEmergency,
    int? shipmentId,
    double? latitude,
    double? longitude,
  }) =>
      _client.post<Map<String, dynamic>>(
        'api/driver-journey/incidents',
        data: {
          'category': category.trim(),
          'title': title.trim(),
          'description': description.trim(),
          'isEmergency': isEmergency,
          'shipmentId': shipmentId,
          'latitude': latitude,
          'longitude': longitude,
        },
      );

  Future<List<dynamic>> getReturnTasks() =>
      _client.get<List<dynamic>>('api/driver-journey/returns');

  Future<void> acceptReturnTask(int taskId) =>
      _client.post<Object?>('api/driver-journey/returns/$taskId/accept');

  Future<void> pickupReturnTask(int taskId) =>
      _client.post<Object?>('api/driver-journey/returns/$taskId/pickup');

  Future<void> completeReturnTask(int taskId) =>
      _client.post<Object?>('api/driver-journey/returns/$taskId/complete');

  Future<Map<String, dynamic>> getPerformance() =>
      _client.get<Map<String, dynamic>>('api/driver-journey/performance');

  Future<List<Shipment>> getShipments() async {
    final json = await _client.get<List<dynamic>>(ApiEndpoints.shipments);
    return json
        .whereType<Map<String, dynamic>>()
        .map(Shipment.fromJson)
        .toList(growable: false);
  }

  Future<Shipment> getShipment(int id) async => Shipment.fromJson(
    await _client.get<Map<String, dynamic>>('${ApiEndpoints.shipments}/$id'),
  );

  Future<Shipment> getTracking(int id) async => Shipment.fromJson(
    await _client.get<Map<String, dynamic>>(
      '${ApiEndpoints.shipments}/$id/tracking',
    ),
  );

  Future<void> changeShipmentStatus(
    int id,
    String action, {
    String? reason,
    String? numericCode,
    String? qrToken,
  }) async {
    Object? data;
    if (action == 'fail') {
      data = {'reason': reason};
    } else if (action == 'deliver' && (numericCode != null || qrToken != null)) {
      data = {'numericCode': numericCode, 'qrToken': qrToken};
    }
    await _client.post<Object?>(
      '${ApiEndpoints.shipments}/$id/$action',
      data: data,
    );
  }

  Future<void> acceptShipment(int id) => changeShipmentStatus(id, 'accept');
  Future<void> rejectShipment(int id) => changeShipmentStatus(id, 'reject');
  Future<void> pickupShipment(int id) => changeShipmentStatus(id, 'pickup');
  Future<void> departShipment(int id) => changeShipmentStatus(id, 'depart');
  Future<void> markNearCustomer(int id) => changeShipmentStatus(id, 'near-customer');
  Future<void> deliverShipment(int id, {String? numericCode, String? qrToken}) =>
      changeShipmentStatus(id, 'deliver', numericCode: numericCode, qrToken: qrToken);
  Future<void> failShipment(int id, {String? reason}) =>
      changeShipmentStatus(id, 'fail', reason: reason);

  Future<void> updateLocation(
    int shipmentId, {
    required double latitude,
    required double longitude,
    double? heading,
    double? speedKph,
    double? accuracyMeters,
  }) async {
    await _client.post<Object?>(
      '${ApiEndpoints.shipments}/$shipmentId/location',
      data: {
        'latitude': latitude,
        'longitude': longitude,
        'heading': heading,
        'speedKph': speedKph,
        'accuracyMeters': accuracyMeters,
      },
    );
  }

  Future<WalletSummary> getWallet() async => WalletSummary.fromJson(
    await _client.get<Map<String, dynamic>>(ApiEndpoints.wallet),
  );

  Future<List<WalletTransaction>> getWalletTransactions() async {
    final json = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.walletTransactions,
      queryParameters: const {'page': 1, 'perPage': 50},
    );
    return (json['data'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(WalletTransaction.fromJson)
        .toList(growable: false);
  }

  Future<List<AppNotification>> getNotifications({bool? unreadOnly}) async {
    final query = <String, dynamic>{'page': 1, 'pageSize': 50};
    if (unreadOnly != null) query['unreadOnly'] = unreadOnly;
    final json = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.notifications,
      queryParameters: query,
    );
    return (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList(growable: false);
  }

  Future<int> unreadNotificationCount() async =>
      (await _client.get<Map<String, dynamic>>(
            ApiEndpoints.unreadNotifications,
          ))['count']
          as int? ??
      0;

  Future<void> markNotificationsRead(List<int> ids) async {
    if (ids.isEmpty) return;
    await _client.post<Object?>(
      '${ApiEndpoints.notifications}/mark-read',
      data: ids,
    );
  }

  Future<void> markAllNotificationsRead() =>
      _client.post<Object?>('${ApiEndpoints.notifications}/mark-all-read');
}