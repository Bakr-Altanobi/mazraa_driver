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
  }) async {
    await _client.post<Object?>(
      '${ApiEndpoints.shipments}/$id/$action',
      data: reason == null ? null : {'reason': reason},
    );
  }

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
