import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazraa_driver/features/shipments/shipment_providers.dart';
import 'package:mazraa_driver/features/wallet/wallet_providers.dart';

/// Loads the server-backed data that the home screen needs for its first frame.
///
/// These providers are intentionally non-autoDispose, so awaiting them here also
/// warms their cached values. When the router finally enters `/home`, the home
/// screen receives shipments and wallet data immediately instead of showing an
/// incomplete first frame.
Future<void> preloadDriverHome(WidgetRef ref) async {
  await Future.wait([
    ref.read(shipmentsProvider.future),
    ref.read(walletSummaryProvider.future),
  ]);
}
