import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazraa_driver/core/network/providers.dart';
import 'package:mazraa_driver/features/reference_journey/reference_assets.dart';

/// Server-owned offers with explicit per-offer actions; never auto-select a
/// different offer than the one the driver tapped.
class DriverOffersScreen extends ConsumerStatefulWidget {
  const DriverOffersScreen({super.key});

  @override
  ConsumerState<DriverOffersScreen> createState() => _DriverOffersScreenState();
}

class _DriverOffersScreenState extends ConsumerState<DriverOffersScreen> {
  late Future<List<dynamic>> _future = _load();
  int? _busyOffer;

  Future<List<dynamic>> _load() => ref.read(driverApiProvider).getOffers();

  void _refresh() {
    setState(() => _future = _load());
  }

  Future<void> _decide(int offerId, {required bool accept}) async {
    if (_busyOffer != null) return;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(accept ? 'قبول عرض التوصيل' : 'رفض عرض التوصيل'),
        content: Text('سيتم ${accept ? 'قبول' : 'رفض'} العرض رقم $offerId على السيرفر.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    setState(() => _busyOffer = offerId);
    try {
      final api = ref.read(driverApiProvider);
      if (accept) {
        await api.acceptOffer(offerId);
      } else {
        await api.rejectOffer(offerId);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(accept ? 'تم قبول العرض.' : 'تم رفض العرض.')),
      );
      _refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تحديث العرض: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _busyOffer = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('عروض التوصيل'),
          actions: [
            IconButton(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'تحديث العروض',
            ),
          ],
        ),
        body: FutureBuilder<List<dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('تعذر تحميل العروض: ${snapshot.error}'),
                      const SizedBox(height: 12),
                      OutlinedButton(onPressed: _refresh, child: const Text('إعادة المحاولة')),
                    ],
                  ),
                ),
              );
            }
            final offers = (snapshot.data ?? const [])
                .whereType<Map<String, dynamic>>()
                .toList();
            if (offers.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('لا توجد عروض توصيل حالية مسندة إلى حسابك.'),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                _refresh();
                await _future;
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: offers.length,
                itemBuilder: (context, index) {
                  final row = offers[index];
                  final offerId = int.tryParse(
                    '${row['offerId'] ?? row['id'] ?? ''}',
                  );
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                ReferenceAssets.ordersProduceThumbnail,
                                width: 58,
                                height: 58,
                                cacheWidth: 180,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'عرض #${offerId ?? '-'}',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              if (row['status'] != null)
                                Text('${row['status']}'),
                            ],
                          ),
                          for (final field in const [
                            ('shipmentId', 'الشحنة'),
                            ('deliveryFee', 'رسوم التوصيل'),
                            ('expiresAt', 'انتهاء العرض'),
                            ('createdAt', 'تاريخ العرض'),
                          ])
                            if (row[field.$1] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text('${field.$2}: ${row[field.$1]}'),
                              ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  onPressed: offerId == null || _busyOffer != null
                                      ? null
                                      : () => _decide(offerId, accept: true),
                                  child: const Text('قبول العرض'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: offerId == null || _busyOffer != null
                                      ? null
                                      : () => _decide(offerId, accept: false),
                                  child: const Text('رفض العرض'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      );
}
