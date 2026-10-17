import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/core/network/providers.dart';
import 'package:mazraa_driver/core/theme/app_theme.dart';
import 'package:mazraa_driver/features/auth/auth_controller.dart';
import 'package:mazraa_driver/features/notifications/notification_providers.dart';
import 'package:mazraa_driver/features/reference_journey/reference_assets.dart';
import 'package:mazraa_driver/features/shipments/shipment_providers.dart';
import 'package:mazraa_driver/features/wallet/wallet_providers.dart';
import 'package:mazraa_driver/shared/widgets/mazraa_widgets.dart';

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

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _statusBusy = false;
  bool _locationBusy = false;

  Future<void> _refresh() async {
    ref.invalidate(shipmentsProvider);
    ref.invalidate(walletSummaryProvider);
    ref.invalidate(unreadNotificationsProvider);
    await ref.read(authControllerProvider).refreshProfile();
    await Future.wait([
      ref.read(shipmentsProvider.future),
      ref.read(walletSummaryProvider.future),
      ref.read(unreadNotificationsProvider.future),
    ]);
  }

  Future<void> _toggleAvailability(DriverProfile profile) async {
    if (_statusBusy) return;
    setState(() => _statusBusy = true);
    try {
      Position? position;
      try {
        position = await ref.read(currentPositionProvider.future);
      } catch (_) {
        // Status updates are valid without coordinates; location is optional.
      }
      final nextAccepting = !profile.isAcceptingOrders;
      await ref.read(driverApiProvider).updateDriverStatus(
            operationalStatus: nextAccepting ? 3 : 1,
            isAcceptingOrders: nextAccepting,
            latitude: position?.latitude,
            longitude: position?.longitude,
          );
      await ref.read(authControllerProvider).refreshProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nextAccepting
                  ? 'أصبحت متاحًا لاستقبال الطلبات.'
                  : 'تم إيقاف استقبال الطلبات.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _statusBusy = false);
    }
  }

  Future<void> _sendCurrentLocation(Shipment? shipment) async {
    if (_locationBusy) return;
    if (shipment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد شحنة نشطة لتحديث موقعها الآن.')),
      );
      return;
    }
    setState(() => _locationBusy = true);
    try {
      ref.invalidate(currentPositionProvider);
      final position = await ref.read(currentPositionProvider.future);
      await ref.read(driverApiProvider).updateLocation(
            shipment.id,
            latitude: position.latitude,
            longitude: position.longitude,
            heading: position.heading.isFinite ? position.heading : null,
            speedKph: position.speed.isFinite ? position.speed * 3.6 : null,
            accuracyMeters: position.accuracy.isFinite ? position.accuracy : null,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث موقع الشحنة على السيرفر.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _locationBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    final auth = ref.watch(authControllerProvider);
    final shipmentsAsync = ref.watch(shipmentsProvider);
    final walletAsync = ref.watch(walletSummaryProvider);
    final unreadAsync = ref.watch(unreadNotificationsProvider);
    final profile = auth.profile;
    final shipments = shipmentsAsync.valueOrNull ?? const <Shipment>[];
    final active = shipments.where((item) => item.status.isActive).toList();
    final activeShipment = active.isEmpty ? null : active.first;
    final now = DateTime.now();
    final today = shipments.where((item) {
      final date = item.createdAt.toLocal();
      return date.year == now.year && date.month == now.month && date.day == now.day;
    }).toList();
    final todayIncome = today
        .where((item) => item.status == ShipmentStatus.delivered)
        .fold<double>(0, (sum, item) => sum + item.netProfit);
    final currency = walletAsync.valueOrNull?.currency ?? '';
    final name = _firstName(profile?.name, ar: ar);
    final accepting = profile?.isAcceptingOrders == true;
    final rating = profile?.ratingAverage ?? 0;
    final unread = unreadAsync.valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF5),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
            children: [
              _ReferenceHeader(
                unread: unread,
                onNotifications: () => context.go('/notifications'),
              ),
              const SizedBox(height: 18),
              Text(
                ar ? 'صباح الخير، $name' : 'Good morning, $name',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFF073C28),
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.6,
                    ),
              ),
              const SizedBox(height: 13),
              Align(
                alignment: Alignment.center,
                child: _AvailabilityPill(accepting: accepting),
              ),
              const SizedBox(height: 20),
              Text(
                ar ? 'جاهز لطلبك التالي؟' : 'Ready for your next order?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF073C28),
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Container(
                  width: 52,
                  height: 4,
                  decoration: BoxDecoration(
                    color: MazraaColors.orange,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _ReferenceMapCard(
                shipment: activeShipment,
                locating: _locationBusy,
                onLocate: () => _sendCurrentLocation(activeShipment),
                onDirections: activeShipment == null
                    ? null
                    : () => context.push('/shipments/${activeShipment.id}'),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _ReferenceMetricCard(
                      icon: Icons.shopping_bag_outlined,
                      iconColor: MazraaColors.orange,
                      label: ar ? 'طلبات اليوم' : "Today's orders",
                      value: '${today.length}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ReferenceMetricCard(
                      icon: Icons.toll_rounded,
                      iconColor: const Color(0xFF075C3D),
                      label: ar ? 'الدخل' : 'Income',
                      value: _incomeLabel(todayIncome, currency, ar: ar),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ReferenceMetricCard(
                      icon: Icons.star_rounded,
                      iconColor: MazraaColors.orange,
                      label: ar ? 'التقييم' : 'Rating',
                      value: rating <= 0 ? '—' : rating.toStringAsFixed(1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 68,
                child: FilledButton.icon(
                  onPressed: profile == null || _statusBusy
                      ? null
                      : () => _toggleAvailability(profile),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF075A35),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    elevation: 3,
                  ),
                  icon: _statusBusy
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.near_me_rounded, size: 29),
                  label: Text(
                    accepting
                        ? (ar ? 'إيقاف استقبال الطلبات' : 'Stop receiving orders')
                        : (ar ? 'ابدأ استقبال الطلبات' : 'Start receiving orders'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReferenceHeader extends StatelessWidget {
  const _ReferenceHeader({required this.unread, required this.onNotifications});

  final int unread;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    return SizedBox(
      height: 78,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_rounded, color: Color(0xFF075A35), size: 28),
                const SizedBox(width: 4),
                Text(
                  ar ? 'موقعي' : 'My location',
                  style: const TextStyle(
                    color: Color(0xFF174D39),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF075A35)),
              ],
            ),
          ),
          Image.asset(
            ReferenceAssets.brandLeaf,
            width: 66,
            height: 66,
            fit: BoxFit.contain,
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      tooltip: ar ? 'الإشعارات' : 'Notifications',
                      onPressed: onNotifications,
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        color: Color(0xFF075A35),
                        size: 31,
                      ),
                    ),
                    if (unread > 0)
                      PositionedDirectional(
                        top: 0,
                        end: 0,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: MazraaColors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unread > 99 ? '99+' : '$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 6),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE7E6DE)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x16000000),
                            blurRadius: 13,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          ReferenceAssets.driverAvatar,
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, -.45),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      end: -1,
                      bottom: 2,
                      child: Container(
                        width: 15,
                        height: 15,
                        decoration: BoxDecoration(
                          color: const Color(0xFF14C975),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityPill extends StatelessWidget {
  const _AvailabilityPill({required this.accepting});
  final bool accepting;

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
      decoration: BoxDecoration(
        color: accepting ? const Color(0xFFE8F6E4) : const Color(0xFFF3EFE6),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accepting ? const Color(0xFF11B965) : const Color(0xFF8E948F),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            accepting
                ? (ar ? 'متاح لاستلام الطلبات' : 'Available for orders')
                : (ar ? 'غير متاح لاستلام الطلبات' : 'Unavailable for orders'),
            style: const TextStyle(
              color: Color(0xFF145439),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceMapCard extends StatelessWidget {
  const _ReferenceMapCard({
    required this.shipment,
    required this.locating,
    required this.onLocate,
    required this.onDirections,
  });

  final Shipment? shipment;
  final bool locating;
  final VoidCallback onLocate;
  final VoidCallback? onDirections;

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    return Container(
      height: 310,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF2EFE2),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE7E3D5)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _MapRoadBackdrop(),
          Opacity(
            opacity: .20,
            child: Image.asset(
              ReferenceAssets.homeRouteDashboard,
              fit: BoxFit.cover,
            ),
          ),
          Opacity(
            opacity: .18,
            child: Image.asset(
              ReferenceAssets.routeMap,
              fit: BoxFit.cover,
            ),
          ),
          PositionedDirectional(
            start: 22,
            top: 22,
            child: _MapActionButton(
              icon: Icons.near_me_rounded,
              label: ar ? 'توجيه' : 'Directions',
              onPressed: onDirections,
            ),
          ),
          PositionedDirectional(
            end: 20,
            top: 22,
            child: _SquareMapButton(
              icon: locating ? Icons.sync_rounded : Icons.my_location_rounded,
              onPressed: locating ? null : onLocate,
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 54,
                  height: 54,
                  child: Image.asset(ReferenceAssets.homePin, fit: BoxFit.contain),
                ),
                const SizedBox(height: 2),
                Text(
                  shipment == null
                      ? (ar ? 'منطقة التشغيل' : 'Service area')
                      : (ar ? 'رحلتك الحالية' : 'Current trip'),
                  style: const TextStyle(
                    color: Color(0xFF5C5C58),
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          if (shipment != null)
            PositionedDirectional(
              start: 36,
              bottom: 30,
              child: SizedBox(
                width: 58,
                height: 58,
                child: Image.asset(
                  ReferenceAssets.deliveryScooter,
                  fit: BoxFit.contain,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MapRoadBackdrop extends StatelessWidget {
  const _MapRoadBackdrop();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _MapRoadPainter());
  }
}

class _MapRoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final green = Paint()
      ..color = const Color(0xFFDCEACC)
      ..style = PaintingStyle.fill;
    final road = Paint()
      ..color = Colors.white.withValues(alpha: .92)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final secondary = Paint()
      ..color = const Color(0xFFFFE8A4)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * .08, size.height * .04, size.width * .24, size.height * .25),
        const Radius.circular(18),
      ),
      green,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * .58, size.height * .12, size.width * .30, size.height * .28),
        const Radius.circular(18),
      ),
      green,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * .12, size.height * .63, size.width * .28, size.height * .25),
        const Radius.circular(18),
      ),
      green,
    );
    final p1 = Path()
      ..moveTo(-20, size.height * .72)
      ..cubicTo(
        size.width * .26,
        size.height * .53,
        size.width * .52,
        size.height * .70,
        size.width + 20,
        size.height * .32,
      );
    canvas.drawPath(p1, road);
    final p2 = Path()
      ..moveTo(size.width * .15, -20)
      ..lineTo(size.width * .43, size.height + 20);
    canvas.drawPath(p2, secondary);
    final p3 = Path()
      ..moveTo(size.width * .63, -20)
      ..lineTo(size.width * .83, size.height + 20);
    canvas.drawPath(p3, secondary);
    final p4 = Path()
      ..moveTo(-20, size.height * .37)
      ..lineTo(size.width + 20, size.height * .86);
    canvas.drawPath(p4, secondary);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({required this.icon, required this.label, required this.onPressed});
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 5,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.near_me_rounded, color: Color(0xFF075A35), size: 22),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF174D39),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SquareMapButton extends StatelessWidget {
  const _SquareMapButton({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 5,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: const Color(0xFF075A35)),
      ),
    );
  }
}

class _ReferenceMetricCard extends StatelessWidget {
  const _ReferenceMetricCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 135,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 31),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF265B48),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF071B13),
                fontSize: 27,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _firstName(String? raw, {required bool ar}) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return ar ? 'سائق مزرعتي' : 'Mazraa driver';
  return value.split(RegExp(r'\s+')).first;
}

String _incomeLabel(double amount, String currency, {required bool ar}) {
  final rounded = amount == amount.roundToDouble()
      ? amount.toStringAsFixed(0)
      : amount.toStringAsFixed(2);
  final normalized = currency.trim().toUpperCase();
  final unit = switch (normalized) {
    'SAR' => ar ? 'ر.س' : 'SAR',
    'YER' => ar ? 'ر.ي' : 'YER',
    'USD' => r'$',
    _ => normalized,
  };
  return unit.isEmpty ? rounded : '$rounded $unit';
}
