import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/core/network/providers.dart';

final walletSummaryProvider = FutureProvider<WalletSummary>((ref) async {
  return ref.watch(driverApiProvider).getWallet();
});

final walletTransactionsProvider = FutureProvider<List<WalletTransaction>>((
  ref,
) async {
  return ref.watch(driverApiProvider).getWalletTransactions();
});
