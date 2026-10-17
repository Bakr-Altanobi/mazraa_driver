import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/core/network/api_client.dart';
import 'package:mazraa_driver/core/network/api_exception.dart';
import 'package:mazraa_driver/core/network/driver_api.dart';
import 'package:mazraa_driver/core/storage/secure_session_store.dart';
import 'package:mazraa_driver/features/auth/auth_controller.dart';

const _session = AuthSession(
  accessToken: 'driver-test-access-token',
  refreshToken: 'driver-test-refresh-token',
  userId: 501,
);

class _MemorySessionStore extends SecureSessionStore {
  AuthSession? current;
  int clears = 0;

  @override
  Future<AuthSession?> read() async => current;

  @override
  Future<void> write(AuthSession value) async {
    current = value;
  }

  @override
  Future<void> clear() async {
    current = null;
    clears++;
  }
}

class _NonDriverApi extends DriverApi {
  _NonDriverApi(this.memory) : super(ApiClient(memory), memory);

  final _MemorySessionStore memory;

  @override
  Future<AuthSession> login(String email, String password) async {
    await memory.write(_session);
    return _session;
  }

  @override
  Future<DriverProfile> getDriver(int userId) async {
    throw const ApiException('Driver does not exist.', statusCode: 404);
  }
}

void main() {
  test('non-driver restored session is cleared rather than looping at splash',
      () async {
    final store = _MemorySessionStore()..current = _session;
    final controller = AuthController(_NonDriverApi(store), store);

    await controller.initialize();

    expect(controller.state, AuthState.signedOut);
    expect(controller.session, isNull);
    expect(store.current, isNull);
    expect(store.clears, 1);
    expect(controller.errorMessage, contains('غير مسجل كسائق'));
  });

  test('non-driver login cannot leave a persisted unusable driver token',
      () async {
    final store = _MemorySessionStore();
    final controller = AuthController(_NonDriverApi(store), store);

    final result = await controller.login('new@example.test', 'a-password');

    expect(result, isFalse);
    expect(controller.state, AuthState.signedOut);
    expect(controller.session, isNull);
    expect(store.current, isNull);
    expect(store.clears, 1);
    expect(controller.errorMessage, contains('استكمال طلب حساب موجود'));
  });
}
