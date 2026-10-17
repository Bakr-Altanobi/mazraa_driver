import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/core/network/providers.dart';
import 'package:mazraa_driver/core/theme/app_theme.dart';
import 'package:mazraa_driver/core/utils/formatters.dart';
import 'package:mazraa_driver/features/shipments/shipment_providers.dart';
import 'package:mazraa_driver/features/shipments/driver_offers_panel.dart';
import 'package:mazraa_driver/shared/widgets/map_panel.dart';
import 'package:mazraa_driver/shared/widgets/mazraa_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

enum _ShipmentFilter { all, active, completed, available }

class ShipmentsScreen extends ConsumerStatefulWidget {
  const ShipmentsScreen({super.key});

  @override
  ConsumerState<ShipmentsScreen> createState() => _ShipmentsScreenState();
}

class _ShipmentsScreenState extends ConsumerState<ShipmentsScreen> {
  final _search = TextEditingController();
  var _filter = _ShipmentFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    final state = ref.watch(shipmentsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(ar ? 'الشحنات' : 'Shipments'),
        actions: [
          IconButton(
            tooltip: ar ? 'تحديث' : 'Refresh',
            onPressed: () {
              ref.invalidate(shipmentsProvider);
              ref.invalidate(driverOffersProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: ar
                    ? 'ابحث برقم الشحنة أو الطلب'
                    : 'Search shipment or order',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () => setState(_search.clear),
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 46,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: ar ? 'الكل' : 'All',
                  selected: _filter == _ShipmentFilter.all,
                  onTap: () => setState(() => _filter = _ShipmentFilter.all),
                ),
                _FilterChip(
                  label: ar ? 'النشطة' : 'Active',
                  selected: _filter == _ShipmentFilter.active,
                  onTap: () => setState(() => _filter = _ShipmentFilter.active),
                ),
                _FilterChip(
                  label: ar ? 'السابقة' : 'History',
                  selected: _filter == _ShipmentFilter.completed,
                  onTap: () =>
                      setState(() => _filter = _ShipmentFilter.completed),
                ),
                _FilterChip(
                  label: ar ? 'العروض المتاحة' : 'Available offers',
                  selected: _filter == _ShipmentFilter.available,
                  onTap: () =>
                      setState(() => _filter = _ShipmentFilter.available),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _filter == _ShipmentFilter.available
                ? const DriverOffersPanel()
                : state.when(
              loading: LoadingList.new,
              error: (error, _) => ErrorState(
                error: error,
                onRetry: () => ref.invalidate(shipmentsProvider),
              ),
              data: (items) {
                final query = _search.text.trim().toLowerCase();
                final filtered = items.where((item) {
                  final matchesFilter = switch (_filter) {
                    _ShipmentFilter.all => true,
                    _ShipmentFilter.active => item.status.isActive,
                    _ShipmentFilter.completed => item.status.isClosed,
                    _ShipmentFilter.available => false,
                  };
                  return matchesFilter &&
                      (query.isEmpty ||
                          item.number.toLowerCase().contains(query) ||
                          item.orderId.toString().contains(query));
                }).toList();
                if (filtered.isEmpty) {
                  return EmptyState(
                    title: ar ? 'لا توجد شحنات' : 'No shipments',
                    message: ar
                        ? 'لا توجد نتائج مطابقة في هذا القسم.'
                        : 'There are no matching shipments in this section.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(shipmentsProvider);
                    await ref.read(shipmentsProvider.future);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 11),
                    itemBuilder: (context, index) =>
                        _ShipmentCard(shipment: filtered[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _ShipmentCard extends StatelessWidget {
  const _ShipmentCard({required this.shipment});
  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    final color = _statusColor(shipment.status);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => context.push('/shipments/${shipment.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(Icons.local_shipping_rounded, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shipment.number,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${ar ? 'طلب' : 'Order'} #${shipment.orderId}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  StatusPill(label: shipment.status.label(ar), color: color),
                ],
              ),
              const SizedBox(height: 14),
              Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _TinyInfo(
                      icon: Icons.payments_outlined,
                      label: ar ? 'رسوم التوصيل' : 'Delivery fee',
                      value: formatMoney(
                        shipment.deliveryFee,
                        'SAR',
                        locale: ar ? 'ar' : 'en',
                      ),
                    ),
                  ),
                  Expanded(
                    child: _TinyInfo(
                      icon: Icons.schedule_rounded,
                      label: ar ? 'تاريخ الإنشاء' : 'Created',
                      value: formatDateTime(
                        shipment.createdAt,
                        locale: ar ? 'ar' : 'en',
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShipmentDetailsScreen extends ConsumerStatefulWidget {
  const ShipmentDetailsScreen({required this.shipmentId, super.key});
  final int shipmentId;

  @override
  ConsumerState<ShipmentDetailsScreen> createState() =>
      _ShipmentDetailsScreenState();
}

class _ShipmentDetailsScreenState extends ConsumerState<ShipmentDetailsScreen> {
  bool _acting = false;
  bool _sendingLocation = false;

  Future<void> _runAction(String action, Shipment shipment) async {
    final ar = isArabic(context);
    final label = _actionLabel(action, ar);
    final confirmed = await confirmAction(
      context,
      title: label,
      message: ar
          ? 'سيتم إرسال العملية مباشرة إلى السيرفر. هل تريد المتابعة؟'
          : 'This action will be sent directly to the server. Continue?',
      confirmLabel: label,
      destructive: action == 'reject' || action == 'fail',
    );
    if (!confirmed || !mounted) return;
    String? reason;
    if (action == 'fail') {
      reason = await _failureReason();
      if (reason == null || !mounted) return;
    }
    // Contactless orders require a server-validated OTP/QR proof. We never
    // guess the code or bypass verification; standard deliveries can be
    // confirmed without a code when permitted by the backend.
    String? numericCode;
    if (action == 'deliver') {
      numericCode = await _deliveryProofCode();
      if (numericCode == null || !mounted) return;
    }
    setState(() => _acting = true);
    try {
      await ref
          .read(driverApiProvider)
          .changeShipmentStatus(
            shipment.id,
            action,
            reason: reason,
            numericCode: numericCode?.isEmpty == true ? null : numericCode,
          );
      ref.invalidate(shipmentsProvider);
      ref.invalidate(shipmentDetailsProvider(widget.shipmentId));
      ref.invalidate(shipmentTrackingProvider(widget.shipmentId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ar ? 'تم تحديث الشحنة بنجاح' : 'Shipment updated'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<String?> _deliveryProofCode() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إثبات تسليم الشحنة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'أدخل رمز الاستلام الذي يظهر للعميل إن كانت الشحنة بدون تلامس. '
              'اتركه فارغًا فقط إذا كان التسليم عاديًا؛ السيرفر يتحقق من نوع الشحنة.',
            ),
            const SizedBox(height: 14),
            TextField(
              key: const Key('deliveryNumericCodeField'),
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(labelText: 'رمز التحقق (إن لزم)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('تأكيد التسليم'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<String?> _failureReason() async {
    final controller = TextEditingController();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          2,
          22,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'سبب تعذر التسليم',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 13),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'مثال: العميل غير متاح أو تعذر الوصول للموقع',
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) Navigator.pop(context, value);
              },
              child: const Text('إرسال البلاغ'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _sendLocation(Shipment shipment) async {
    final ar = isArabic(context);
    setState(() => _sendingLocation = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(ar ? 'إذن الموقع مرفوض' : 'Location permission denied');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      await ref
          .read(driverApiProvider)
          .updateLocation(
            shipment.id,
            latitude: position.latitude,
            longitude: position.longitude,
            heading: position.heading,
            speedKph: position.speed * 3.6,
            accuracyMeters: position.accuracy,
          );
      ref.invalidate(shipmentTrackingProvider(widget.shipmentId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ar ? 'تم تحديث موقع الشحنة' : 'Location updated'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _sendingLocation = false);
    }
  }

  Future<void> _openNavigation(Shipment shipment) async {
    final target =
        shipment.status == ShipmentStatus.assigned ||
            shipment.status == ShipmentStatus.accepted
        ? shipment.storeLocation
        : shipment.customerLocation;
    if (target == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('إحداثيات الوجهة غير متاحة من السيرفر.')),
      );
      return;
    }
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${target.latitude},${target.longitude}&travelmode=driving',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر فتح تطبيق الملاحة.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    final details = ref.watch(shipmentDetailsProvider(widget.shipmentId));
    final tracking = ref.watch(shipmentTrackingProvider(widget.shipmentId));
    return Scaffold(
      appBar: AppBar(
        title: Text(ar ? 'تفاصيل الشحنة' : 'Shipment details'),
        actions: [
          IconButton(
            onPressed: () {
              ref.invalidate(shipmentDetailsProvider(widget.shipmentId));
              ref.invalidate(shipmentTrackingProvider(widget.shipmentId));
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: details.when(
        loading: LoadingList.new,
        error: (error, _) => ErrorState(
          error: error,
          onRetry: () =>
              ref.invalidate(shipmentDetailsProvider(widget.shipmentId)),
        ),
        data: (shipment) {
          final tracked = tracking.valueOrNull;
          final mapShipment = tracked ?? shipment;
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shipment.number,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          '${ar ? 'الطلب' : 'Order'} #${shipment.orderId}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  StatusPill(
                    label: shipment.status.label(ar),
                    color: _statusColor(shipment.status),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              MapPanel(
                driver: mapShipment.driverLocation,
                store: shipment.storeLocation ?? mapShipment.storeLocation,
                customer:
                    shipment.customerLocation ?? mapShipment.customerLocation,
                height: 285,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: shipment.status.isClosed
                          ? null
                          : () => _openNavigation(shipment),
                      icon: const Icon(Icons.navigation_rounded),
                      label: Text(ar ? 'فتح الملاحة' : 'Navigate'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: shipment.status.isClosed || _sendingLocation
                          ? null
                          : () => _sendLocation(shipment),
                      icon: _sendingLocation
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location_rounded),
                      label: Text(ar ? 'تحديث الموقع' : 'Update location'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SectionHeader(
                title: ar ? 'معلومات الرحلة' : 'Trip information',
                icon: Icons.route_outlined,
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.straighten_rounded,
                        label: ar ? 'المسافة التقديرية' : 'Estimated distance',
                        value: formatDistance(
                          mapShipment.distanceKm,
                          arabic: ar,
                        ),
                      ),
                      const Divider(height: 22),
                      _InfoRow(
                        icon: Icons.schedule_rounded,
                        label: ar ? 'الوقت المتوقع' : 'Estimated time',
                        value: formatEta(mapShipment.etaMinutes, arabic: ar),
                      ),
                      const Divider(height: 22),
                      _InfoRow(
                        icon: Icons.payments_outlined,
                        label: ar ? 'رسوم التوصيل' : 'Delivery fee',
                        value: formatMoney(
                          shipment.deliveryFee,
                          'SAR',
                          locale: ar ? 'ar' : 'en',
                        ),
                      ),
                      const Divider(height: 22),
                      _InfoRow(
                        icon: Icons.local_gas_station_outlined,
                        label: ar ? 'تكلفة النقل' : 'Transport cost',
                        value: formatMoney(
                          shipment.transportCost,
                          'SAR',
                          locale: ar ? 'ar' : 'en',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ar
                    ? 'القيم المالية أعلاه حقول الشحنة من السيرفر، وليست بالضرورة مستحقات السائق.'
                    : 'Financial values above are shipment fields from the server and are not necessarily driver earnings.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              SectionHeader(
                title: ar ? 'تقدم الشحنة' : 'Shipment progress',
                icon: Icons.timeline_rounded,
              ),
              const SizedBox(height: 10),
              _ShipmentTimeline(status: shipment.status),
              const SizedBox(height: 22),
              ..._actionButtons(shipment, ar),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _actionButtons(Shipment shipment, bool ar) {
    if (_acting) {
      return const [Center(child: CircularProgressIndicator())];
    }
    final actions = <String>[];
    switch (shipment.status) {
      case ShipmentStatus.assigned:
        actions.addAll(['accept', 'reject']);
        break;
      case ShipmentStatus.accepted:
        actions.addAll(['pickup', 'reject']);
        break;
      case ShipmentStatus.inTransit:
        actions.addAll(['near-customer', 'fail']);
        break;
      case ShipmentStatus.nearCustomer:
        actions.addAll(['deliver', 'fail']);
        break;
      case ShipmentStatus.pickedUp:
        actions.addAll(['depart', 'fail']);
        break;
      case ShipmentStatus.pending:
      case ShipmentStatus.delivered:
      case ShipmentStatus.cancelled:
      case ShipmentStatus.failed:
      case ShipmentStatus.unknown:
        break;
    }
    if (actions.isEmpty) return const [];
    return actions.map((action) {
      final secondary = action == 'reject' || action == 'fail';
      final button = secondary
          ? OutlinedButton.icon(
              onPressed: () => _runAction(action, shipment),
              icon: Icon(
                action == 'fail'
                    ? Icons.report_problem_outlined
                    : Icons.close_rounded,
              ),
              label: Text(_actionLabel(action, ar)),
            )
          : FilledButton.icon(
              onPressed: () => _runAction(action, shipment),
              icon: Icon(_actionIcon(action)),
              label: Text(_actionLabel(action, ar)),
            );
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: SizedBox(width: double.infinity, child: button),
      );
    }).toList();
  }
}

class _TinyInfo extends StatelessWidget {
  const _TinyInfo({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 11),
        Expanded(child: Text(label)),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _ShipmentTimeline extends StatelessWidget {
  const _ShipmentTimeline({required this.status});
  final ShipmentStatus status;

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    const normal = [
      ShipmentStatus.assigned,
      ShipmentStatus.accepted,
      ShipmentStatus.pickedUp,
      ShipmentStatus.inTransit,
      ShipmentStatus.nearCustomer,
      ShipmentStatus.delivered,
    ];
    final current = normal.indexOf(status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (var i = 0; i < normal.length; i++)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: i <= current
                              ? MazraaColors.forest
                              : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          i < current ? Icons.check_rounded : Icons.circle,
                          color: i <= current
                              ? Colors.white
                              : Theme.of(context).colorScheme.outline,
                          size: i < current ? 16 : 7,
                        ),
                      ),
                      if (i != normal.length - 1)
                        Container(
                          width: 2,
                          height: 28,
                          color: i < current
                              ? MazraaColors.forest
                              : Theme.of(context).colorScheme.outlineVariant,
                        ),
                    ],
                  ),
                  const SizedBox(width: 11),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      normal[i].label(ar),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: i == current ? FontWeight.w800 : null,
                        color: i <= current
                            ? null
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            if (status == ShipmentStatus.failed ||
                status == ShipmentStatus.cancelled)
              StatusPill(
                label: status.label(ar),
                color: Theme.of(context).colorScheme.error,
              ),
          ],
        ),
      ),
    );
  }
}

Color _statusColor(ShipmentStatus status) => switch (status) {
  ShipmentStatus.delivered => MazraaColors.success,
  ShipmentStatus.failed || ShipmentStatus.cancelled => MazraaColors.danger,
  ShipmentStatus.assigned || ShipmentStatus.accepted => MazraaColors.orange,
  ShipmentStatus.pickedUp ||
  ShipmentStatus.inTransit ||
  ShipmentStatus.nearCustomer => MazraaColors.forest,
  _ => MazraaColors.warning,
};

String _actionLabel(String action, bool ar) => switch (action) {
  'accept' => ar ? 'قبول الشحنة' : 'Accept shipment',
  'reject' => ar ? 'رفض الشحنة' : 'Reject shipment',
  'pickup' => ar ? 'تأكيد الاستلام' : 'Confirm pickup',
  'depart' => ar ? 'بدأت التوصيل' : 'Depart for customer',
  'near-customer' => ar ? 'أنا قريب من العميل' : 'Near customer',
  'deliver' => ar ? 'تأكيد التسليم' : 'Confirm delivery',
  'fail' => ar ? 'تعذر التسليم' : 'Report failure',
  _ => action,
};

IconData _actionIcon(String action) => switch (action) {
  'accept' => Icons.check_circle_outline_rounded,
  'pickup' => Icons.inventory_2_outlined,
  'depart' => Icons.route_rounded,
  'near-customer' => Icons.near_me_outlined,
  'deliver' => Icons.task_alt_rounded,
  _ => Icons.arrow_forward_rounded,
};
