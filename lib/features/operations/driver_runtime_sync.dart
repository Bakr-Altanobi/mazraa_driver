import 'package:mazraa_driver/features/operations/driver_account_cache.dart';
import 'dart:async';
import 'package:mazraa_driver/core/notifications/driver_push.dart';
import 'package:mazraa_driver/app/app_router.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mazraa_driver/core/network/providers.dart';
import 'package:mazraa_driver/features/auth/auth_controller.dart';
import 'package:mazraa_driver/features/notifications/notification_providers.dart';
import 'package:mazraa_driver/features/operations/driver_live_providers.dart';
import 'package:mazraa_driver/features/shipments/shipment_providers.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/features/shipments/driver_location_session.dart';

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
  DriverPushSession? _push;
  void _refreshFromPush(String? title, String? body) {
    if (!mounted) return;
    unawaited(_poll());
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationsProvider);
    if (_foreground && (title?.isNotEmpty ?? false)) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text([title, body].whereType<String>().join(' — '))),
      );
    }
  }

  void _openPush(Map<String, dynamic> data) {
    if (!mounted || !ref.read(authControllerProvider).isAuthenticated) return;
    _refreshFromPush(null, null);
    final shipmentId = int.tryParse(data['shipmentId']?.toString() ?? '');
    final deepLink = data['deepLink']?.toString();
    final route = deepLink == '/offers'
        ? '/offers'
        : shipmentId != null && shipmentId > 0
        ? '/shipments/$shipmentId'
        : '/notifications';
    ref.read(appRouterProvider).push(route);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _push = DriverPushSession(
      ref.read(driverApiProvider),
      onMessage: _refreshFromPush,
      onOpen: _openPush,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(authControllerProvider).isAuthenticated)
        unawaited(_push?.activate());
    });
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _poll());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      unawaited(_poll());
      if (ref.read(authControllerProvider).isAuthenticated)
        unawaited(_push?.activate());
    }
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
      if (_tick % 4 == 1 &&
          auth.profile?.isAcceptingOrders == true &&
          !ref.read(driverLocationSessionProvider).availabilityEnabled) {
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
            if (mounted &&
                _foreground &&
                ref.read(authControllerProvider).session?.userId == userId) {
              await ref
                  .read(driverLocationSessionProvider)
                  .enableAvailability(
                    arabic:
                        Localizations.localeOf(context).languageCode == 'ar',
                  );
            }
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
    _push?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(authControllerProvider.select((a) => a.isAuthenticated)))
      ref.listen<AsyncValue<List<Shipment>>>(shipmentsProvider, (
        before,
        after,
      ) {
        if (after.hasValue && !after.isLoading) {
          ref
              .read(driverLocationSessionProvider)
              .retainActive(
                after.requireValue
                    .where((s) => !s.status.isClosed)
                    .map((s) => s.id)
                    .toSet(),
              );
        }
      });
    ref.listen<int?>(
      authControllerProvider.select(
        (a) => a.isAuthenticated ? a.session?.userId : null,
      ),
      (before, after) {
        if (before == after) return;
        ref.read(resetDriverAccountCacheProvider)();
        ref.read(driverLocationSessionProvider).stop();
        _push?.pause();
        if (after != null) {
          unawaited(_poll());
          unawaited(_push?.activate());
        }
      },
    );
    return widget.child;
  }
}
