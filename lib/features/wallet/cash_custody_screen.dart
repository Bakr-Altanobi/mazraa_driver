import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazraa_driver/core/network/providers.dart';
import 'package:mazraa_driver/core/utils/formatters.dart';
import 'package:mazraa_driver/shared/widgets/mazraa_widgets.dart';

final cashCustodyProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async =>
    (await ref.watch(driverApiProvider).getCashCustody()).whereType<Map<String, dynamic>>().toList());

class CashCustodyScreen extends ConsumerWidget {
  const CashCustodyScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ar = isArabic(context);
    final state = ref.watch(cashCustodyProvider);
    return Scaffold(appBar: AppBar(title: Text(ar ? 'عهدة التحصيل النقدي' : 'Cash custody'), actions: [
      IconButton(onPressed: () => ref.invalidate(cashCustodyProvider), icon: const Icon(Icons.refresh))]),
      body: state.when(loading: LoadingList.new,
        error: (error, _) => ErrorState(error: error, onRetry: () => ref.invalidate(cashCustodyProvider)),
        data: (rows) {
          final balances = <String, double>{};
          for (final row in rows) {
            final currency = row['currency']?.toString() ?? '';
            balances.update(currency, (value) => value + (row['outstandingAmount'] as num? ?? 0).toDouble(),
              ifAbsent: () => (row['outstandingAmount'] as num? ?? 0).toDouble());
          }
          return RefreshIndicator(onRefresh: () async {
            ref.invalidate(cashCustodyProvider); await ref.read(cashCustodyProvider.future);
          }, child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(18), children: [
            Text(ar ? 'تُغلق العهدة بعد استلام الإدارة للنقد وتسجيل سند التوريد.' : 'Custody closes after operations receives your cash and records a receipt.'),
            const SizedBox(height: 12),
            for (final balance in balances.entries) Card(child: ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: Text(ar ? 'المتبقي للتوريد' : 'Outstanding cash'),
              trailing: Text(formatMoney(balance.value, balance.key, locale: ar ? 'ar' : 'en')))),
            if (rows.isEmpty) Padding(padding: const EdgeInsets.all(24), child: Text(ar ? 'لا توجد مبالغ نقدية مسجلة.' : 'No cash collections recorded.')),
            for (final row in rows) Card(child: ExpansionTile(
              title: Text('${ar ? 'الشحنة' : 'Shipment'} #${row['shipmentId']}'),
              subtitle: Text('${ar ? 'المتبقي' : 'Outstanding'}: ${formatMoney((row['outstandingAmount'] as num? ?? 0).toDouble(), row['currency']?.toString() ?? '', locale: ar ? 'ar' : 'en')}'),
              leading: Icon(row['isFullyRemitted'] == true ? Icons.check_circle_outline : Icons.payments_outlined),
              children: [ListTile(title: Text(ar ? 'المبلغ المحصل' : 'Cash collected'), trailing: Text('${row['amount']} ${row['currency']}')),
                for (final receipt in (row['receipts'] as List? ?? const []).whereType<Map<String, dynamic>>())
                  ListTile(leading: const Icon(Icons.receipt_long), title: Text(receipt['receiptReference']?.toString() ?? ''),
                    subtitle: Text(receipt['recordedAt']?.toString() ?? ''), trailing: Text('${receipt['amount']} ${row['currency']}')),
              ])),
          ]));
        }));
  }
}
