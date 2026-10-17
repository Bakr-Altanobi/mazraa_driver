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

  Future<bool> _manageScheduledTrips() async {
    final api = ref.read(driverApiProvider);
    final rows = await api.getScheduledTrips();
    if (!mounted) return false;
    final tripRows = rows.whereType<Map<String, dynamic>>().toList(growable: false);
    if (tripRows.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('الرحلات المجدولة'),
          content: const Text('لا توجد رحلات مجدولة متاحة من السيرفر حاليًا.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
          ],
        ),
      );
      return false;
    }

    final selection = await showDialog<(int, bool)>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('الرحلات المجدولة'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final row in tripRows)
                Builder(
                  builder: (context) {
                    final trip = row['trip'] is Map
                        ? Map<String, dynamic>.from(row['trip'] as Map)
                        : <String, dynamic>{};
                    final participation = row['participation'] is Map
                        ? Map<String, dynamic>.from(row['participation'] as Map)
                        : <String, dynamic>{};
                    final tripId = int.tryParse('${trip['id'] ?? ''}');
                    if (tripId == null || tripId <= 0) {
                      return const SizedBox.shrink();
                    }
                    final status = '${participation['status'] ?? ''}'.toLowerCase();
                    final approved = status == 'approved' || status == '1';
                    final requested = status == 'requested' || status == '0';
                    final departure = trip['plannedDepartureAt']?.toString() ?? '';
                    return ListTile(
                      title: Text('${trip['tripCode'] ?? 'رحلة #$tripId'}'),
                      subtitle: Text(approved
                          ? 'مُعتمدة من العمليات · $departure'
                          : requested
                              ? 'بانتظار الموافقة · $departure'
                              : 'يمكن طلب الانضمام · $departure'),
                      trailing: approved
                          ? const Icon(Icons.verified_outlined)
                          : Icon(requested ? Icons.exit_to_app_rounded : Icons.add_circle_outline_rounded),
                      onTap: approved
                          ? null
                          : () => Navigator.pop(ctx, (tripId, !requested)),
                    );
                  },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
    if (selection == null || !mounted) return false;
    final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(selection.$2 ? 'طلب الانضمام إلى الرحلة' : 'الانسحاب من الرحلة'),
            content: Text('سيتم إرسال القرار إلى السيرفر للرحلة #${selection.$1}.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('تأكيد'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirm || !mounted) return false;
    if (selection.$2) {
      await api.joinScheduledTrip(selection.$1);
    } else {
      await api.withdrawScheduledTrip(selection.$1);
    }
    return true;
  }

  Future<bool> _manageReturnTasks() async {
    final api = ref.read(driverApiProvider);
    final rows = await api.getReturnTasks();
    if (!mounted) return false;
    final tasks = rows.whereType<Map<String, dynamic>>().toList(growable: false);
    final eligible = <(int, String, Map<String, dynamic>)>[];
    for (final task in tasks) {
      final id = int.tryParse('${task['id'] ?? ''}');
      final status = '${task['status'] ?? ''}'.replaceAll('_', '').toLowerCase();
      if (id == null || id <= 0) continue;
      final action = switch (status) {
        'assigned' || '0' => 'accept',
        'accepted' || '1' => 'pickup',
        'pickedup' || '2' => 'complete',
        _ => null,
      };
      if (action != null) eligible.add((id, action, task));
    }
    if (eligible.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('المهام المرتجعة'),
          content: const Text('لا توجد مهمة مرتجع تسمح حالتها بتنفيذ خطوة جديدة.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      );
      return false;
    }
    final chosen = await showDialog<(int, String)>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حدد مهمة المرتجع'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final task in eligible)
                ListTile(
                  title: Text('مرتجع #${task.$3['returnRequestId'] ?? task.$1}'),
                  subtitle: Text(switch (task.$2) {
                    'accept' => 'قبول مهمة المرتجع',
                    'pickup' => 'تأكيد الاستلام من العميل',
                    _ => 'تأكيد إرجاع المرتجع للمتجر',
                  }),
                  onTap: () => Navigator.pop(ctx, (task.$1, task.$2)),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
    if (chosen == null || !mounted) return false;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('تأكيد إجراء المرتجع'),
            content: Text('سيتم إرسال العملية لمهمة المرتجع #${chosen.$1} إلى السيرفر.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('تأكيد'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return false;
    switch (chosen.$2) {
      case 'accept':
        await api.acceptReturnTask(chosen.$1);
      case 'pickup':
        await api.pickupReturnTask(chosen.$1);
      case 'complete':
        await api.completeReturnTask(chosen.$1);
    }
    return true;
  }

  static int? _parseDayOfWeek(Object? value) {
    final number = int.tryParse('${value ?? ''}');
    if (number != null) return number >= 0 && number <= 6 ? number : null;
    const days = ['sunday', 'monday', 'tuesday', 'wednesday',
      'thursday', 'friday', 'saturday'];
    final day = '${value ?? ''}'.toLowerCase();
    final index = days.indexOf(day);
    return index < 0 ? null : index;
  }

  Future<bool> _editAvailability() async {
    final api = ref.read(driverApiProvider);
    final fromServer = await api.getDriverAvailability();
    if (!mounted) return false;
    final saved = <Map<String, dynamic>>[];
    for (final raw in fromServer) {
      if (raw is! Map<String, dynamic>) {
        throw StateError('صيغة جدول التوفر من السيرفر غير متوقعة.');
      }
      final day = _parseDayOfWeek(raw['dayOfWeek']);
      final start = raw['startTime']?.toString();
      final end = raw['endTime']?.toString();
      if (day == null || start == null || end == null ||
          raw['isActive'] is! bool) {
        throw StateError('لا يمكن تعديل الجدول دون فهم كل النوافذ المحفوظة.');
      }
      saved.add({
        'dayOfWeek': day,
        'startTime': start,
        'endTime': end,
        'isActive': raw['isActive'],
      });
    }
    const weekdayNames = ['الأحد', 'الاثنين', 'الثلاثاء',
      'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
    final index = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('اختر نافذة توفر لتعديلها'),
        children: [
          for (var i = 0; i < saved.length; i++)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, i),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Text('${weekdayNames[saved[i]['dayOfWeek'] as int]} · '
                  '${saved[i]['startTime']} – ${saved[i]['endTime']}'),
              ),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, -1),
            child: const ListTile(
              leading: Icon(Icons.add_circle_outline_rounded),
              title: Text('إضافة نافذة توفر جديدة'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
    if (index == null || !mounted) return false;
    final original = index >= 0 ? saved[index] : null;
    var day = original?['dayOfWeek'] as int? ?? 0;
    var active = original?['isActive'] as bool? ?? true;
    String clock(Object? v) {
      final value = (v ?? '').toString();
      return value.length >= 5 ? value.substring(0, 5) : value;
    }
    final start = TextEditingController(text: clock(original?['startTime']));
    final end = TextEditingController(text: clock(original?['endTime']));
    try {
      final formKey = GlobalKey<FormState>();
      final entry = await showDialog<(int, String, String, bool)>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, redraw) => AlertDialog(
            title: Text(index == -1 ? 'نافذة توفر جديدة' : 'تعديل نافذة التوفر'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: day,
                      decoration: const InputDecoration(labelText: 'اليوم'),
                      items: [
                        for (var d = 0; d < 7; d++)
                          DropdownMenuItem(value: d, child: Text(weekdayNames[d])),
                      ],
                      onChanged: (value) => redraw(() => day = value ?? day),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: start,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(labelText: 'البداية HH:mm'),
                      validator: (v) => RegExp(r'^(?:[01]\\d|2[0-3]):[0-5]\\d = widget.screenNumber == 10 || widget.screenNumber == 30;
    final preferenceControls = widget.screenNumber == 12 || widget.screenNumber == 16;
    final scheduledControls = widget.screenNumber == 16;
    final returnControls = widget.screenNumber == 39;
    final availabilityControls = widget.screenNumber == 16;
    if (!bankControls && !preferenceControls && !scheduledControls &&
        !returnControls && !availabilityControls) {
      return const SizedBox.shrink();
    }
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
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
                  label: const Text('تفضيلات الرحلات'),
                ),
              ),
            if (scheduledControls) ...[
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('manageScheduledTripsButton'),
                  onPressed: _busy ? null : () => _run(_manageScheduledTrips),
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('الرحلات المجدولة'),
                ),
              ),
            ],
            if (returnControls)
              Expanded(
                child: FilledButton.icon(
                  key: const Key('manageReturnTasksButton'),
                  onPressed: _busy ? null : () => _run(_manageReturnTasks),
                  icon: const Icon(Icons.assignment_return_outlined),
                  label: const Text('تنفيذ خطوة المرتجع'),
                ),
              ),
              ],
            ),
            if (availabilityControls) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('editAvailabilityButton'),
                  onPressed: _busy ? null : () => _run(_editAvailability),
                  icon: const Icon(Icons.edit_calendar_rounded),
                  label: const Text('تحرير جدول التوفر الأسبوعي'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
).hasMatch(v ?? '')
                          ? null : 'أدخل وقتًا صحيحًا 00:00–23:59',
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: end,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(labelText: 'النهاية HH:mm'),
                      validator: (v) {
                        if (!RegExp(r'^(?:[01]\\d|2[0-3]):[0-5]\\d = widget.screenNumber == 10 || widget.screenNumber == 30;
    final preferenceControls = widget.screenNumber == 12 || widget.screenNumber == 16;
    final scheduledControls = widget.screenNumber == 16;
    final returnControls = widget.screenNumber == 39;
    if (!bankControls && !preferenceControls && !scheduledControls && !returnControls) {
      return const SizedBox.shrink();
    }
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
                  label: const Text('تفضيلات الرحلات'),
                ),
              ),
            if (scheduledControls) ...[
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('manageScheduledTripsButton'),
                  onPressed: _busy ? null : () => _run(_manageScheduledTrips),
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('الرحلات المجدولة'),
                ),
              ),
            ],
            if (returnControls)
              Expanded(
                child: FilledButton.icon(
                  key: const Key('manageReturnTasksButton'),
                  onPressed: _busy ? null : () => _run(_manageReturnTasks),
                  icon: const Icon(Icons.assignment_return_outlined),
                  label: const Text('تنفيذ خطوة المرتجع'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
).hasMatch(v ?? '')) {
                          return 'أدخل وقتًا صحيحًا';
                        }
                        return (v!.compareTo(start.text) > 0)
                            ? null : 'وقت النهاية يجب أن يكون بعد البداية';
                      },
                    ),
                    SwitchListTile(
                      title: const Text('النافذة نشطة'),
                      value: active,
                      onChanged: (value) => redraw(() => active = value),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() == true) {
                    Navigator.pop(ctx, (day, start.text, end.text, active));
                  }
                },
                child: const Text('متابعة'),
              ),
            ],
          ),
        ),
      );
      if (entry == null || !mounted) return false;
      final proposed = <String, dynamic>{
        'dayOfWeek': entry.$1,
        'startTime': '${entry.$2}:00',
        'endTime': '${entry.$3}:00',
        'isActive': entry.$4,
      };
      if (index == -1) {
        saved.add(proposed);
      } else {
        saved[index] = proposed;
      }
      final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('حفظ جدول التوفر'),
              content: Text(
                'سيُرسل الجدول الكامل مع الحفاظ على النوافذ الأخرى '
                '(${saved.length} نافذة). تأكد من الأوقات قبل المتابعة.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('حفظ في السيرفر'),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirmed || !mounted) return false;
      await api.updateDriverAvailability(saved);
      return true;
    } finally {
      start.dispose();
      end.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bankControls = widget.screenNumber == 10 || widget.screenNumber == 30;
    final preferenceControls = widget.screenNumber == 12 || widget.screenNumber == 16;
    final scheduledControls = widget.screenNumber == 16;
    final returnControls = widget.screenNumber == 39;
    if (!bankControls && !preferenceControls && !scheduledControls && !returnControls) {
      return const SizedBox.shrink();
    }
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
                  label: const Text('تفضيلات الرحلات'),
                ),
              ),
            if (scheduledControls) ...[
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('manageScheduledTripsButton'),
                  onPressed: _busy ? null : () => _run(_manageScheduledTrips),
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('الرحلات المجدولة'),
                ),
              ),
            ],
            if (returnControls)
              Expanded(
                child: FilledButton.icon(
                  key: const Key('manageReturnTasksButton'),
                  onPressed: _busy ? null : () => _run(_manageReturnTasks),
                  icon: const Icon(Icons.assignment_return_outlined),
                  label: const Text('تنفيذ خطوة المرتجع'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
