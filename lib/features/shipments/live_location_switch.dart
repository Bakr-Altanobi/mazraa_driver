import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/core/network/providers.dart';
import 'package:mazraa_driver/features/shipments/shipment_providers.dart';
import 'package:mazraa_driver/shared/widgets/mazraa_widgets.dart';

/// An explicit opt-in GPS stream active only while the driver keeps the
/// relevant trip screen open. It does not claim background tracking support.
class LiveLocationSwitch extends ConsumerStatefulWidget {
  const LiveLocationSwitch({required this.shipment, super.key});
  final Shipment shipment;

  @override
  ConsumerState<LiveLocationSwitch> createState() => _LiveLocationSwitchState();
}

class _LiveLocationSwitchState extends ConsumerState<LiveLocationSwitch> {
  StreamSubscription<Position>? _subscription;
  bool _enabled = false;
  bool _uploading = false;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _toggle(bool enabled) async {
    if (!enabled) {
      await _subscription?.cancel();
      _subscription = null;
      if (mounted) setState(() => _enabled = false);
      return;
    }
    final ar = isArabic(context);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError(ar ? 'خدمات الموقع مغلقة' : 'Location services are disabled');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError(ar ? 'يجب منح إذن الموقع' : 'Location permission required');
      }
      await _subscription?.cancel();
      _subscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 35,
        ),
      ).listen((position) async {
        if (!mounted || _uploading) return;
        _uploading = true;
        try {
          await ref.read(driverApiProvider).updateLocation(
            widget.shipment.id,
            latitude: position.latitude,
            longitude: position.longitude,
            heading: position.heading,
            speedKph: position.speed * 3.6,
            accuracyMeters: position.accuracy,
          );
          if (mounted) ref.invalidate(shipmentTrackingProvider(widget.shipment.id));
        } catch (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error.toString())),
            );
          }
        } finally {
          _uploading = false;
        }
      }, onError: (Object error) {
        if (mounted) {
          setState(() => _enabled = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString())),
          );
        }
      });
      if (mounted) setState(() => _enabled = true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    return Card(
      child: SwitchListTile.adaptive(
        value: _enabled,
        onChanged: widget.shipment.status.isClosed ? null : _toggle,
        secondary: const Icon(Icons.location_searching_rounded),
        title: Text(ar ? 'مشاركة الموقع المباشر' : 'Share live location'),
        subtitle: Text(ar
          ? 'يرسل موقعك للسيرفر أثناء فتح هذه الشاشة فقط.'
          : 'Your location is uploaded only while this screen is open.'),
      ),
    );
  }
}
