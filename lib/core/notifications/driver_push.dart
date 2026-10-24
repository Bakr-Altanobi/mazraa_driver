import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mazraa_driver/core/network/driver_api.dart';

/// Public Firebase client configuration for the registered com.mazraa.driver app.
/// No Firebase service-account credentials belong in a mobile build.
FirebaseOptions? driverFirebaseOptions() {
  const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  const appId = String.fromEnvironment('FIREBASE_APP_ID');
  const senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  if ([apiKey, appId, senderId, projectId].any((v) => v.isEmpty)) return null;
  return const FirebaseOptions(apiKey: apiKey, appId: appId,
      messagingSenderId: senderId, projectId: projectId,
      iosBundleId: 'com.mazraa.driver');
}

@pragma('vm:entry-point')
Future<void> driverPushBackground(RemoteMessage message) async {
  final options = driverFirebaseOptions();
  if (options != null && Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: options);
  }
  // FCM displays notification payloads in the background. UI/API mutations
  // wait until the signed-in application resumes.
}

Future<void> initializeDriverPush() async {
  final options = driverFirebaseOptions();
  if (options == null) return;
  try {
    await Firebase.initializeApp(options: options);
    FirebaseMessaging.onBackgroundMessage(driverPushBackground);
  } catch (_) {
    // An unavailable provider must not prevent sign-in or foreground refresh.
  }
}

class DriverPushSession {
  DriverPushSession(this.api, {required this.onMessage, required this.onOpen});
  final DriverApi api;
  final void Function(String? title, String? body) onMessage;
  final void Function(Map<String, dynamic> data) onOpen;
  StreamSubscription<String>? _tokens;
  StreamSubscription<RemoteMessage>? _messages, _opened;
  int _generation = 0;
  bool _disposed = false;

  Future<void> activate() async {
    final generation = ++_generation;
    if (_disposed || Firebase.apps.isEmpty) return;
    final messaging = FirebaseMessaging.instance;
    try {
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      if (_disposed || generation != _generation) return;
      await _tokens?.cancel(); await _messages?.cancel(); await _opened?.cancel();
      Future<void> register(String token) async {
        if (_disposed || generation != _generation) return;
        try { await api.registerPushToken(token); } catch (_) { /* retry on next activation/resume */ }
      }
      _tokens = messaging.onTokenRefresh.listen((token) => unawaited(register(token)));
      _messages = FirebaseMessaging.onMessage.listen((message) {
        if (!_disposed && generation == _generation) {
          onMessage(message.notification?.title, message.notification?.body);
        }
      });
      _opened = FirebaseMessaging.onMessageOpenedApp.listen((message) {
        if (!_disposed && generation == _generation) onOpen(message.data);
      });
      final token = await messaging.getToken();
      if (token != null) await register(token);
      final initial = await messaging.getInitialMessage();
      if (!_disposed && generation == _generation && initial != null) onOpen(initial.data);
    } catch (_) { /* the foreground API fallback remains available */ }
  }
  void pause() {
    _generation++;
    unawaited(_tokens?.cancel()); unawaited(_messages?.cancel()); unawaited(_opened?.cancel());
    _tokens = null; _messages = null; _opened = null;
  }
  void dispose() { _disposed = true; pause(); }
}
