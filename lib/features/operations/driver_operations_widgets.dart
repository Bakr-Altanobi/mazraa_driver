import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mazraa_driver/core/network/providers.dart';
import 'package:mazraa_driver/features/auth/auth_controller.dart';
import 'package:mazraa_driver/features/operations/driver_live_providers.dart';
import 'package:mazraa_driver/features/reference_journey/reference_assets.dart';
import 'package:mazraa_driver/features/shipments/shipment_providers.dart';
import 'package:mazraa_driver/shared/widgets/mazraa_widgets.dart';

/// Driver status and shift actions are backed by driver-journey endpoints.
class DriverControlPanel extends ConsumerStatefulWidget {
  const DriverControlPanel({super.key});

  @override
  ConsumerState<DriverControlPanel> createState() => _DriverControlPanelState();
}

class _DriverControlPanelState extends ConsumerState<DriverControlPanel> {
  bool busy = false;

  Future<void> _change({required bool online, bool? startShift}) async {
    if (busy) return;
    final ar = isArabic(context);
    final message = startShift == null
        ? (online
            ? (ar ? 'بدء استقبال عروض التوصيل؟' : 'Start accepting delivery offers?')
            : (ar ? 'إيقاف استقبال العروض؟' : 'Stop accepting offers?'))
        : (startShift
            ? (ar ? 'بدء وردية جديدة الآن؟' : 'Start a new shift?')
            : (ar ? 'إنهاء الوردية الحالية؟' : 'End your current shift?'));
    final confirmed = await confirmAction(
      context,
      title: ar ? 'تأكيد حالة العمل' : 'Confirm work status',
      message: message,
      confirmLabel: ar ? 'تأكيد' : 'Confirm',
    );
    if (!confirmed || !mounted) return;
    setState(() => busy = true);
    try {
      final api = ref.read(driverApiProvider);
      if (startShift == true) {
        await api.startShift();
      } else if (startShift == false) {
        await api.endShift();
      } else {
        await api.updateDriverStatus(
          operationalStatus: online ? 3 : 1,
          isAcceptingOrders: online,
        );
      }
      ref.invalidate(driverJourneyProvider);
      ref.invalidate(driverShiftsProvider);
      ref.invalidate(driverOffersProvider);
      await ref.read(authControllerProvider).refreshProfile();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    final journey = ref.watch(driverJourneyProvider);
    return journey.when(
      loading: () => const Card(child: Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      )),
      error: (error, _) => Card(child: ListTile(
        leading: const Icon(Icons.cloud_off_outlined),
        title: Text(ar ? 'تعذر تحديث حالة السائق' : 'Cannot load driver status'),
        subtitle: Text(error.toString(), maxLines: 2),
        trailing: IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => ref.invalidate(driverJourneyProvider),
        ),
      )),
      data: (data) {
        final driver = data['driver'] is Map ? data['driver'] as Map : const {};
        final status = driver['approvalStatus']?.toString().toLowerCase() ?? '';
        final isApproved = status == '2' || status == 'approved';
        final verified = driver['isVerified'] == true;
        final canWork = isApproved && verified;
        final online = driver['isAcceptingOrders'] == true;
        final shift = data['openShift'] is Map ? data['openShift'] as Map : null;
        final activeShift = shift != null;
        final scheme = Theme.of(context).colorScheme;
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 50,
                    height: 50,
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.asset(ReferenceAssets.deliveryScooter, cacheWidth: 180),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ar ? 'حالة العمل' : 'Driver availability',
                        style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        canWork
                            ? (online
                                ? (ar ? 'متاح لاستلام الطلبات' : 'Available for orders')
                                : (ar ? 'غير متصل حاليًا' : 'Currently offline'))
                            : (ar ? 'الحساب ينتظر الاعتماد والتحقق' : 'Approval and verification required'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  )),
                  Switch.adaptive(
                    value: online,
                    onChanged: busy || !canWork ? null : (value) => _change(online: value),
                  ),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: Text(
                    activeShift
                        ? (ar ? 'الوردية نشطة' : 'Shift is active')
                        : (ar ? 'لم تبدأ وردية' : 'No active shift'),
                    style: Theme.of(context).textTheme.labelLarge,
                  )),
                  OutlinedButton.icon(
                    onPressed: busy || !canWork
                        ? null
                        : () => _change(online: !activeShift, startShift: !activeShift),
                    icon: Icon(activeShift ? Icons.stop_circle_outlined : Icons.play_circle_outline),
                    label: Text(activeShift
                        ? (ar ? 'إنهاء الوردية' : 'End shift')
                        : (ar ? 'بدء الوردية' : 'Start shift')),
                  ),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }
}

