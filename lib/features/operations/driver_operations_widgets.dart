import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
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
              ? (ar
                    ? 'بدء استقبال عروض التوصيل؟'
                    : 'Start accepting delivery offers?')
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
      Position? point;
      if (online || startShift == true) {
        if (!await Geolocator.isLocationServiceEnabled())
          throw StateError(
            ar
                ? 'فعّل الموقع لاستلام العروض القريبة.'
                : 'Enable location to receive nearby offers.',
          );
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied)
          permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever)
          throw StateError(
            ar ? 'إذن الموقع مطلوب.' : 'Location permission required.',
          );
        point = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 15),
          ),
        );
      }
      if (startShift == true) {
        await api.startShift(
          latitude: point?.latitude,
          longitude: point?.longitude,
        );
      } else if (startShift == false) {
        await api.endShift();
      } else {
        await api.updateDriverStatus(
          operationalStatus: online ? 3 : 1,
          isAcceptingOrders: online,
          latitude: point?.latitude,
          longitude: point?.longitude,
        );
      }
      ref.invalidate(driverJourneyProvider);
      ref.invalidate(driverShiftsProvider);
      ref.invalidate(driverOffersProvider);
      await ref.read(authControllerProvider).refreshProfile();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
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
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => Card(
        child: ListTile(
          leading: const Icon(Icons.cloud_off_outlined),
          title: Text(
            ar ? 'تعذر تحديث حالة السائق' : 'Cannot load driver status',
          ),
          subtitle: Text(error.toString(), maxLines: 2),
          trailing: IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(driverJourneyProvider),
          ),
        ),
      ),
      data: (data) {
        final driver = data['driver'] is Map ? data['driver'] as Map : const {};
        final status = driver['approvalStatus']?.toString().toLowerCase() ?? '';
        final isApproved = status == '2' || status == 'approved';
        final verified = driver['isVerified'] == true;
        final canWork = isApproved && verified;
        final online = driver['isAcceptingOrders'] == true;
        final shift = data['openShift'] is Map
            ? data['openShift'] as Map
            : null;
        final activeShift = shift != null;
        final scheme = Theme.of(context).colorScheme;
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Image.asset(
                        ReferenceAssets.deliveryScooter,
                        cacheWidth: 180,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ar ? 'حالة العمل' : 'Driver availability',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            canWork
                                ? (online
                                      ? (ar
                                            ? 'متاح لاستلام الطلبات'
                                            : 'Available for orders')
                                      : (ar
                                            ? 'غير متصل حاليًا'
                                            : 'Currently offline'))
                                : (ar
                                      ? 'الحساب ينتظر الاعتماد والتحقق'
                                      : 'Approval and verification required'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: online,
                      onChanged: busy || !canWork
                          ? null
                          : (value) => _change(online: value),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        activeShift
                            ? (ar ? 'الوردية نشطة' : 'Shift is active')
                            : (ar ? 'لم تبدأ وردية' : 'No active shift'),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: busy || !canWork
                          ? null
                          : () => _change(
                              online: !activeShift,
                              startShift: !activeShift,
                            ),
                      icon: Icon(
                        activeShift
                            ? Icons.stop_circle_outlined
                            : Icons.play_circle_outline,
                      ),
                      label: Text(
                        activeShift
                            ? (ar ? 'إنهاء الوردية' : 'End shift')
                            : (ar ? 'بدء الوردية' : 'Start shift'),
                      ),
                    ),
                  ],
                ),
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

