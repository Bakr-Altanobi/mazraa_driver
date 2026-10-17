import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/core/network/api_client.dart';
import 'package:mazraa_driver/core/network/providers.dart';
import 'package:mazraa_driver/core/storage/secure_session_store.dart';

final driverRegistrationApiProvider = Provider<DriverRegistrationApi>((ref) {
  return DriverRegistrationApi(
    ref.watch(apiClientProvider),
    ref.watch(sessionStoreProvider),
  );
});

class DriverRegistrationApi {
  const DriverRegistrationApi(this._client, this._store);

  final ApiClient _client;
  final SecureSessionStore _store;

  Future<AuthSession> registerAndApply({
    required String name,
    required String email,
    required String password,
    required int vehicleType,
    int maxActiveShipments = 3,
    String? notes,
  }) async {
    final json = await _client.post<Map<String, dynamic>>(
      'api/Auth/register',
      data: {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
      },
    );
    final session = AuthSession.fromJson(json);
    if (!session.isUsable) {
      throw const FormatException('استجابة إنشاء الحساب غير مكتملة.');
    }
    await _store.write(session);

    await _client.post<Map<String, dynamic>>(
      'api/driver-journey/apply',
      data: {
        'vehicleType': vehicleType,
        'maxActiveShipments': maxActiveShipments.clamp(1, 20),
        'notes': notes?.trim(),
      },
    );
    return session;
  }

  Future<void> applyCurrentAccount({
    required int vehicleType,
    int maxActiveShipments = 3,
    String? notes,
  }) =>
      _client.post<Object?>(
        'api/driver-journey/apply',
        data: {
          'vehicleType': vehicleType,
          'maxActiveShipments': maxActiveShipments.clamp(1, 20),
          'notes': notes?.trim(),
        },
      );
}