class DriverOfferList extends ConsumerStatefulWidget {
  const DriverOfferList({this.compact = false, super.key});
  final bool compact;

  @override
  ConsumerState<DriverOfferList> createState() => _DriverOfferListState();
}

class _DriverOfferListState extends ConsumerState<DriverOfferList> {
  int? pendingId;

  Future<void> _take(DriverOffer offer, {required bool accept}) async {
    if (pendingId != null) return;
    final ar = isArabic(context);
    final verb = accept
        ? (ar ? 'قبول العرض' : 'Accept offer')
        : (ar ? 'رفض العرض' : 'Reject offer');
    final ok = await confirmAction(
      context,
      title: verb,
      message: ar
          ? 'الشحنة ${offer.shipmentNumber} — سيتم إرسال قرارك للسيرفر.'
          : 'Shipment ${offer.shipmentNumber} — send your decision to the server?',
      confirmLabel: verb,
      destructive: !accept,
    );
    if (!ok || !mounted) return;
    setState(() => pendingId = offer.id);
    try {
      if (accept) {
        await ref.read(driverApiProvider).acceptOffer(offer.id);
      } else {
        await ref.read(driverApiProvider).rejectOffer(offer.id);
      }
      ref.invalidate(driverOffersProvider);
      ref.invalidate(shipmentsProvider);
      if (mounted && accept) context.push('/shipments/${offer.shipmentId}');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
        ref.invalidate(driverOffersProvider);
      }
    } finally {
      if (mounted) setState(() => pendingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    final offers = ref.watch(driverOffersProvider);
    return offers.when(
      loading: () => const Center(child: Padding(
        padding: EdgeInsets.all(28),
        child: CircularProgressIndicator(),
      )),
      error: (error, _) => Card(child: ListTile(
        leading: const Icon(Icons.wifi_off_outlined),
        title: Text(ar ? 'تعذر تحميل العروض' : 'Could not load offers'),
        subtitle: Text(error.toString(), maxLines: 2),
        trailing: IconButton(
          onPressed: () => ref.invalidate(driverOffersProvider),
          icon: const Icon(Icons.refresh_rounded),
        ),
      )),
      data: (items) {
        if (items.isEmpty) {
          return Card(child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Image.asset(ReferenceAssets.deliveryTote, height: 92, cacheWidth: 220),
              const SizedBox(height: 8),
              Text(ar ? 'لا توجد عروض حاليًا' : 'No available offers',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 5),
              Text(
                ar ? 'ستظهر العروض الجديدة هنا عند إرسالها إلى حسابك.'
                   : 'New dispatch offers will appear here when assigned to your account.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ]),
          ));
        }
        final visible = widget.compact ? items.take(2).toList() : items;
        return Column(children: [
          for (final offer in visible) Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.local_shipping_outlined),
                    const SizedBox(width: 9),
                    Expanded(child: Text(offer.shipmentNumber,
                        style: Theme.of(context).textTheme.titleMedium)),
                    Text(
                      ar ? 'عرض جديد' : 'New offer',
                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Text(
                    offer.distanceToPickupKm == null
                        ? (ar ? 'المسافة غير متاحة' : 'Distance unavailable')
                        : (ar ? 'يبعد الاستلام ${offer.distanceToPickupKm!.toStringAsFixed(1)} كم'
                            : 'Pickup ${offer.distanceToPickupKm!.toStringAsFixed(1)} km away'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${ar ? 'ينتهي' : 'Expires'}: ${MaterialLocalizations.of(context).formatTimeOfDay(
                       TimeOfDay.fromDateTime(offer.expiresAt.toLocal()))}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: OutlinedButton(
                      onPressed: pendingId != null ? null : () => _take(offer, accept: false),
                      child: Text(ar ? 'رفض' : 'Decline'),
                    )),
                    const SizedBox(width: 9),
                    Expanded(child: FilledButton(
                      onPressed: pendingId != null ? null : () => _take(offer, accept: true),
                      child: pendingId == offer.id
                          ? const SizedBox(width: 19, height: 19,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(ar ? 'قبول' : 'Accept'),
                    )),
                  ]),
                ]),
              ),
            ),
          ),
        ]);
      },
    );
  }
}

class DriverOffersScreen extends ConsumerWidget {
  const DriverOffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ar = isArabic(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(ar ? 'عروض التوصيل' : 'Delivery offers'),
        actions: [
          IconButton(
            tooltip: ar ? 'تحديث' : 'Refresh',
            onPressed: () => ref.invalidate(driverOffersProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(driverOffersProvider);
          await ref.read(driverOffersProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
          children: const [DriverOfferList()],
        ),
      ),
    );
  }
}
