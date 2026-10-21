import 'package:flutter/material.dart';
import 'package:mazraa_driver/features/workspace/driver_tool_catalog.dart';
import 'package:go_router/go_router.dart';
import 'package:mazraa_driver/features/reference_journey/reference_assets.dart';
import 'package:mazraa_driver/features/reference_journey/reference_catalog.dart';
import 'package:mazraa_driver/shared/widgets/mazraa_widgets.dart';

/// All canonical reference screens are Flutter widgets backed by the actual API.
/// Artwork comes from ASSET_INDEX derivatives, never screenshots.
class DriverServicesScreen extends StatefulWidget {
  const DriverServicesScreen({super.key});

  @override
  State<DriverServicesScreen> createState() => _DriverServicesScreenState();
}

class _DriverServicesScreenState extends State<DriverServicesScreen> {
  final _query = TextEditingController();
  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  static const categories = <String, List<int>>{
    'العمل والطلبات': [3, 4, 5, 6, 7, 8, 23, 25, 26, 27, 28, 29, 39, 40],
    'الجدول والمركبة': [14, 15, 16, 41, 42, 43, 47],
    'الأرباح والتسويات': [9, 10, 17, 30, 37, 38, 46],
    'التواصل والمساعدة': [11, 18, 19, 20, 21, 22, 33, 34, 45, 48],
    'الحساب والتفضيلات': [1, 2, 12, 13, 24, 31, 32, 35, 36, 44],
  };
  static const labelsEn = <int, String>{
    1: 'Onboarding',
    2: 'Sign in',
    3: 'Dashboard',
    4: 'Orders',
    5: 'Order details',
    6: 'Pickup navigation',
    7: 'Pickup verification',
    8: 'Delivery',
    9: 'Earnings',
    10: 'Wallet & payouts',
    11: 'Notifications',
    12: 'Profile & settings',
    13: 'Driver application',
    14: 'Documents',
    15: 'Vehicle',
    16: 'Availability',
    17: 'Incentives',
    18: 'Order problem',
    19: 'Customer chat',
    20: 'Emergency help',
    21: 'Support',
    22: 'Ratings',
    23: 'No orders',
    24: 'Referrals',
    25: 'Trip history',
    26: 'QR proof',
    27: 'Batch deliveries',
    28: 'Pickup checklist',
    29: 'Delivery proof',
    30: 'Bank account',
    31: 'Language & privacy',
    32: 'Performance',
    33: 'Rating details',
    34: 'Notification preferences',
    35: 'Service area',
    36: 'System health',
    37: 'Cash collections',
    38: 'Payout status',
    39: 'Returns',
    40: 'Customer unavailable',
    41: 'Shift summary',
    42: 'Vehicle maintenance',
    43: 'Document renewal',
    44: 'Account suspended',
    45: 'Incident report',
    46: 'Fee breakdown',
    47: 'Identity verification',
    48: 'Customer feedback',
  };

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    final filter = _query.text.trim().toLowerCase();
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(ar ? 'خدمات السائق' : 'Driver services')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Image.asset(
                    ReferenceAssets.deliveryScooter,
                    width: 74,
                    height: 74,
                    cacheWidth: 200,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ar
                          ? 'كل أدوات عملك في مكان واحد، مرتبطة بحسابك الحقيقي.'
                          : 'Your operational tools, connected to your real driver account.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _query,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: ar
                  ? 'ابحث عن شاشة أو خدمة'
                  : 'Search screens and services',
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Column(
              children: [
                for (final tool in driverTools.where(
                  (t) =>
                      t.pending ||
                      t.id == 'training' ||
                      t.id == 'preferences' ||
                      t.id == 'scheduled-trips',
                ))
                  if (filter.isEmpty ||
                      tool.ar.contains(filter) ||
                      tool.en.toLowerCase().contains(filter))
                    ListTile(
                      leading: Icon(tool.icon, color: colors.primary),
                      title: Text(ar ? tool.ar : tool.en),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(tool.route),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          for (final group in categories.entries) ...[
            if (group.value.any((number) {
              final spec = ReferenceCatalog.screen(number);
              return filter.isEmpty ||
                  spec.titleAr.toLowerCase().contains(filter) ||
                  (labelsEn[number] ?? '').toLowerCase().contains(filter) ||
                  number.toString().contains(filter);
            })) ...[
              Text(
                ar
                    ? group.key
                    : switch (group.key) {
                        'العمل والطلبات' => 'Orders & delivery',
                        'الجدول والمركبة' => 'Schedule & vehicle',
                        'الأرباح والتسويات' => 'Earnings & settlements',
                        'التواصل والمساعدة' => 'Communication & support',
                        _ => 'Account & settings',
                      },
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    for (final number in group.value)
                      if (filter.isEmpty ||
                          ReferenceCatalog.screen(
                            number,
                          ).titleAr.toLowerCase().contains(filter) ||
                          (labelsEn[number] ?? '').toLowerCase().contains(
                            filter,
                          ) ||
                          number.toString().contains(filter))
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: colors.primaryContainer,
                            child: Text(number.toString().padLeft(2, '0')),
                          ),
                          title: Text(
                            ar
                                ? ReferenceCatalog.screen(number).titleAr
                                : (labelsEn[number] ??
                                      ReferenceCatalog.screen(number).titleAr),
                          ),
                          subtitle: Text(
                            ar
                                ? 'بيانات وأحداث مباشرة من السيرفر عند توفرها'
                                : 'Live server-backed data and available actions',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.push(
                            '/journey/${number.toString().padLeft(2, '0')}',
                          ),
                        ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
          ],
        ],
      ),
    );
  }
}
