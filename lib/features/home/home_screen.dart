import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/core/network/providers.dart';
import 'package:mazraa_driver/core/theme/app_theme.dart';
import 'package:mazraa_driver/core/utils/formatters.dart';
import 'package:mazraa_driver/features/auth/auth_controller.dart';
import 'package:mazraa_driver/features/shipments/shipment_providers.dart';
import 'package:mazraa_driver/features/wallet/wallet_providers.dart';
import 'package:mazraa_driver/shared/widgets/map_panel.dart';
import 'package:mazraa_driver/shared/widgets/mazraa_widgets.dart';

final connectionProvider = FutureProvider<bool>((ref) async {
  final result = await Connectivity().checkConnectivity();
  return !result.contains(ConnectivityResult.none);
});

final currentPositionProvider = FutureProvider<Position>((ref) async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw Exception('خدمة الموقع متوقفة على الجهاز.');
  }
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw Exception('لم يتم منح إذن الموقع.');
  }
  return Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 15),
    ),
  );
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(shipmentsProvider);
    ref.invalidate(walletSummaryProvider);
    ref.invalidate(connectionProvider);
    ref.invalidate(currentPositionProvider);
    await Future.wait([
      ref.read(shipmentsProvider.future),
      ref.read(walletSummaryProvider.future),
      // A newly approved driver must be able to go online without signing
      // out and in again. The backend remains authoritative.
      ref.read(authControllerProvider).refreshProfile(),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ar = isArabic(context);
    final auth = ref.watch(authControllerProvider);
    final shipments = ref.watch(shipmentsProvider);
    final wallet = ref.watch(walletSummaryProvider);
    final connection = ref.watch(connectionProvider);
    final position = ref.watch(currentPositionProvider);
    final profile = auth.profile;
    final shipmentRows = shipments.valueOrNull ?? const <Shipment>[];
    final active = shipmentRows.where((item) => item.status.isActive).toList();
    final completedToday = shipmentRows.where((item) {
      final now = DateTime.now();
      final deliveredAt = item.deliveredAt?.toLocal();
      return item.status == ShipmentStatus.delivered &&
          deliveredAt != null &&
          deliveredAt.year == now.year &&
          deliveredAt.month == now.month &&
          deliveredAt.day == now.day;
    }).length;
    final currentPoint = position.valueOrNull == null
        ? (profile?.currentLatitude != null && profile?.currentLongitude != null
              ? GeoPoint(profile!.currentLatitude!, profile.currentLongitude!)
              : null)
        : GeoPoint(
            position.valueOrNull!.latitude,
            position.valueOrNull!.longitude,
          );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                sliver: SliverList.list(
                  children: [
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/branding/mazraa_mark.svg',
                          width: 45,
                          height: 52,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ar ? 'صباح الخير' : 'Good morning',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              Text(
                                profile?.name ??
                                    (ar ? 'سائق مزرعتي' : 'Mazraa driver'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: ar ? 'الإشعارات' : 'Notifications',
                          onPressed: () => context.go('/notifications'),
                          icon: const Icon(Icons.notifications_none_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _StatusBanner(
                      profile: profile,
                      connected: connection.valueOrNull,
                      location: currentPoint,
                    ),
                    const SizedBox(height: 15),
                    MapPanel(
                      driver: currentPoint,
                      store: active.isEmpty ? null : active.first.storeLocation,
                      customer: active.isEmpty
                          ? null
                          : active.first.customerLocation,
                      onLocate: () => ref.invalidate(currentPositionProvider),
                    ),
                    const SizedBox(height: 18),
                    if (active.isNotEmpty) ...[
                      SectionHeader(
                        title: ar ? 'المهمة الجارية' : 'Current mission',
                        icon: Icons.route_rounded,
                        action: TextButton(
                          onPressed: () =>
                              context.push('/shipments/${active.first.id}'),
                          child: Text(ar ? 'عرض التفاصيل' : 'View'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _ActiveShipmentCard(shipment: active.first),
                      const SizedBox(height: 20),
                    ],
                    SectionHeader(
                      title: ar ? 'ملخص اليوم' : "Today's summary",
                      icon: Icons.insights_rounded,
                    ),
                    const SizedBox(height: 11),
                    SizedBox(
                      height: 132,
                      child: Row(
                        children: [
                          Expanded(
                            child: MetricCard(
                              title: ar ? 'رحلات مكتملة' : 'Completed',
                              value: '$completedToday',
                              icon: Icons.task_alt_rounded,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: MetricCard(
                              title: ar ? 'شحنات نشطة' : 'Active',
                              value: '${active.length}',
                              icon: Icons.local_shipping_rounded,
                              accent: MazraaColors.orange,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: MetricCard(
                              title: ar ? 'رصيد المحفظة' : 'Wallet balance',
                              value: wallet.when(
                                data: (data) => formatMoney(
                                  data.balance,
                                  data.currency,
                                  locale: ar ? 'ar' : 'en',
                                ),
                                loading: () => '—',
                                error: (_, _) => '—',
                              ),
                              icon: Icons.account_balance_wallet_rounded,
                              accent: MazraaColors.leaf,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SectionHeader(
                      title: ar ? 'وصول سريع' : 'Quick access',
                      icon: Icons.grid_view_rounded,
                    ),
                    const SizedBox(height: 11),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.local_shipping_outlined,
                            label: ar ? 'الشحنات' : 'Shipments',
                            onTap: () => context.go('/shipments'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.account_balance_wallet_outlined,
                            label: ar ? 'المحفظة' : 'Wallet',
                            onTap: () => context.go('/wallet'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.support_agent_rounded,
                            label: ar ? 'المساعدة' : 'Support',
                            onTap: () => context.push('/support'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends ConsumerStatefulWidget {
  const _StatusBanner({
    required this.profile,
    required this.connected,
    required this.location,
  });
  final DriverProfile? profile;
  final bool? connected;
  final GeoPoint? location;

  @override
  ConsumerState<_StatusBanner> createState() => _StatusBannerState();
}

class _StatusBannerState extends ConsumerState<_StatusBanner> {
  bool _saving = false;

  Future<void> _toggle() async {
    final profile = widget.profile;
    if (profile == null || _saving) return;
    if (!profile.isApproved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن بدء استقبال الطلبات قبل اعتماد حساب السائق.')),
      );
      return;
    }
    final online = profile.operationalStatus.toLowerCase() != 'offline' &&
        profile.operationalStatus.toLowerCase() != 'unknown';
    setState(() => _saving = true);
    try {
      await ref.read(driverApiProvider).updateDriverStatus(
        operationalStatus: online ? 1 : 2,
        isAcceptingOrders: !online,
        latitude: widget.location?.latitude,
        longitude: widget.location?.longitude,
      );
      await ref.read(authControllerProvider).refreshProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(online ? 'أصبحت غير متصل' : 'أصبحت متصلًا ومستعدًا لاستقبال الطلبات')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final ar = isArabic(context);
    final online = profile != null &&
        profile.operationalStatus.toLowerCase() != 'offline' &&
        profile.operationalStatus.toLowerCase() != 'unknown';
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [MazraaColors.forest, MazraaColors.forestDark],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: MazraaColors.forest.withValues(alpha: .18),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 47,
            height: 47,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              online ? Icons.sensors_rounded : Icons.power_settings_new_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  online
                      ? (ar ? 'أنت متصل' : 'You are online')
                      : (ar ? 'حالتك الحالية: غير متصل' : 'Currently offline'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  profile?.isApproved == false
                      ? (ar ? 'بانتظار اعتماد حساب السائق' : 'Awaiting driver approval')
                      : (ar ? 'اضغط لتغيير حالة استقبال الطلبات' : 'Change order availability'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          if (_saving)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          else
            Switch(
              key: const Key('driverLiveStatusSwitch'),
              value: online,
              onChanged: widget.connected == false || profile == null || !profile.isApproved
                  ? null
                  : (_) => _toggle(),
            ),
          if (widget.connected == false) ...[
            const SizedBox(width: 4),
            const Icon(Icons.wifi_off_rounded, color: Color(0xFFFFB09A)),
          ],
        ],
      ),
    );
  }
}

class _ActiveShipmentCard extends StatelessWidget {
  const _ActiveShipmentCard({required this.shipment});
  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => context.push('/shipments/${shipment.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: MazraaColors.orange.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.route_rounded,
                  color: MazraaColors.orange,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shipment.number,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${ar ? 'الطلب' : 'Order'} #${shipment.orderId}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: shipment.status.label(ar),
                color: MazraaColors.orange,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
