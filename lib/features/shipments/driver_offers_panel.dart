import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazraa_driver/core/network/providers.dart';
import 'package:mazraa_driver/features/reference_journey/reference_assets.dart';
import 'package:mazraa_driver/features/shipments/shipment_providers.dart';
import 'package:mazraa_driver/shared/widgets/mazraa_widgets.dart';

/// Every offer displayed here is issued by /api/driver-journey/offers.
/// An expired or already-assigned offer is still revalidated by the backend.
class DriverOffer {
  const DriverOffer({
    required this.offerId,
    required this.shipmentId,
    required this.shipmentNumber,
    required this.expiresAt,
    required this.secondsRemaining,
    this.distanceToPickupKm,
  });

  final int offerId;
  final int shipmentId;
  final String shipmentNumber;
  final DateTime expiresAt;
  final int secondsRemaining;
  final double? distanceToPickupKm;

  static int _int(Object? value) =>
      int.tryParse(value?.toString() ?? '') ?? 0;

  factory DriverOffer.fromJson(Map<String, dynamic> json) {
    final offerId = _int(json['offerId']);
    final shipmentId = _int(json['shipmentId']);
    if (offerId <= 0 || shipmentId <= 0) {
      throw const FormatException('استجابة العرض تفتقد رقم العرض أو الشحنة.');
    }
    return DriverOffer(
      offerId: offerId,
      shipmentId: shipmentId,
      shipmentNumber: (json['shipmentNumber'] ?? '').toString(),
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      secondsRemaining: _int(json['secondsRemaining']),
      distanceToPickupKm: double.tryParse(
        json['distanceToPickupKm']?.toString() ?? '',
      ),
    );
  }

  bool get isExpired => !expiresAt.isAfter(DateTime.now());
}

final driverOffersProvider = FutureProvider.autoDispose<List<DriverOffer>>(
  (ref) async {
    final rows = await ref.watch(driverApiProvider).getOffers();
    return rows
        .whereType<Map<String, dynamic>>()
        .map(DriverOffer.fromJson)
        .toList(growable: false);
  },
);

class DriverOffersPanel extends ConsumerStatefulWidget {
  const DriverOffersPanel({super.key});

  @override
  ConsumerState<DriverOffersPanel> createState() => _DriverOffersPanelState();
}

class _DriverOffersPanelState extends ConsumerState<DriverOffersPanel> {
  int? _busyOfferId;

  Future<void> _respond(DriverOffer offer, {required bool accept}) async {
    if (_busyOfferId != null) return;
    if (offer.isExpired) {
      ref.invalidate(driverOffersProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('انتهت صلاحية العرض، جارٍ تحديث القائمة.')),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(accept ? 'قبول عرض التوصيل' : 'رفض عرض التوصيل'),
            content: Text(
              'الشحنة ${offer.shipmentNumber.isEmpty ? '#${offer.shipmentId}' : offer.shipmentNumber} — سيتم إرسال القرار إلى السيرفر.',
            ),
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
        ) ??
        false;
    if (!confirmed || !mounted) return;
    setState(() => _busyOfferId = offer.offerId);
    try {
      final api = ref.read(driverApiProvider);
      if (accept) {
        await api.acceptOffer(offer.offerId);
      } else {
        await api.rejectOffer(offer.offerId);
      }
      ref.invalidate(driverOffersProvider);
      ref.invalidate(shipmentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(accept ? 'تم قبول العرض' : 'تم رفض العرض')),
        );
      }
    } catch (error) {
      ref.invalidate(driverOffersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _busyOfferId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ref.watch(driverOffersProvider).when(
      loading: LoadingList.new,
      error: (error, _) => ErrorState(
        error: error,
        onRetry: () => ref.invalidate(driverOffersProvider),
      ),
      data: (offers) {
        if (offers.isEmpty) {
          return EmptyState(
            title: 'لا توجد عروض توصيل متاحة الآن',
            message: 'ستظهر هنا العروض الصادرة من السيرفر عند إتاحتها لحسابك.',
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(driverOffersProvider);
            await ref.read(driverOffersProvider.future);
          },
          child: ListView.separated(
            key: const Key('liveDriverOffersList'),
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
            itemCount: offers.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final offer = offers[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            ReferenceAssets.deliveryTote,
                            width: 52,
                            height: 52,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              offer.shipmentNumber.isEmpty
                                  ? 'شحنة #${offer.shipmentId}'
                                  : offer.shipmentNumber,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (offer.distanceToPickupKm != null)
                        Text('المسافة إلى نقطة الاستلام: ${offer.distanceToPickupKm!.toStringAsFixed(1)} كم'),
                      Text(
                        offer.isExpired
                            ? 'انتهت صلاحية العرض'
                            : 'ينتهي العرض: ${TimeOfDay.fromDateTime(offer.expiresAt.toLocal()).format(context)}',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              key: Key('acceptOffer${offer.offerId}'),
                              onPressed: offer.isExpired || _busyOfferId != null
                                  ? null
                                  : () => _respond(offer, accept: true),
                              child: const Text('قبول العرض'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              key: Key('rejectOffer${offer.offerId}'),
                              onPressed: offer.isExpired || _busyOfferId != null
                                  ? null
                                  : () => _respond(offer, accept: false),
                              child: const Text('رفض'),
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
    );
  }
}
