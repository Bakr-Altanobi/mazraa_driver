import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/features/shipments/driver_location_session.dart';
import 'package:mazraa_driver/shared/widgets/mazraa_widgets.dart';

class LiveLocationSwitch extends ConsumerStatefulWidget {
  const LiveLocationSwitch({required this.shipment, super.key});
  final Shipment shipment;
  @override
  ConsumerState<LiveLocationSwitch> createState() => _LiveLocationSwitchState();
}
class _LiveLocationSwitchState extends ConsumerState<LiveLocationSwitch> {
  bool _busy = false;
  Future<void> _toggle(bool enabled) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final session = ref.read(driverLocationSessionProvider);
      if (enabled) { await session.enable(widget.shipment.id, arabic: isArabic(context)); }
      else { session.disable(widget.shipment.id); }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally { if (mounted) setState(() => _busy = false); }
  }
  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    final session = ref.watch(driverLocationSessionProvider);
    return Card(child: SwitchListTile.adaptive(
      value: session.isSharing(widget.shipment.id),
      onChanged: widget.shipment.status.isClosed || _busy ? null : _toggle,
      secondary: const Icon(Icons.location_searching_rounded),
      title: Text(ar ? 'مشاركة الموقع المباشر' : 'Share live location'),
      subtitle: Text(session.lastError ?? (ar
          ? 'تستمر أثناء التنقل بين الشاشات. في Android يظهر إشعار دائم. تتوقف عند إنهاء الرحلة أو تسجيل الخروج.'
          : 'Continues between screens, with an ongoing Android notification. Stops when the trip ends or you sign out.')),
    ));
  }
}
