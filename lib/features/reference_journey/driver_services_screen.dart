import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mazraa_driver/features/reference_journey/reference_catalog.dart';

/// Entry point for every authenticated driver service in the 48-screen
/// reference contract. Each destination uses its own reference artwork
/// and queries real server data through ReferenceRepository.
class DriverServicesScreen extends StatelessWidget {
  const DriverServicesScreen({super.key});

  static const _groups = <String>[
    'الطلبات والملاحة والتسليم',
    'الأرباح والمكافآت والأداء',
    'الحساب والمركبة والإعدادات',
    'الإشعارات والدعم والتقييمات',
  ];

  String _groupOf(int n) {
    if ({3, 4, 5, 6, 7, 8, 18, 23, 25, 26, 27, 28, 29, 39, 40}.contains(n)) {
      return _groups[0];
    }
    if ({9, 10, 17, 30, 32, 33, 37, 38, 41, 46}.contains(n)) {
      return _groups[1];
    }
    if ({12, 13, 14, 15, 16, 24, 31, 34, 35, 36, 42, 43, 44, 47}.contains(n)) {
      return _groups[2];
    }
    return _groups[3];
  }

  @override
  Widget build(BuildContext context) {
    final screens = ReferenceCatalog.screens.where((s) => s.number >= 3).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('جميع خدمات السائق')),
      body: ListView(
        key: const Key('driverServicesList'),
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 12),
            child: Text(
              'اختر العملية المطلوبة. بيانات الرحلات والمحفظة والحساب '
              'تُحمّل من السيرفر عند فتح الخدمة، ولا تُعرض بيانات تجريبية.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          for (final group in _groups) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 18, 6, 10),
              child: Text(group, style: Theme.of(context).textTheme.titleMedium),
            ),
            for (final spec in screens.where((s) => _groupOf(s.number) == group))
              Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  key: Key('driverService${spec.number}'),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  leading: SizedBox(
                    width: 54,
                    height: 54,
                    child: spec.assets.isNotEmpty
                        ? Image.asset(
                            spec.assets.first.path,
                            fit: BoxFit.contain,
                            cacheWidth: 180,
                          )
                        : const Icon(Icons.local_shipping_outlined),
                  ),
                  title: Text(spec.titleAr),
                  subtitle: Text(
                    spec.descriptionAr,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () => context.push(spec.route),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
