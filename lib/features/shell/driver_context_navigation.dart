import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DriverNavDestination {
  const DriverNavDestination(this.route, this.ar, this.en, this.icon);
  final String route;
  final String ar, en;
  final IconData icon;
}

/// Secondary screens have their own relevant navigation, not an unrelated
/// 48-screen service index. This lives outside the Navigator, so a pushed
/// screen cannot accidentally reserve the parent shell's GlobalKey twice.
List<DriverNavDestination> driverDestinationsFor(String path) {
  if (path.startsWith('/shipments/') || path.startsWith('/tasks/')) {
    return const [
      DriverNavDestination('/shipments', 'الشحنات', 'Shipments', Icons.local_shipping_outlined),
      DriverNavDestination('/tools/current-trips', 'رحلاتي', 'My trips', Icons.route_outlined),
      DriverNavDestination('/offers', 'العروض', 'Offers', Icons.local_offer_outlined),
    ];
  }
  if (path.startsWith('/chats/') || path == '/tools/chats' ||
      path.startsWith('/support') || path == '/tools/notification-preferences') {
    return const [
      DriverNavDestination('/notifications', 'الإشعارات', 'Alerts', Icons.notifications_outlined),
      DriverNavDestination('/tools/chats', 'المحادثات', 'Chats', Icons.chat_bubble_outline),
      DriverNavDestination('/support', 'الدعم', 'Support', Icons.support_agent_outlined),
    ];
  }
  if (path == '/tools/scheduled-trips' || path == '/tools/current-trips' ||
      path == '/tools/availability' || path == '/tools/preferences') {
    return const [
      DriverNavDestination('/tools/scheduled-trips', 'المجدولة', 'Scheduled', Icons.event_available_outlined),
      DriverNavDestination('/tools/current-trips', 'رحلاتي', 'My trips', Icons.route_outlined),
      DriverNavDestination('/tools/availability', 'التوفر', 'Availability', Icons.calendar_month_outlined),
    ];
  }
  if (path.contains('vehicle') || path.contains('maintenance') ||
      path.contains('documents') || path == '/upload-document') {
    return const [
      DriverNavDestination('/tools/vehicle', 'المركبة', 'Vehicle', Icons.local_shipping_outlined),
      DriverNavDestination('/tools/vehicle-change', 'تغيير المركبة', 'Change', Icons.car_rental_outlined),
      DriverNavDestination('/tools/documents', 'المستندات', 'Documents', Icons.folder_open_outlined),
    ];
  }
  if (path == '/payouts' || path == '/cash-custody' ||
      path.contains('earnings') || path.contains('bank')) {
    return const [
      DriverNavDestination('/wallet', 'المحفظة', 'Wallet', Icons.account_balance_wallet_outlined),
      DriverNavDestination('/tools/earnings', 'الأرباح', 'Earnings', Icons.payments_outlined),
      DriverNavDestination('/payouts', 'السحوبات', 'Payouts', Icons.receipt_long_outlined),
    ];
  }
  if (path.startsWith('/tools/') || path == '/settings' || path == '/services') {
    return const [
      DriverNavDestination('/profile', 'حسابي', 'Profile', Icons.person_outline),
      DriverNavDestination('/tools/vehicle', 'مركبتي', 'Vehicle', Icons.local_shipping_outlined),
      DriverNavDestination('/tools/preferences', 'تفضيلاتي', 'Preferences', Icons.tune_outlined),
    ];
  }
  return const [
    DriverNavDestination('/home', 'الرئيسية', 'Home', Icons.home_outlined),
    DriverNavDestination('/shipments', 'الشحنات', 'Shipments', Icons.local_shipping_outlined),
    DriverNavDestination('/profile', 'حسابي', 'Profile', Icons.person_outline),
  ];
}

bool showContextualDriverBar(String path) =>
    !const {'/home', '/shipments', '/wallet', '/notifications',
            '/profile', '/splash', '/onboarding', '/login', '/apply'}.contains(path);

class DriverContextNavigation extends StatelessWidget {
  const DriverContextNavigation({
    required this.router,
    required this.child,
    super.key,
  });

  final GoRouter router;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: router.routeInformationProvider,
      child: child,
      builder: (context, routedChild) {
        final path = router.routeInformationProvider.value.uri.path;
        if (!showContextualDriverBar(path) ||
            MediaQuery.viewInsetsOf(context).bottom > 0) {
          return routedChild ?? const SizedBox.shrink();
        }
        final ar = Localizations.localeOf(context).languageCode == 'ar';
        final colors = Theme.of(context).colorScheme;
        final items = driverDestinationsFor(path);
        return Column(
          children: [
            Expanded(child: routedChild ?? const SizedBox.shrink()),
            Material(
              color: colors.surface,
              elevation: 3,
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 70,
                  child: Row(
                    children: [
                      for (final item in items)
                        Expanded(
                          child: InkWell(
                            key: ValueKey('context-tab-${item.route}'),
                            onTap: () {
                              if (item.route == path) return;
                              // Use replacement navigation instead of stacking
                              // multiple nested Navigator pages with shared keys.
                              router.go(item.route);
                            },
                            child: Semantics(
                              button: true,
                              selected: item.route == path,
                              label: ar ? item.ar : item.en,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: item.route == path
                                          ? colors.primaryContainer
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Icon(
                                      item.icon,
                                      color: item.route == path
                                          ? colors.onPrimaryContainer
                                          : colors.onSurfaceVariant,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    ar ? item.ar : item.en,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.labelSmall
                                        ?.copyWith(
                                            color: item.route == path
                                                ? colors.primary
                                                : colors.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
