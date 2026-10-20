import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/core/network/providers.dart';

/// Always reads the authenticated driver's records; no placeholder or seed
/// data is exposed in normal builds.
final driverJourneyProvider = FutureProvider<Map<String, dynamic>>((ref) =>
    ref.watch(driverApiProvider).getJourneyMe());

final driverOffersProvider = FutureProvider<List<DriverOffer>>((ref) async {
  final rows = await ref.watch(driverApiProvider).getOffers();
  return rows
      .whereType<Map<String, dynamic>>()
      .map(DriverOffer.fromJson)
      .where((offer) => offer.id > 0 && offer.expiresAt.isAfter(DateTime.now().toUtc()))
      .toList(growable: false);
});

final driverShiftsProvider = FutureProvider<List<dynamic>>(
  (ref) => ref.watch(driverApiProvider).getShifts(),
);

final driverBankAccountsProvider = FutureProvider<List<dynamic>>(
  (ref) => ref.watch(driverApiProvider).getBankAccounts(),
);

final driverPayoutsProvider = FutureProvider<List<dynamic>>(
  (ref) => ref.watch(driverApiProvider).getPayouts(),
);

class DriverOffer {
  const DriverOffer({
    required this.id,
    required this.shipmentId,
    required this.shipmentNumber,
    required this.expiresAt,
    this.distanceToPickupKm,
    this.pickup,
    this.customer,
  });

  factory DriverOffer.fromJson(Map<String, dynamic> json) {
    final expiresAt = DateTime.tryParse(json['expiresAt']?.toString() ?? '');
    return DriverOffer(
      id: (json['offerId'] as num?)?.toInt() ?? 0,
      shipmentId: (json['shipmentId'] as num?)?.toInt() ?? 0,
      shipmentNumber: (json['shipmentNumber'] ?? '').toString(),
      expiresAt: expiresAt?.toUtc() ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      distanceToPickupKm: (json['distanceToPickupKm'] as num?)?.toDouble(),
      pickup: GeoPoint.fromDynamic(null,
          latitude: json['pickupLatitude'],
          longitude: json['pickupLongitude']),
      customer: GeoPoint.fromDynamic(null,
          latitude: json['customerLatitude'],
          longitude: json['customerLongitude']),
    );
  }

  final int id;
  final int shipmentId;
  final String shipmentNumber;
  final DateTime expiresAt;
  final double? distanceToPickupKm;
  final GeoPoint? pickup;
  final GeoPoint? customer;
}
