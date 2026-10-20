import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mazraa_driver/core/network/providers.dart';
import 'package:mazraa_driver/features/auth/auth_controller.dart';
import 'package:mazraa_driver/features/notifications/notification_providers.dart';
import 'package:mazraa_driver/features/operations/driver_live_providers.dart';
import 'package:mazraa_driver/features/shipments/shipment_providers.dart';

/// One app-wide foreground fallback when a push is delayed or unavailable.
class DriverRuntimeSync extends ConsumerStatefulWidget {
  const DriverRuntimeSync({required this.child, super.key});
  final Widget child;
  @override
  ConsumerState<DriverRuntimeSync> createState() => _DriverRuntimeSyncState();
}

class _DriverRuntimeSyncState extends ConsumerState<DriverRuntimeSync>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _foreground = true;
  bool _polling = false;
  int _tick = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _poll());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) unawaited(_poll());
  }

  Future<void> _poll() async {
    final auth = ref.read(authControllerProvider);
    final userId = auth.session?.userId;
    if (!_foreground || _polling || !auth.isAuthenticated || userId == null)
      return;
    _polling = true;
    try {
      ref.invalidate(driverOffersProvider);
      await ref.read(driverOffersProvider.future);
      if (!mounted) return;
      if (_tick++ % 3 == 0) {
        ref.invalidate(shipmentsProvider);
        ref.invalidate(notificationsProvider);
        ref.invalidate(unreadNotificationsProvider);
        ref.invalidate(driverJourneyProvider);
      }
      if (_tick % 4 == 1 && auth.profile?.isAcceptingOrders == true) {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          final point = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 12),
            ),
          );
          if (mounted &&
              _foreground &&
              ref.read(authControllerProvider).session?.userId == userId) {
            await ref
                .read(driverApiProvider)
                .updateAvailabilityLocation(
                  latitude: point.latitude,
                  longitude: point.longitude,
                );
          }
        }
      }
    } catch (_) {
      // Screens keep their own visible connection/error state and last result.
    } finally {
      _polling = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int?>(
      authControllerProvider.select(
        (a) => a.isAuthenticated ? a.session?.userId : null,
      ),
      (before, after) {
        if (before == after) return;
        ref.invalidate(driverOffersProvider);
        ref.invalidate(driverJourneyProvider);
        ref.invalidate(shipmentsProvider);
        ref.invalidate(notificationsProvider);
        ref.invalidate(unreadNotificationsProvider);
        if (after != null) unawaited(_poll());
      },
    );
    return widget.child;
  }
}
