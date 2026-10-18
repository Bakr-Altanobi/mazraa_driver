import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazraa_driver/features/shipments/shipment_providers.dart';
import 'package:mazraa_driver/features/wallet/wallet_providers.dart';

/// Warm non-critical dashboard data without treating a shipment or wallet
/// endpoint outage as an authentication failure. Each screen handles its own
/// provider error state and can retry independently.
Future<void> preloadDriverHome(WidgetRef ref) async {
  await Future.wait<void>([
    ref.read(shipmentsProvider.future).then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    ),
    ref.read(walletSummaryProvider.future).then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    ),
  ]);
}
