import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mazraa_driver/features/auth/auth_controller.dart';
import 'package:mazraa_driver/features/reference_journey/reference_catalog.dart';
import 'package:mazraa_driver/features/reference_journey/reference_production_body.dart';
import 'package:mazraa_driver/features/reference_journey/reference_repository.dart';

class ReferenceJourneyScreen extends ConsumerStatefulWidget {
  const ReferenceJourneyScreen({required this.screenNumber, super.key});

  final int screenNumber;

  @override
  ConsumerState<ReferenceJourneyScreen> createState() =>
      _ReferenceJourneyScreenState();
}

class _ReferenceJourneyScreenState
    extends ConsumerState<ReferenceJourneyScreen> {
  bool _actionBusy = false;

  ReferenceScreenSpec get spec =>
      ReferenceCatalog.screen(widget.screenNumber);

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final userId = auth.profile?.userId;
    final sessionReady = userId != null;
    final key = userId == null
        ? null
        : ReferenceLoadKey(widget.screenNumber, userId);
    final asyncPayload = key == null
        ? null
        : ref.watch(referenceScreenPayloadProvider(key));

    return Scaffold(
      key: Key('referenceScreen${widget.screenNumber}'),
      appBar: AppBar(
        title: Text(
          '${widget.screenNumber.toString().padLeft(2, '0')} · ${spec.titleAr}',
        ),
        actions: [
          if (auth.isAuthenticated)
            IconButton(
              tooltip: 'الرئيسية',
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.home_outlined),
            ),
        ],
      ),
      body: ReferenceProductionBody(
        spec: spec,
        payload: asyncPayload?.valueOrNull,
        loading: asyncPayload?.isLoading ?? false,
        sessionReady: sessionReady,
        actionBusy: _actionBusy,
        onAction: (action) => _runAction(action, key),
        onPrevious: widget.screenNumber > 1
            ? () => context.go(_route(widget.screenNumber - 1))
            : null,
        onNext: widget.screenNumber < 48
            ? () => _goNext(context, auth)
            : () => context.go('/home'),
      ),
    );
  }

  void _goNext(BuildContext context, AuthController auth) {
    if (widget.screenNumber == 1) {
      context.go('/login');
      return;
    }
    if (widget.screenNumber == 2 && !auth.isAuthenticated) {
      context.go('/login');
      return;
    }
    context.go(_route(widget.screenNumber + 1));
  }

  String _route(int number) =>
      '/journey/${number.toString().padLeft(2, '0')}';

  Future<void> _runAction(
    ReferenceAction action,
    ReferenceLoadKey? key,
  ) async {
    if (_actionBusy) return;
    if (action == ReferenceAction.updatePreferences ||
        action == ReferenceAction.saveBankAccount ||
        action == ReferenceAction.requestPayout) {
      await _editAccountAction(action);
      return;
    }
    int? targetId;
    if (action != ReferenceAction.startShift &&
        action != ReferenceAction.endShift &&
        action != ReferenceAction.createIncident) {
      try {
        final targets = await ref.read(referenceRepositoryProvider).actionTargets(action);
        if (!mounted) return;
        if (targets.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لا توجد شحنات أو عروض مؤهلة لهذا الإجراء الآن.')),
          );
          return;
        }
        targetId = await showDialog<int>(
          context: context,
          builder: (dialogContext) => SimpleDialog(
            title: const Text('اختر الطلب المقصود'),
            children: [
              for (final target in targets)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(dialogContext, target['id'] as int),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      target['label'].toString() + ' · ' + target['status'].toString(),
                    ),
                  ),
                ),
            ],
          ),
        );
        if (targetId == null || !mounted) return;
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تعذر تحميل الطلبات من السيرفر: ' + error.toString())),
          );
        }
        return;
      }
    }

    String? reason;
    String? subject;
    String? message;
    if (action == ReferenceAction.failShipment) {
      reason = await _textDialog(
        title: 'سبب تعذر التسليم',
        label: 'السبب الذي سيُرسل إلى السيرفر',
        initialValue: 'تعذر الوصول للعميل',
      );
      if (reason == null) return;
    } else if (action == ReferenceAction.createIncident) {
      final incident = await _incidentDialog();
      if (incident == null) return;
      subject = incident.$1;
      message = incident.$2;
    } else {
      final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text(_actionTitle(action)),
              content: const Text(
                'سيتم تنفيذ العملية فقط على بيانات حقيقية مؤهلة حسب قواعد السيرفر. إذا لم توجد شحنة أو وردية أو عرض مؤهل فلن يتم إرسال تعديل غير صالح.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('تنفيذ'),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirmed) return;
    }

    setState(() => _actionBusy = true);
    try {
      final repository = ref.read(referenceRepositoryProvider);
      if (action == ReferenceAction.createIncident) {
        await repository.createIncident(
          subject: subject!,
          message: message!,
        );
      } else {
        await repository.runShipmentAction(action, reason: reason, targetId: targetId);
      }
      if (key != null) {
        ref.invalidate(referenceScreenPayloadProvider);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت العملية على السيرفر بنجاح.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  Future<void> _editAccountAction(ReferenceAction action) {
    if (action == ReferenceAction.updatePreferences) return _updatePreferences();
    if (action == ReferenceAction.saveBankAccount) return _updateBankAccount();
    return _requestPayout();
  }

  Future<void> _updatePreferences() async {
    setState(() => _actionBusy = true);
    try {
      final repository = ref.read(referenceRepositoryProvider);
      final original = await repository.loadPreferences();
      if (!mounted) return;
      const fields = [
        ('acceptScheduledTrips', 'الرحلات المجدولة'),
        ('acceptPrivateDeliveries', 'التوصيل الخاص'),
        ('acceptBatchDeliveries', 'التوصيل المجمع'),
        ('isAvailableForOffers', 'استقبال العروض'),
      ];
      if (!fields.every((field) => original[field.$1] is bool) ||
          original['offerRadiusKm'] == null ||
          original['offerTimeoutSeconds'] == null) {
        throw StateError('لم تصل التفضيلات كاملة من السيرفر.');
      }
      final values = Map<String, dynamic>.from(original);
      final save = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, update) => AlertDialog(
            title: const Text('تفضيلات السائق'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final field in fields)
                  SwitchListTile.adaptive(
                    title: Text(field.$2),
                    value: values[field.$1] == true,
                    onChanged: (value) => update(() => values[field.$1] = value),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('حفظ'),
              ),
            ],
          ),
        ),
      );
      if (save != true) return;
      await repository.savePreferences(values);
      ref.invalidate(referenceScreenPayloadProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث تفضيلات العمل على السيرفر.')),
      );
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }
  Future<void> _updateBankAccount() async {
    setState(() => _actionBusy = true);
    final input = <TextEditingController>[];
    try {
      final repository = ref.read(referenceRepositoryProvider);
      final accounts = await repository.loadBankAccounts();
      if (!mounted) return;
      final rows = accounts.whereType<Map>().toList();
      final current = rows.where((a) => a['isDefault'] == true).firstOrNull ??
          (rows.isEmpty ? null : rows.first);
      TextEditingController field(String name) {
        final controller = TextEditingController(text: current?[name]?.toString() ?? '');
        input.add(controller);
        return controller;
      }
      final bank = field('bankName');
      final holder = field('accountHolderName');
      final iban = field('iban');
      final number = field('accountNumber');
      var invalid = false;
      final save = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, update) => AlertDialog(
            title: const Text('الحساب البنكي للسائق'),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: bank,
                    decoration: const InputDecoration(labelText: 'اسم البنك')),
                TextField(controller: holder,
                    decoration: const InputDecoration(labelText: 'صاحب الحساب')),
                TextField(controller: iban, textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(labelText: 'IBAN')),
                TextField(controller: number, textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(labelText: 'رقم الحساب (اختياري)')),
                const SizedBox(height: 10),
                const Text('حفظ التغييرات يتطلب إعادة تحقق البنك من السيرفر.'),
                if (invalid) const Text('املأ اسم البنك وصاحب الحساب وIBAN.',
                    style: TextStyle(color: Colors.red)),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('إلغاء')),
              FilledButton(onPressed: () {
                if (bank.text.trim().isEmpty || holder.text.trim().isEmpty ||
                    iban.text.trim().isEmpty) {
                  update(() => invalid = true);
                  return;
                }
                Navigator.pop(dialogContext, true);
              }, child: const Text('حفظ')),
            ],
          ),
        ),
      );
      if (save != true) return;
      await repository.saveBankAccount(
        bankName: bank.text, holder: holder.text,
        iban: iban.text, accountNumber: number.text,
      );
      ref.invalidate(referenceScreenPayloadProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الحساب البنكي بانتظار التحقق.')),
      );
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      for (final controller in input) { controller.dispose(); }
      if (mounted) setState(() => _actionBusy = false);
    }
  }
  Future<void> _requestPayout() async {
    setState(() => _actionBusy = true);
    final amount = TextEditingController();
    try {
      final repository = ref.read(referenceRepositoryProvider);
      final rawAccounts = await repository.loadBankAccounts();
      final wallet = await repository.loadWallet();
      if (!mounted) return;
      final banks = rawAccounts.whereType<Map>().where((item) =>
          int.tryParse(item['id']?.toString() ?? '') != null).toList();
      if (banks.isEmpty) throw StateError('أضف حسابًا بنكيًا قبل طلب السحب.');
      final currency = (wallet['currencyCode'] ?? wallet['currency'])?.toString();
      if (currency == null || currency.trim().isEmpty) {
        throw StateError('عملة المحفظة غير متوفرة من السيرفر.');
      }
      int selected = int.parse(banks.first['id'].toString());
      var invalid = false;
      final save = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, update) => AlertDialog(
            title: const Text('إنشاء طلب سحب'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('الرصيد: ' + (wallet['balance']?.toString() ?? 'غير متوفر') +
                  ' ' + currency),
              DropdownButton<int>(
                isExpanded: true,
                value: selected,
                items: [for (final bank in banks)
                  DropdownMenuItem<int>(
                    value: int.parse(bank['id'].toString()),
                    child: Text((bank['bankName'] ?? '').toString() + ' · ' +
                        (bank['accountHolderName'] ?? '').toString(),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) update(() => selected = value);
                },
              ),
              TextField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'المبلغ (' + currency + ')'),
              ),
              if (invalid) const Text('أدخل مبلغًا صحيحًا أكبر من صفر.',
                  style: TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              const Text('هذا طلب سحب للمراجعة، وليس تأكيد تحويل فوري.'),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('إلغاء')),
              FilledButton(onPressed: () {
                final value = double.tryParse(amount.text.trim());
                if (value == null || !value.isFinite || value <= 0) {
                  update(() => invalid = true);
                  return;
                }
                Navigator.pop(dialogContext, true);
              }, child: const Text('إرسال الطلب')),
            ],
          ),
        ),
      );
      if (save != true) return;
      await repository.requestPayout(
        bankAccountId: selected,
        amount: double.parse(amount.text.trim()),
        currency: currency,
      );
      ref.invalidate(referenceScreenPayloadProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسجيل طلب السحب للمراجعة لدى السيرفر.')),
      );
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      amount.dispose();
      if (mounted) setState(() => _actionBusy = false);
    }
  }
  Future<String?> _textDialog({
    required String title,
    required String label,
    String initialValue = '',
  }) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<(String, String)?> _incidentDialog() async {
    final subject = TextEditingController();
    final message = TextEditingController();
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('رفع بلاغ إلى السيرفر'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: subject,
              decoration: const InputDecoration(labelText: 'عنوان البلاغ'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: message,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'تفاصيل البلاغ'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final a = subject.text.trim();
              final b = message.text.trim();
              if (a.isNotEmpty && b.isNotEmpty) {
                Navigator.pop(dialogContext, (a, b));
              }
            },
            child: const Text('رفع البلاغ'),
          ),
        ],
      ),
    );
    subject.dispose();
    message.dispose();
    return result;
  }
}

String _actionTitle(ReferenceAction action) => switch (action) {
      ReferenceAction.acceptShipment => 'قبول الشحنة',
      ReferenceAction.pickupShipment => 'تأكيد استلام الشحنة',
      ReferenceAction.startTransit => 'بدء التوجه للعميل',
      ReferenceAction.nearCustomer => 'تأكيد الوصول قرب العميل',
      ReferenceAction.deliverShipment => 'تأكيد تسليم الشحنة',
      ReferenceAction.failShipment => 'تسجيل تعذر التسليم',
      ReferenceAction.startShift => 'بدء الوردية',
      ReferenceAction.endShift => 'إنهاء الوردية',
      ReferenceAction.acceptOffer => 'قبول عرض التوصيل',
      ReferenceAction.rejectOffer => 'رفض عرض التوصيل',
      ReferenceAction.createIncident => 'رفع بلاغ',
      ReferenceAction.updatePreferences => 'تعديل التفضيلات',
      ReferenceAction.saveBankAccount => 'تعديل الحساب البنكي',
      ReferenceAction.requestPayout => 'طلب سحب من المحفظة',
    };
