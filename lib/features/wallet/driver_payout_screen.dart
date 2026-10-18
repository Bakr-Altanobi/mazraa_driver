import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazraa_driver/core/network/providers.dart';
import 'package:mazraa_driver/core/utils/formatters.dart';
import 'package:mazraa_driver/features/operations/driver_live_providers.dart';
import 'package:mazraa_driver/features/reference_journey/reference_assets.dart';
import 'package:mazraa_driver/features/wallet/wallet_providers.dart';
import 'package:mazraa_driver/shared/widgets/mazraa_widgets.dart';

class DriverPayoutScreen extends ConsumerStatefulWidget {
  const DriverPayoutScreen({super.key});
  @override
  ConsumerState<DriverPayoutScreen> createState() => _DriverPayoutScreenState();
}

class _DriverPayoutScreenState extends ConsumerState<DriverPayoutScreen> {
  bool busy = false;

  Future<void> _addBank() async {
    if (busy) return;
    final ar = isArabic(context);
    final name = TextEditingController();
    final holder = TextEditingController();
    final iban = TextEditingController();
    final account = TextEditingController();
    try {
      final result = await showDialog<Map<String, String>>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(ar ? 'إضافة الحساب البنكي' : 'Bank account'),
          content: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: InputDecoration(
                labelText: ar ? 'البنك' : 'Bank name')),
              const SizedBox(height: 10),
              TextField(controller: holder, decoration: InputDecoration(
                labelText: ar ? 'اسم صاحب الحساب' : 'Account holder')),
              const SizedBox(height: 10),
              TextField(controller: iban, textDirection: TextDirection.ltr,
                decoration: const InputDecoration(labelText: 'IBAN')),
              const SizedBox(height: 10),
              TextField(controller: account, textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: ar ? 'رقم الحساب (اختياري)' : 'Account number (optional)')),
            ],
          )),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext),
              child: Text(ar ? 'إلغاء' : 'Cancel')),
            FilledButton(onPressed: () {
              if (name.text.trim().isEmpty || holder.text.trim().isEmpty ||
                  iban.text.trim().isEmpty) return;
              Navigator.pop(dialogContext, {
                'bankName': name.text.trim(),
                'accountHolderName': holder.text.trim(),
                'iban': iban.text.trim(),
                'accountNumber': account.text.trim(),
              });
            }, child: Text(ar ? 'حفظ' : 'Save')),
          ],
        ),
      );
      if (!mounted || result == null) return;
      final ok = await confirmAction(context,
        title: ar ? 'تأكيد بيانات البنك' : 'Confirm bank details',
        message: ar
            ? 'سيتم حفظ الحساب البنكي الذي أدخلته للسائق الحالي؛ قد يتطلب توثيق الإدارة.'
            : 'These bank details will be saved for this driver and may require verification.',
        confirmLabel: ar ? 'حفظ' : 'Save',
      );
      if (!ok || !mounted) return;
      setState(() => busy = true);
      await ref.read(driverApiProvider).putBankAccount(
        bankName: result['bankName']!,
        accountHolderName: result['accountHolderName']!,
        iban: result['iban']!,
        accountNumber: result['accountNumber'],
      );
      ref.invalidate(driverBankAccountsProvider);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())));
    } finally {
      name.dispose(); holder.dispose(); iban.dispose(); account.dispose();
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _requestPayout(List<dynamic> accounts, String currency) async {
    if (busy) return;
    final ar = isArabic(context);
    final selectable = accounts.whereType<Map<String, dynamic>>()
        .where((account) => account['id'] is num).toList();
    if (selectable.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ar ? 'أضف حسابًا بنكيًا أولًا' : 'Add a bank account first')));
      return;
    }
    final amount = TextEditingController();
    var bankId = (selectable.first['id'] as num).toInt();
    try {
      final request = await showDialog<(int, double)>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, change) => AlertDialog(
            title: Text(ar ? 'طلب سحب' : 'Request payout'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: bankId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: ar ? 'الحساب البنكي' : 'Bank account',
                  ),
                  items: [
                    for (final bank in selectable)
                      DropdownMenuItem(
                        value: (bank['id'] as num).toInt(),
                        child: Text(bank['bankName']?.toString() ?? ''),
                      ),
                  ],
                  onChanged: (value) { if (value != null) change(() => bankId = value); },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amount,
                  textDirection: TextDirection.ltr,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: '${ar ? 'المبلغ' : 'Amount'} ($currency)'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext),
                child: Text(ar ? 'إلغاء' : 'Cancel')),
              FilledButton(onPressed: () {
                final value = double.tryParse(amount.text.trim());
                if (value == null || value <= 0 || !value.isFinite) return;
                Navigator.pop(dialogContext, (bankId, value));
              }, child: Text(ar ? 'متابعة' : 'Continue')),
            ],
          ),
        ),
      );
      if (!mounted || request == null) return;
      final approved = await confirmAction(context,
        title: ar ? 'تأكيد طلب السحب' : 'Confirm payout',
        message: '${ar ? 'طلب سحب' : 'Request'} ${formatMoney(request.$2, currency, locale: ar ? 'ar' : 'en')}',
        confirmLabel: ar ? 'تأكيد' : 'Confirm',
      );
      if (!approved || !mounted) return;
      setState(() => busy = true);
      await ref.read(driverApiProvider).requestPayout(
        bankAccountId: request.$1, amount: request.$2, currency: currency);
      ref.invalidate(driverPayoutsProvider);
      ref.invalidate(walletSummaryProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ar ? 'تم تسجيل طلب السحب، بانتظار المعالجة' : 'Payout request submitted for processing')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      amount.dispose();
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    final wallet = ref.watch(walletSummaryProvider);
    final banks = ref.watch(driverBankAccountsProvider);
    final payouts = ref.watch(driverPayoutsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(ar ? 'الحساب البنكي والسحب' : 'Bank & payouts'),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded),
          onPressed: () {
            ref.invalidate(driverBankAccountsProvider);
            ref.invalidate(driverPayoutsProvider);
            ref.invalidate(walletSummaryProvider);
          })]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 32),
        children: [
          Card(child: Padding(padding: const EdgeInsets.all(18),
            child: Row(children: [
              Image.asset(ReferenceAssets.bankCard, width: 80, height: 82, cacheWidth: 180),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ar ? 'الرصيد القابل للمراجعة' : 'Wallet balance',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 7),
                  Text(wallet.when(
                    data: (v) => formatMoney(v.balance, v.currency, locale: ar ? 'ar' : 'en'),
                    loading: () => '…', error: (_, _) => '—'),
                    style: Theme.of(context).textTheme.headlineSmall),
                ])),
            ]),
          )),
          const SizedBox(height: 13),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: busy ? null : _addBank,
              icon: const Icon(Icons.account_balance_outlined),
              label: Text(ar ? 'تعديل البنك' : 'Bank details'))),
            const SizedBox(width: 10),
            Expanded(child: FilledButton.icon(
              onPressed: busy || !banks.hasValue || !wallet.hasValue
                  ? null : () => _requestPayout(banks.value!, wallet.value!.currency),
              icon: const Icon(Icons.payments_outlined),
              label: Text(ar ? 'طلب سحب' : 'Request payout'))),
          ]),
          const SizedBox(height: 22),
          Text(ar ? 'حساباتك البنكية' : 'Bank accounts',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          banks.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorState(error: e,
              onRetry: () => ref.invalidate(driverBankAccountsProvider)),
            data: (rows) => rows.isEmpty
                ? ListTile(title: Text(ar ? 'لم تُضف حسابًا بنكيًا' : 'No bank account'))
                : Column(children: [
                  for (final item in rows.whereType<Map<String, dynamic>>())
                    Card(child: ListTile(
                      leading: const Icon(Icons.account_balance_rounded),
                      title: Text(item['bankName']?.toString() ?? ''),
                      subtitle: Text(item['isVerified'] == true
                          ? (ar ? 'حساب موثق' : 'Verified')
                          : (ar ? 'بانتظار مراجعة الحساب' : 'Pending verification')),
                      trailing: const Icon(Icons.chevron_right_rounded),
                    )),
                ]),
          ),
          const SizedBox(height: 16),
          Text(ar ? 'طلبات السحب' : 'Payout requests',
              style: Theme.of(context).textTheme.titleMedium),
          payouts.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorState(error: e,
              onRetry: () => ref.invalidate(driverPayoutsProvider)),
            data: (rows) => rows.isEmpty
                ? ListTile(title: Text(ar ? 'لا توجد طلبات' : 'No payouts yet'))
                : Column(children: [
                    for (final item in rows.whereType<Map<String, dynamic>>())
                      Card(child: ListTile(
                        leading: const Icon(Icons.receipt_long_rounded),
                        title: Text('${item['amount'] ?? ''} ${item['currency'] ?? ''}'),
                        subtitle: Text('${ar ? 'الحالة' : 'Status'}: ${item['status'] ?? ''}'),
                      )),
                  ]),
          ),
          const SizedBox(height: 12),
          Text(
            ar ? 'طلب السحب ليس تأكيدًا للتحويل البنكي؛ راجع حالته بعد موافقة الإدارة ومعالجة المزود.'
               : 'A payout request does not confirm a bank transfer. Check its status after approval and processing.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
