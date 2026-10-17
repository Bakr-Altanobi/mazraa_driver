import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mazraa_driver/features/shipments/driver_offer_feed.dart';

const _forest = Color(0xFF075A35);
const _orange = Color(0xFFC95A22);

class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = ref.watch(driverOfferFeedProvider).asData?.value.offers.length ?? 0;
    final current = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 7, 13, 5),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 18,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _ReferenceDestination(
                  selected: current == 0,
                  icon: Icons.home_rounded,
                  outlineIcon: Icons.home_outlined,
                  label: 'الرئيسية',
                  onTap: () => _go(0),
                ),
              ),
              Expanded(
                child: _ReferenceDestination(
                  selected: current == 2,
                  icon: Icons.map_rounded,
                  outlineIcon: Icons.map_outlined,
                  label: 'الخريطة',
                  onTap: () => _go(2),
                ),
              ),
              Expanded(
                child: _ReferenceDestination(
                  selected: current == 1,
                  icon: Icons.assignment_rounded,
                  outlineIcon: Icons.assignment_outlined,
                  label: 'الطلبات',
                  badge: offers,
                  onTap: () => _go(1),
                ),
              ),
              Expanded(
                child: _ReferenceDestination(
                  selected: current == 4,
                  icon: Icons.person_rounded,
                  outlineIcon: Icons.person_outline_rounded,
                  label: 'حسابي',
                  onTap: () => _go(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _go(int branch) {
    navigationShell.goBranch(
      branch,
      initialLocation: branch == navigationShell.currentIndex,
    );
  }
}

class _ReferenceDestination extends StatelessWidget {
  const _ReferenceDestination({
    required this.selected,
    required this.icon,
    required this.outlineIcon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  final bool selected;
  final IconData icon;
  final IconData outlineIcon;
  final String label;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final color = selected ? _forest : const Color(0xFF5E5A56);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0F5E9) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(selected ? icon : outlineIcon, color: color, size: 28),
                if (badge > 0)
                  Positioned(
                    right: -9,
                    top: -6,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: _orange,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
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
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