class _DriverOfferListState extends ConsumerState<DriverOfferList>
    with WidgetsBindingObserver {
  int? pendingId;
  Timer? _countdownTimer;
  DateTime _now = DateTime.now().toUtc();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The offer expiry is server-owned; only the countdown clock is local.
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now().toUtc());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        setState(() => _now = DateTime.now().toUtc());
        ref.invalidate(driverOffersProvider);
      }
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _take(DriverOffer offer, {required bool accept}) async {
    if (pendingId != null) return;
    if (!offer.expiresAt.isAfter(DateTime.now().toUtc())) {
      ref.invalidate(driverOffersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('انتهت مهلة العرض. جارٍ تحديث العروض من السيرفر.'),
          ),
        );
      }
      return;
    }
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
    // The confirmation dialog may be open past the expiry time.
    if (!offer.expiresAt.isAfter(DateTime.now().toUtc())) {
      ref.invalidate(driverOffersProvider);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('انتهت مهلة قبول العرض.')));
      return;
    }
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
        ref.invalidate(driverOffersProvider);
      }
    } finally {
      if (mounted) setState(() => pendingId = null);
    }
  }

  Future<void> _showOfferDetails(DriverOffer offer) async {
    final ar = isArabic(context);
    if (!offer.expiresAt.isAfter(DateTime.now().toUtc())) {
      ref.invalidate(driverOffersProvider);
      return;
    }
    try {
      final details = await ref
          .read(driverApiProvider)
          .getOfferDetails(offer.id);
      if (!mounted) return;
      final rawItems = details['items'];
      final items = rawItems is List
          ? rawItems.whereType<Map>().toList()
          : <Map>[];
      final payment = details['payment'] is Map
          ? details['payment'] as Map
          : const {};
      final terms = details['deliveryTerms'] is Map
          ? details['deliveryTerms'] as Map
          : const {};
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(ar ? 'تفاصيل عرض التوصيل' : 'Delivery offer details'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  details['shipmentNumber']?.toString() ?? offer.shipmentNumber,
                ),
                const SizedBox(height: 8),
                if (terms['dropoffName'] != null)
                  Text(
                    '${ar ? 'نقطة التسليم' : 'Drop-off'}: ${terms['dropoffName']}',
                  ),
                if (terms['plannedDepartureAt'] != null)
                  Text(
                    '${ar ? 'انطلاق الرحلة' : 'Departure'}: ${DateTime.tryParse('${terms['plannedDepartureAt']}')?.toLocal() ?? terms['plannedDepartureAt']}',
                  ),
                if (details['deliveryFee'] != null)
                  Text(
                    '${ar ? 'رسوم التوصيل' : 'Delivery charge'}: ${details['deliveryFee']} ${terms['currency'] ?? ''}',
                  ),
                Text(
                  ar
                      ? 'المنتجات والكمية الفعلية:'
                      : 'Actual products and quantities:',
                ),
                if (items.isEmpty)
                  Text(
                    ar
                        ? 'لا توجد بنود متاحة للعرض.'
                        : 'No item details available.',
                  ),
                for (final item in items)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      item['productName']?.toString() ??
                          item['sku']?.toString() ??
                          '—',
                    ),
                    subtitle: Text('SKU: ${item['sku'] ?? '—'}'),
                    trailing: Text('× ${item['quantity'] ?? '—'}'),
                  ),
                const Divider(),
                Text(
                  payment['requiresCashCollection'] == true
                      ? (ar
                            ? 'تحصيل عند التسليم: ${payment['amountToCollect']} ${payment['currency'] ?? ''}'
                            : 'Collect on delivery: ${payment['amountToCollect']} ${payment['currency'] ?? ''}')
                      : (ar
                            ? 'لا يوجد تحصيل نقدي عند التسليم.'
                            : 'No cash collection at delivery.'),
                ),
                const SizedBox(height: 8),
                Text(
                  ar
                      ? 'انتهاء العرض: ${offer.expiresAt.toLocal()}'
                      : 'Offer expires: ${offer.expiresAt.toLocal()}',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(ar ? 'إغلاق' : 'Close'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ref.invalidate(driverOffersProvider);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    final offers = ref.watch(driverOffersProvider);
    return offers.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Card(
        child: ListTile(
          leading: const Icon(Icons.wifi_off_outlined),
          title: Text(ar ? 'تعذر تحميل العروض' : 'Could not load offers'),
          subtitle: Text(error.toString(), maxLines: 2),
          trailing: IconButton(
            onPressed: () => ref.invalidate(driverOffersProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Image.asset(
                    ReferenceAssets.deliveryTote,
                    height: 92,
                    cacheWidth: 220,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ar ? 'لا توجد عروض حاليًا' : 'No available offers',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    ar ? 'ستظهر العروض الجديدة هنا عند إرسالها إلى حسابك.' : 'New dispatch offers will appear here when assigned to your account.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        }
        final unexpired = items
            .where((offer) => offer.expiresAt.isAfter(_now))
            .toList();
        final visible = widget.compact ? unexpired.take(2).toList() : unexpired;
        return Column(
          children: [
            for (final offer in visible)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_shipping_outlined),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                offer.shipmentNumber,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Text(
                              ar ? 'عرض جديد' : 'New offer',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          offer.distanceToPickupKm == null
                              ? (ar
                                    ? 'المسافة غير متاحة'
                                    : 'Distance unavailable')
                              : (ar
                                    ? 'يبعد الاستلام ${offer.distanceToPickupKm!.toStringAsFixed(1)} كم'
                                    : 'Pickup ${offer.distanceToPickupKm!.toStringAsFixed(1)} km away'),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${ar ? 'ينتهي' : 'Expires'}: ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(offer.expiresAt.toLocal()))}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Builder(
                          builder: (context) {
                            final seconds = offer.expiresAt
                                .difference(_now)
                                .inSeconds;
                            final time = Duration(
                              seconds: seconds > 0 ? seconds : 0,
                            );
                            final remaining =
                                '${time.inMinutes.toString().padLeft(2, '0')}:${(time.inSeconds % 60).toString().padLeft(2, '0')}';
                            return Semantics(
                              liveRegion: false,
                              label: ar
                                  ? 'مهلة قبول العرض $remaining'
                                  : 'Offer expires in $remaining',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.timer_outlined,
                                    size: 18,
                                    color: seconds <= 15
                                        ? Theme.of(context).colorScheme.error
                                        : Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    ar
                                        ? 'متبقي $remaining'
                                        : '$remaining remaining',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: seconds <= 15
                                              ? Theme.of(context)
                                                    .colorScheme
                                                    .error
                                              : Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                        ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: pendingId != null
                              ? null
                              : () => _showOfferDetails(offer),
                          icon: const Icon(Icons.inventory_2_outlined),
                          label: Text(
                            ar
                                ? 'تفاصيل المنتجات والرحلة'
                                : 'Review items and trip',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: pendingId != null
                                    ? null
                                    : () => _take(offer, accept: false),
                                child: Text(ar ? 'رفض' : 'Decline'),
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: FilledButton(
                                onPressed: pendingId != null
                                    ? null
                                    : () => _take(offer, accept: true),
                                child: pendingId == offer.id
                                    ? const SizedBox(
                                        width: 19,
                                        height: 19,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(ar ? 'قبول' : 'Accept'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
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
