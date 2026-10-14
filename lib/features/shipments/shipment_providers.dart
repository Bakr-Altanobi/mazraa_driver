import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazraa_driver/core/constants/build_flags.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/core/network/providers.dart';

final shipmentsProvider = FutureProvider<List<Shipment>>((ref) async {
  if (BuildFlags.ciSmokeHome) {
    final now = DateTime.now();
    return [
      Shipment(
        id: 9101,
        number: 'SHP-9101',
        orderId: 50101,
        driverId: 77,
        customerId: 301,
        status: ShipmentStatus.inTransit,
        deliveryFee: 1800,
        transportCost: 350,
        netProfit: 1450,
        createdAt: now,
        storeLocation: const GeoPoint(15.3694, 44.1910),
        customerLocation: const GeoPoint(15.3547, 44.2067),
        driverLocation: const GeoPoint(15.3621, 44.1982),
        distanceKm: 4.8,
        etaMinutes: 14,
      ),
      Shipment(
        id: 9100,
        number: 'SHP-9100',
        orderId: 50100,
        driverId: 77,
        customerId: 300,
        status: ShipmentStatus.delivered,
        deliveryFee: 1500,
        transportCost: 300,
        netProfit: 1200,
        createdAt: now,
      ),
    ];
  }
  return ref.watch(driverApiProvider).getShipments();
});

final shipmentDetailsProvider = FutureProvider.autoDispose
    .family<Shipment, int>((ref, id) async {
      return ref.watch(driverApiProvider).getShipment(id);
    });

final shipmentTrackingProvider = FutureProvider.autoDispose
    .family<Shipment, int>((ref, id) async {
      return ref.watch(driverApiProvider).getTracking(id);
    });
