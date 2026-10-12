import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazraa_driver/core/network/api_client.dart';
import 'package:mazraa_driver/core/network/driver_api.dart';
import 'package:mazraa_driver/core/storage/secure_session_store.dart';

final sessionStoreProvider = Provider<SecureSessionStore>(
  (ref) => SecureSessionStore(),
);

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(sessionStoreProvider)),
);

final driverApiProvider = Provider<DriverApi>(
  (ref) =>
      DriverApi(ref.watch(apiClientProvider), ref.watch(sessionStoreProvider)),
);
