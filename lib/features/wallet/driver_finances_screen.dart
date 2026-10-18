import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/core/network/providers.dart';
import 'package:mazraa_driver/features/reference_journey/reference_assets.dart';

class _FinanceData {
  const _FinanceData(this.wallet, this.accounts, this.payouts);
  final WalletSummary wallet;
  final List<Map<String, dynamic>> accounts;
  final List<Map<String, dynamic>> payouts;
}

class DriverFinancesScreen extends ConsumerStatefulWidget {
  const DriverFinancesScreen({super.key});

  @override
  ConsumerState<DriverFinancesScreen> createState() => _DriverFinancesScreenState();
}

class _DriverFinancesScreenState extends ConsumerState<DriverFinancesScreen> {
  late Future<_FinanceData> _future = _load();
  bool _saving = false;

  Future<_FinanceData> _load() async {
    final api = ref.read(driverApiProvider);
    final wallet = await api.getWallet();
    final accounts = await api.getBankAccounts();
    final payouts = await api.getPayouts();
    return _FinanceData(
      wallet,
      accounts.whereType<Map<String, dynamic>>().toList(),
      payouts.whereType<Map<String, dynamic>>().toList(),
    );
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _updateBank(_FinanceData data) async {
    final existing = data.accounts.where((a) => a['isDefault'] == true).firstOrNull ??
        (data.accounts.isEmpty ? null : data.accounts.first);
    final bankName = TextEditingController(text: existing?['bankName']?.toString() ?? '');
    final holder = TextEditingController(text: existing?['accountHolderName']?.toString() ?? '');
    final iban = TextEditingController(text: existing?['iban']?.toString() ?? '');
    final number = TextEditingController(text: existing?['accountNumber']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('إضافة أو تحديث الحساب البنكي'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: bankName,
                  decoration: const InputDecoration(labelText: 'اسم البنك'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
                TextFormField(
                  controller: holder,
                  decoration: const InputDecoration(labelText: 'اسم صاحب الحساب'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
                TextFormField(
                  controller: iban,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(labelText: 'IBAN'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
                TextFormField(
                  controller: number,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(labelText: 'رقم الحساب (اختياري)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(dialog, true);
            },
            child: const Text('حفظ في السيرفر'),
          ),
        ],
      ),
    );
    final values = (
      bank: bankName.text.trim(),
      holder: holder.text.trim(),
      iban: iban.text.trim(),
      number: number.text.trim(),
    );
    bankName.dispose();
    holder.dispose();
    iban.dispose();
    number.dispose();
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await ref.read(driverApiProvider).putBankAccount(
        bankName: values.bank,
        accountHolderName: values.holder,
        iban: values.iban,
        accountNumber: values.number.isEmpty ? null : values.number,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حُفظ الحساب البنكي ويحتاج التحقق من الإدارة.')),
        );
        _reload();
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _requestPayout(_FinanceData data) async {
    if (data.accounts.isEmpty) {
      _showError('أضف حسابًا بنكيًا أولًا.');
      return;
    }
    final amount = TextEditingController();
    var bankId = int.tryParse('${data.accounts.first['id']}');
    final response = await showDialog<(int, double)>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, setDialogState) => AlertDialog(
          title: const Text('طلب سحب من المحفظة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('الرصيد: ${data.wallet.balance} ${data.wallet.currency}'),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: bankId,
                decoration: const InputDecoration(labelText: 'الحساب البنكي'),
                items: [
                  for (final bank in data.accounts)
                    if (int.tryParse('${bank['id']}') case final int id)
                      DropdownMenuItem(
                        value: id,
                        child: Text('${bank['bankName'] ?? ''} - ${bank['iban'] ?? ''}',
                          overflow: TextOverflow.ellipsis),
                      ),
                ],
                onChanged: (v) => setDialogState(() => bankId = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'المبلغ (${data.wallet.currency})',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(amount.text.trim());
                if (bankId == null || value == null || value <= 0 ||
                    value > data.wallet.balance) return;
                Navigator.pop(dialog, (bankId!, value));
              },
              child: const Text('إرسال طلب السحب'),
            ),
          ],
        ),
      ),
    );
    amount.dispose();
    if (response == null || !mounted) return;
    setState(() => _saving = true);
    try {
      await ref.read(driverApiProvider).requestPayout(
        bankAccountId: response.$1,
        amount: response.$2,
        currency: data.wallet.currency,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسجيل طلب السحب في السيرفر.')),
        );
        _reload();
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('لم تتم العملية: $error')),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('الحساب البنكي والسحوبات'),
          actions: [
            IconButton(
              tooltip: 'تحديث البيانات',
              onPressed: _saving ? null : _reload,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: FutureBuilder<_FinanceData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: TextButton(
                  onPressed: _reload,
                  child: Text('تعذر التحميل: ${snapshot.error}. إعادة المحاولة'),
                ),
              );
            }
            final data = snapshot.data!;
            return ListView(
              key: const Key('driverFinances'),
              padding: const EdgeInsets.all(18),
              children: [
                Image.asset(
                  ReferenceAssets.bankCard,
                  height: 135,
                  fit: BoxFit.contain,
                  cacheWidth: 550,
                ),
                Text(
                  'الرصيد: ${data.wallet.balance} ${data.wallet.currency}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _saving ? null : () => _requestPayout(data),
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('طلب سحب رصيد'),
                ),
                OutlinedButton.icon(
                  onPressed: _saving ? null : () => _updateBank(data),
                  icon: const Icon(Icons.account_balance_outlined),
                  label: const Text('إضافة أو تعديل الحساب البنكي'),
                ),
                const SizedBox(height: 22),
                Text('الحسابات البنكية', style: Theme.of(context).textTheme.titleMedium),
                if (data.accounts.isEmpty)
                  const Text('لم تتم إضافة حساب بنكي بعد.')
                else
                  for (final bank in data.accounts)
                    Card(
                      child: ListTile(
                        title: Text('${bank['bankName'] ?? ''}'),
                        subtitle: Text(
                          '${bank['iban'] ?? ''}\n'
                          '${bank['isVerified'] == true ? 'تم التحقق' : 'قيد التحقق'}',
                        ),
                      ),
                    ),
                const SizedBox(height: 16),
                Text('طلبات السحب السابقة', style: Theme.of(context).textTheme.titleMedium),
                if (data.payouts.isEmpty)
                  const Text('لا توجد طلبات سحب سابقة.')
                else
                  for (final payout in data.payouts)
                    Card(
                      child: ListTile(
                        title: Text('${payout['amount'] ?? ''} ${payout['currency'] ?? ''}'),
                        subtitle: Text('الحالة: ${payout['status'] ?? ''}'),
                        trailing: Text('#${payout['id'] ?? ''}'),
                      ),
                    ),
              ],
            );
          },
        ),
      );
}
