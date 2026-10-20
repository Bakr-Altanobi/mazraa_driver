import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mazraa_driver/core/network/driver_api.dart';
import 'package:mazraa_driver/core/network/providers.dart';
import 'package:mazraa_driver/features/auth/auth_controller.dart';

final driverLocationSessionProvider = ChangeNotifierProvider<DriverLocationSession>((ref) {
  final session = DriverLocationSession(ref.read(driverApiProvider),
    () => ref.read(authControllerProvider).isAuthenticated
        ? ref.read(authControllerProvider).session?.userId : null);
  ref.listen<int?>(authControllerProvider.select((a) => a.isAuthenticated ? a.session?.userId : null),
      (before, after) { if (before != after) session.stop(); });
  return session;
});

/// A single explicit opt-in stream survives navigation between screens.
/// Android uses a visible foreground service; force-stop still stops tracking.
class DriverLocationSession extends ChangeNotifier {
  DriverLocationSession(this._api, this._currentUser);
  final DriverApi _api;
  final int? Function() _currentUser;
  StreamSubscription<Position>? _subscription;
  final Set<int> _shipments = {};
  bool _uploading = false, _disposed = false;
  int _generation = 0;
  int? _owner;
  bool _availability = false;
  bool get availabilityEnabled => _availability;
  String? lastError;
  bool isSharing(int shipmentId) => _shipments.contains(shipmentId);

  Future<void> enable(int shipmentId, {required bool arabic}) => _enable(shipmentId: shipmentId, arabic: arabic);
  Future<void> enableAvailability({required bool arabic}) => _enable(arabic: arabic);
  Future<void> _enable({int? shipmentId, required bool arabic}) async {
    if (_disposed || (shipmentId == null ? _availability : _shipments.contains(shipmentId))) return;
    final owner = _currentUser();
    if (owner == null) throw StateError(arabic ? 'سجّل الدخول أولًا' : 'Sign in first');
    final generation = _generation;
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError(arabic ? 'خدمات الموقع مغلقة' : 'Location services are disabled');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) {
      throw StateError(arabic ? 'يجب منح إذن الموقع' : 'Location permission required');
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // A driver must be able to see the ongoing location-sharing notification.
      await Permission.notification.request();
    }
    if (_disposed || owner != _currentUser() || generation != _generation) return;
    _owner = owner;
    if (shipmentId == null) { _availability = true; } else { _shipments.add(shipmentId); }
    if (_subscription == null) {
      final LocationSettings settings = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
          ? AndroidSettings(accuracy: LocationAccuracy.high, distanceFilter: 0,
              intervalDuration: const Duration(seconds: 30),
              foregroundNotificationConfig: ForegroundNotificationConfig(
                notificationTitle: arabic ? 'مشاركة موقع التوصيل' : 'Delivery location sharing',
                notificationText: arabic ? 'مزرعتي يشارك موقع الرحلة. أوقف المشاركة من التطبيق.' : 'Mazraa is sharing your trip location. Stop sharing in the app.',
                enableWakeLock: true, setOngoing: true))
          : const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 35);
      _subscription = Geolocator.getPositionStream(locationSettings: settings).listen(
        (position) => unawaited(_upload(position)), onError: (Object error) {
          if (!_disposed) { lastError = error.toString(); stop(clearError: false); }
        });
    }
    lastError = null;
    notifyListeners();
  }

  Future<void> _upload(Position point) async {
    if (_disposed || _uploading || _owner != _currentUser() || (_shipments.isEmpty && !_availability)) return;
    _uploading = true;
    final generation = _generation;
    try {
      if (_availability) await _api.updateAvailabilityLocation(latitude: point.latitude, longitude: point.longitude);
      for (final id in _shipments.toList()) {
        if (_disposed || generation != _generation || _owner != _currentUser() || !_shipments.contains(id)) break;
        await _api.updateLocation(id, latitude: point.latitude, longitude: point.longitude,
            heading: point.heading.isFinite && point.heading >= 0 ? point.heading : null,
            speedKph: point.speed.isFinite && point.speed >= 0 ? point.speed * 3.6 : null,
            accuracyMeters: point.accuracy.isFinite && point.accuracy >= 0 ? point.accuracy : null);
      }
      if (!_disposed && generation == _generation) { lastError = null; notifyListeners(); }
    } catch (error) {
      if (!_disposed && generation == _generation) { lastError = error.toString(); notifyListeners(); }
    } finally { _uploading = false; }
  }

  void disable(int shipmentId) {
    if (!_shipments.remove(shipmentId)) return;
    if (_shipments.isEmpty && !_availability) { stop(); } else { notifyListeners(); }
  }
  void retainActive(Set<int> ids) {
    if (_shipments.difference(ids).isEmpty) return;
    _shipments.retainAll(ids);
    if (_shipments.isEmpty && !_availability) { stop(); } else { notifyListeners(); }
  }
  void disableAvailability() {
    _availability = false;
    if (_shipments.isEmpty) { stop(); } else { notifyListeners(); }
  }
  void stop({bool clearError = true}) {
    _generation++; _shipments.clear(); _owner = null; _availability = false;
    unawaited(_subscription?.cancel()); _subscription = null;
    if (clearError) lastError = null;
    if (!_disposed) notifyListeners();
  }
  @override
  void dispose() { _disposed = true; stop(); super.dispose(); }
}
