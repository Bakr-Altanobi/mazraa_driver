import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/core/network/providers.dart';

final shipmentsProvider = FutureProvider<List<Shipment>>((ref) async {
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
