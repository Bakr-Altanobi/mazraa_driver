import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazraa_driver/core/network/providers.dart';

/// Server-backed controls on the reference services screens. No payouts or
/// preferences are simulated locally: a successful API response is required.
class DriverServiceControls extends ConsumerStatefulWidget {
  const DriverServiceControls({
    required this.screenNumber,
    required this.onSaved,
    super.key,
  });

  final int screenNumber;
  final VoidCallback onSaved;

  @override
  ConsumerState<DriverServiceControls> createState() => _DriverServiceControlsState();
}

class _DriverServiceControlsState extends ConsumerState<DriverServiceControls> {
  bool _busy = false;

  Future<void> _run(Future<bool> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final saved = await action();
      if (saved && mounted) {
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ العملية في السيرفر.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _editBank() async {
    final bank = TextEditingController();
    final holder = TextEditingController();
    final iban = TextEditingController();
    final account = TextEditingController();
    try {
      final formKey = GlobalKey<FormState>();
      final entered = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('إضافة أو تعديل الحساب البنكي'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    key: const Key('bankNameField'),
                    controller: bank,
                    decoration: const InputDecoration(labelText: 'اسم البنك'),
                    validator: (v) => v?.trim().isNotEmpty == true ? null : 'اسم البنك مطلوب',
                  ),
                  TextFormField(
                    controller: holder,
                    decoration: const InputDecoration(labelText: 'اسم صاحب الحساب'),
                    validator: (v) => v?.trim().isNotEmpty == true ? null : 'اسم صاحب الحساب مطلوب',
                  ),
                  TextFormField(
                    key: const Key('bankIbanField'),
                    controller: iban,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(labelText: 'IBAN'),
                    validator: (v) =>
                        (v?.replaceAll(' ', '').length ?? 0) >= 8 ? null : 'تحقق من رقم IBAN',
                  ),
                  TextFormField(
                    controller: account,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(labelText: 'رقم الحساب (اختياري)'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() == true) Navigator.pop(ctx, true);
              },
              child: const Text('حفظ في السيرفر'),
            ),
          ],
        ),
      );
      if (entered != true || !mounted) return false;
      await ref.read(driverApiProvider).putBankAccount(
        bankName: bank.text,
        accountHolderName: holder.text,
        iban: iban.text,
        accountNumber: account.text.isEmpty ? null : account.text,
      );
      return true;
    } finally {
      bank.dispose();
      holder.dispose();
      iban.dispose();
      account.dispose();
    }
  }

  Future<bool> _requestPayout() async {
    final api = ref.read(driverApiProvider);
    final wallet = await api.getWallet();
    final rows = await api.getBankAccounts();
    final accounts = rows.whereType<Map<String, dynamic>>().where(
      (row) => int.tryParse('${row['id']}') != null,
    ).toList(growable: false);
    if (accounts.isEmpty) {
      throw StateError('أضف حسابًا بنكيًا من السيرفر قبل طلب السحب.');
    }
    if (wallet.balance <= 0) {
      throw StateError('لا يوجد رصيد متاح لإرسال طلب سحب.');
    }
    int? selected = int.tryParse('${accounts.first['id']}');
    final amount = TextEditingController();
    try {
      final formKey = GlobalKey<FormState>();
      final entered = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('طلب سحب من المحفظة'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('الرصيد: ${wallet.balance.toStringAsFixed(2)} ${wallet.currency}'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: selected,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'الحساب البنكي'),
                    items: [
                      for (final account in accounts)
                        DropdownMenuItem(
                          value: int.parse('${account['id']}'),
                          child: Text('${account['bankName'] ?? ''} · ${account['iban'] ?? ''}', overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (next) => setDialogState(() => selected = next),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('payoutAmountField'),
                    controller: amount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'المبلغ (${wallet.currency})'),
                    validator: (value) {
                      final parsed = double.tryParse(value?.trim() ?? '');
                      if (parsed == null || !parsed.isFinite || parsed <= 0) return 'أدخل مبلغًا موجبًا';
                      if (parsed > wallet.balance) return 'المبلغ أكبر من رصيد المحفظة';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() == true && selected != null) {
                    Navigator.pop(ctx, true);
                  }
                },
                child: const Text('إرسال طلب السحب'),
              ),
            ],
          ),
        ),
      );
      if (entered != true || selected == null || !mounted) return false;
      await api.requestPayout(
        bankAccountId: selected!,
        amount: double.parse(amount.text.trim()),
        currency: wallet.currency,
      );
      return true;
    } finally {
      amount.dispose();
    }
  }

  Future<bool> _editPreferences() async {
    final api = ref.read(driverApiProvider);
    final existing = await api.getDriverPreferences();
    var scheduled = existing['acceptScheduledTrips'] == true;
    var private = existing['acceptPrivateDeliveries'] == true;
    var batch = existing['acceptBatchDeliveries'] == true;
    var offers = existing['isAvailableForOffers'] == true;
    final radius = TextEditingController(text: '${existing['offerRadiusKm'] ?? 50}');
    final timeout = TextEditingController(text: '${existing['offerTimeoutSeconds'] ?? 60}');
    try {
      final formKey = GlobalKey<FormState>();
      final entered = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('تفضيلات استقبال الرحلات'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      title: const Text('الرحلات المجدولة'),
                      value: scheduled,
                      onChanged: (v) => setDialogState(() => scheduled = v),
                    ),
                    SwitchListTile(
                      title: const Text('التوصيل الخاص'),
                      value: private,
                      onChanged: (v) => setDialogState(() => private = v),
                    ),
                    SwitchListTile(
                      title: const Text('التوصيل المجمع'),
                      value: batch,
                      onChanged: (v) => setDialogState(() => batch = v),
                    ),
                    SwitchListTile(
                      title: const Text('استقبال عروض جديدة'),
                      value: offers,
                      onChanged: (v) => setDialogState(() => offers = v),
                    ),
                    TextFormField(
                      controller: radius,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'نطاق العروض (كم)'),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        return n != null && n >= 1 && n <= 500 ? null : 'من 1 إلى 500 كم';
                      },
                    ),
                    TextFormField(
                      controller: timeout,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'مهلة العرض (ثانية)'),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        return n != null && n >= 30 && n <= 180 ? null : 'من 30 إلى 180 ثانية';
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() == true) Navigator.pop(ctx, true);
                },
                child: const Text('حفظ التفضيلات'),
              ),
            ],
          ),
        ),
      );
      if (entered != true || !mounted) return false;
      await api.updateDriverPreferences(
        acceptScheduledTrips: scheduled,
        acceptPrivateDeliveries: private,
        acceptBatchDeliveries: batch,
        isAvailableForOffers: offers,
        offerRadiusKm: double.parse(radius.text.trim()),
        offerTimeoutSeconds: int.parse(timeout.text.trim()),
      );
      return true;
    } finally {
      radius.dispose();
      timeout.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bankControls = widget.screenNumber == 10 || widget.screenNumber == 30;
    final preferenceControls = widget.screenNumber == 12 || widget.screenNumber == 16;
    if (!bankControls && !preferenceControls) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            if (bankControls) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : () => _run(_editBank),
                  child: const Text('تعديل الحساب البنكي'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : () => _run(_requestPayout),
                  child: const Text('طلب سحب'),
                ),
              ),
            ],
            if (preferenceControls)
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy ? null : () => _run(_editPreferences),
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('تعديل تفضيلات الرحلات'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
