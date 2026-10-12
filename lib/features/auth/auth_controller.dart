import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/core/network/driver_api.dart';
import 'package:mazraa_driver/core/network/providers.dart';
import 'package:mazraa_driver/core/storage/secure_session_store.dart';

enum AuthState { initial, restoring, signedOut, signingIn, authenticated }

class AuthController extends ChangeNotifier {
  AuthController(this._api, this._store);

  final DriverApi _api;
  final SecureSessionStore _store;

  AuthState state = AuthState.initial;
  AuthSession? session;
  DriverProfile? profile;
  String? errorMessage;

  bool get isAuthenticated => state == AuthState.authenticated;

  Future<void> initialize() async {
    if (state != AuthState.initial) return;
    state = AuthState.restoring;
    notifyListeners();
    try {
      final stored = await _store.read();
      if (stored == null) {
        state = AuthState.signedOut;
      } else {
        session = stored;
        profile = await _api.getDriver(stored.userId);
        state = AuthState.authenticated;
      }
    } catch (_) {
      await _store.clear();
      session = null;
      profile = null;
      state = AuthState.signedOut;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    if (state == AuthState.signingIn) return false;
    state = AuthState.signingIn;
    errorMessage = null;
    notifyListeners();
    try {
      final nextSession = await _api.login(email, password);
      final nextProfile = await _api.getDriver(nextSession.userId);
      session = nextSession;
      profile = nextProfile;
      state = AuthState.authenticated;
      notifyListeners();
      return true;
    } catch (error) {
      await _store.clear();
      errorMessage = error.toString();
      state = AuthState.signedOut;
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshProfile() async {
    final current = session;
    if (current == null) return;
    profile = await _api.getDriver(current.userId);
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } finally {
      session = null;
      profile = null;
      errorMessage = null;
      state = AuthState.signedOut;
      notifyListeners();
    }
  }
}

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  return AuthController(
    ref.watch(driverApiProvider),
    ref.watch(sessionStoreProvider),
  );
});
