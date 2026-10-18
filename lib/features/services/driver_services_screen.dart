import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/core/network/providers.dart';
import 'package:mazraa_driver/core/theme/app_theme.dart';
import 'package:mazraa_driver/features/auth/auth_controller.dart';
import 'package:mazraa_driver/features/reference_journey/reference_assets.dart';
import 'package:mazraa_driver/shared/widgets/mazraa_widgets.dart';

class DriverServicesScreen extends ConsumerWidget {
  const DriverServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ar = isArabic(context);
    final profile = ref.watch(authControllerProvider).profile;
    return Scaffold(
      appBar: AppBar(
        title: Text(ar ? 'المزيد' : 'More'),
        actions: [
          IconButton(
            tooltip: ar ? 'تحديث الحساب' : 'Refresh profile',
            onPressed: () => ref.read(authControllerProvider).refreshProfile(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [MazraaColors.forest, MazraaColors.forestDark],
              ),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Row(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Image.asset(
                    ReferenceAssets.driverAvatar,
                    fit: BoxFit.contain,
                    cacheWidth: 220,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.name ?? (ar ? 'حساب السائق' : 'Driver account'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        profile?.driverCode ??
                            (ar ? 'خدمات السائق' : 'Driver services'),
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      StatusPill(
                        label: profile?.isApproved == true
                            ? (ar ? 'حساب معتمد' : 'Approved')
                            : (ar ? 'حالة الحساب' : 'Account status'),
                        color: profile?.isApproved == true
                            ? const Color(0xFFBDE8C9)
                            : const Color(0xFFFFD49E),
                        icon: profile?.isApproved == true
                            ? Icons.verified_rounded
                            : Icons.info_outline_rounded,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _MenuSection(
            title: ar ? 'الحساب والعمل' : 'Account & work',
            children: [
              _MenuTile(
                icon: Icons.person_outline_rounded,
                title: ar ? 'الملف الشخصي' : 'Profile',
                route: '/profile-details',
              ),
              _MenuTile(
                icon: Icons.tune_rounded,
                title: ar ? 'تفضيلات التوصيل' : 'Delivery preferences',
                route: '/preferences',
              ),
              _MenuTile(
                icon: Icons.calendar_month_outlined,
                title: ar ? 'جدول التوفر' : 'Availability schedule',
                route: '/availability',
              ),
              _MenuTile(
                icon: Icons.event_available_outlined,
                title: ar ? 'الرحلات المجدولة' : 'Scheduled trips',
                route: '/scheduled-trips',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _MenuSection(
            title: ar ? 'المال والمزايا' : 'Money & rewards',
            children: [
              _MenuTile(
                icon: Icons.account_balance_wallet_outlined,
                title: ar ? 'المحفظة والأرباح' : 'Wallet & earnings',
                route: '/wallet',
              ),
              _MenuTile(
                icon: Icons.account_balance_outlined,
                title: ar ? 'الحساب البنكي والسحب' : 'Bank & payouts',
                route: '/bank-payout',
              ),
              _MenuTile(
                icon: Icons.workspace_premium_outlined,
                title: ar ? 'الحوافز والمكافآت' : 'Incentives',
                route: '/journey/17',
              ),
              _MenuTile(
                icon: Icons.share_outlined,
                title: ar ? 'إحالة صديق' : 'Refer a friend',
                route: '/journey/24',
              ),
              _MenuTile(
                icon: Icons.insights_outlined,
                title: ar ? 'الأداء والتقييم' : 'Performance',
                route: '/journey/32',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _MenuSection(
            title: ar ? 'المركبة والعمليات' : 'Vehicle & operations',
            children: [
              _MenuTile(
                icon: Icons.badge_outlined,
                title: ar ? 'وثائق السائق والمركبة' : 'Driver documents',
                route: '/journey/14',
              ),
              _MenuTile(
                icon: Icons.build_outlined,
                title: ar ? 'صيانة المركبة' : 'Vehicle maintenance',
                route: '/journey/42',
              ),
              _MenuTile(
                icon: Icons.assignment_return_outlined,
                title: ar ? 'مهام المرتجعات' : 'Return tasks',
                route: '/returns',
              ),
              _MenuTile(
                icon: Icons.report_problem_outlined,
                title: ar ? 'البلاغات والمشكلات' : 'Incidents',
                route: '/journey/45',
              ),
              _MenuTile(
                icon: Icons.map_outlined,
                title: ar ? 'منطقة الخدمة' : 'Service area',
                route: '/journey/35',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _MenuSection(
            title: ar ? 'الدعم والإعدادات' : 'Support & settings',
            children: [
              _MenuTile(
                icon: Icons.support_agent_rounded,
                title: ar ? 'مركز الدعم' : 'Support center',
                route: '/journey/21',
              ),
              _MenuTile(
                icon: Icons.settings_outlined,
                title: ar ? 'الإعدادات' : 'Settings',
                route: '/settings',
              ),
              _MenuTile(
                icon: Icons.fact_check_outlined,
                title: ar ? 'رحلة الشاشات الكاملة' : 'Full driver journey',
                route: '/journey/03',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DriverPreferencesScreen extends ConsumerStatefulWidget {
  const DriverPreferencesScreen({super.key});

  @override
  ConsumerState<DriverPreferencesScreen> createState() =>
      _DriverPreferencesScreenState();
}

class _DriverPreferencesScreenState
    extends ConsumerState<DriverPreferencesScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _scheduled = true;
  bool _private = true;
  bool _batch = true;
  bool _offers = true;
  double _radius = 50;
  int _timeout = 60;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final json = await ref.read(driverApiProvider).getDriverPreferences();
      if (!mounted) return;
      setState(() {
        _scheduled = json['acceptScheduledTrips'] != false;
        _private = json['acceptPrivateDeliveries'] != false;
        _batch = json['acceptBatchDeliveries'] != false;
        _offers = json['isAvailableForOffers'] != false;
        _radius = _double(json['offerRadiusKm'], 50).clamp(1, 500);
        _timeout = _int(json['offerTimeoutSeconds'], 60).clamp(30, 180);
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(driverApiProvider).updateDriverPreferences(
            acceptScheduledTrips: _scheduled,
            acceptPrivateDeliveries: _private,
            acceptBatchDeliveries: _batch,
            isAvailableForOffers: _offers,
            offerRadiusKm: _radius,
            offerTimeoutSeconds: _timeout,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ تفضيلات التوصيل على السيرفر.')),
        );
      }
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    return Scaffold(
      appBar: AppBar(title: Text(ar ? 'تفضيلات التوصيل' : 'Preferences')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _RetryState(message: _error!, onRetry: _load)
              : ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    _SwitchCard(
                      title: ar ? 'العروض المباشرة' : 'Live offers',
                      value: _offers,
                      onChanged: (v) => setState(() => _offers = v),
                    ),
                    _SwitchCard(
                      title: ar ? 'الرحلات المجدولة' : 'Scheduled trips',
                      value: _scheduled,
                      onChanged: (v) => setState(() => _scheduled = v),
                    ),
                    _SwitchCard(
                      title: ar ? 'التوصيلات الخاصة' : 'Private deliveries',
                      value: _private,
                      onChanged: (v) => setState(() => _private = v),
                    ),
                    _SwitchCard(
                      title: ar ? 'الطلبات المجمعة' : 'Batch deliveries',
                      value: _batch,
                      onChanged: (v) => setState(() => _batch = v),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${ar ? 'نطاق استقبال العروض' : 'Offer radius'}: ${_radius.toStringAsFixed(0)} كم',
                            ),
                            Slider(
                              value: _radius,
                              min: 1,
                              max: 100,
                              divisions: 99,
                              label: '${_radius.toStringAsFixed(0)} km',
                              onChanged: (v) => setState(() => _radius = v),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${ar ? 'مهلة العرض' : 'Offer timeout'}: $_timeout ${ar ? 'ثانية' : 'sec'}',
                            ),
                            Slider(
                              value: _timeout.toDouble(),
                              min: 30,
                              max: 180,
                              divisions: 15,
                              onChanged: (v) =>
                                  setState(() => _timeout = v.round()),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(ar ? 'حفظ على السيرفر' : 'Save'),
                    ),
                  ],
                ),
    );
  }
}

class DriverAvailabilityScreen extends ConsumerStatefulWidget {
  const DriverAvailabilityScreen({super.key});

  @override
  ConsumerState<DriverAvailabilityScreen> createState() =>
      _DriverAvailabilityScreenState();
}

class _DriverAvailabilityScreenState
    extends ConsumerState<DriverAvailabilityScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<Map<String, dynamic>> _windows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await ref.read(driverApiProvider).getAvailability();
      if (!mounted) return;
      setState(() {
        _windows = _maps(rows)
            .map((row) => {
                  'dayOfWeek': _int(row['dayOfWeek'], 0),
                  'startTime': _timeText(row['startTime'], '08:00:00'),
                  'endTime': _timeText(row['endTime'], '18:00:00'),
                  'isActive': row['isActive'] != false,
                })
            .toList();
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _add() async {
    var day = DateTime.now().weekday % 7;
    var start = const TimeOfDay(hour: 8, minute: 0);
    var end = const TimeOfDay(hour: 18, minute: 0);
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('إضافة نافذة توفر'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: day,
                decoration: const InputDecoration(labelText: 'اليوم'),
                items: List.generate(
                  7,
                  (index) => DropdownMenuItem(
                    value: index,
                    child: Text(_dayLabel(index)),
                  ),
                ),
                onChanged: (value) => setLocal(() => day = value ?? day),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('من'),
                trailing: Text(start.format(context)),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: start,
                  );
                  if (picked != null) setLocal(() => start = picked);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('إلى'),
                trailing: Text(end.format(context)),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: end,
                  );
                  if (picked != null) setLocal(() => end = picked);
                },
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
                final a = start.hour * 60 + start.minute;
                final b = end.hour * 60 + end.minute;
                if (b <= a) return;
                Navigator.pop(dialogContext, {
                  'dayOfWeek': day,
                  'startTime': _encodeTime(start),
                  'endTime': _encodeTime(end),
                  'isActive': true,
                });
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
    if (result != null) setState(() => _windows.add(result));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(driverApiProvider).updateAvailability(_windows);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ جدول التوفر على السيرفر.')),
        );
      }
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جدول التوفر'),
        actions: [
          IconButton(onPressed: _add, icon: const Icon(Icons.add_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _RetryState(message: _error!, onRetry: _load)
              : ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    if (_windows.isEmpty)
                      const _EmptyCard('لا توجد نوافذ توفر محفوظة. أضف أول نافذة.'),
                    for (var i = 0; i < _windows.length; i++)
                      Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text('${i + 1}'),
                          ),
                          title: Text(_dayLabel(_int(_windows[i]['dayOfWeek'], 0))),
                          subtitle: Text(
                            '${_windows[i]['startTime']} — ${_windows[i]['endTime']}',
                            textDirection: TextDirection.ltr,
                          ),
                          trailing: IconButton(
                            tooltip: 'حذف',
                            onPressed: () => setState(() => _windows.removeAt(i)),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.cloud_done_outlined),
                      label: const Text('حفظ الجدول على السيرفر'),
                    ),
                  ],
                ),
    );
  }
}

class ScheduledTripsScreen extends ConsumerStatefulWidget {
  const ScheduledTripsScreen({super.key});

  @override
  ConsumerState<ScheduledTripsScreen> createState() =>
      _ScheduledTripsScreenState();
}

class _ScheduledTripsScreenState extends ConsumerState<ScheduledTripsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];
  int? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await ref.read(driverApiProvider).getScheduledTrips();
      if (!mounted) return;
      setState(() {
        _rows = _maps(rows);
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _act(int id, bool withdraw) async {
    setState(() => _busyId = id);
    try {
      final api = ref.read(driverApiProvider);
      if (withdraw) {
        await api.withdrawScheduledTrip(id);
      } else {
        await api.joinScheduledTrip(id);
      }
      await _load();
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الرحلات المجدولة'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _RetryState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(18),
                    children: [
                      if (_rows.isEmpty)
                        const _EmptyCard('لا توجد رحلات مجدولة متاحة حاليًا.'),
                      for (final row in _rows) _tripCard(row),
                    ],
                  ),
                ),
    );
  }

  Widget _tripCard(Map<String, dynamic> row) {
    final trip = _map(row['trip']);
    final participation = _map(row['participation']);
    final id = _int(trip['id'], 0);
    final status = _norm(participation['status']);
    final requested = participation.isNotEmpty &&
        (status == '0' || status == 'requested');
    final approved = status == '1' || status == 'approved';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${trip['name'] ?? trip['tripNumber'] ?? 'رحلة #$id'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('موعد المغادرة: ${trip['plannedDepartureAt'] ?? '—'}'),
            Text('الحالة: ${trip['status'] ?? '—'}'),
            if (participation.isNotEmpty)
              Text('حالة مشاركتك: ${participation['status'] ?? '—'}'),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: _busyId == id || approved || id == 0
                  ? null
                  : () => _act(id, requested),
              icon: Icon(requested
                  ? Icons.undo_rounded
                  : approved
                      ? Icons.verified_rounded
                      : Icons.add_task_rounded),
              label: Text(requested
                  ? 'سحب طلب المشاركة'
                  : approved
                      ? 'تم اعتماد مشاركتك'
                      : 'طلب الانضمام للرحلة'),
            ),
          ],
        ),
      ),
    );
  }
}

class BankPayoutScreen extends ConsumerStatefulWidget {
  const BankPayoutScreen({super.key});

  @override
  ConsumerState<BankPayoutScreen> createState() => _BankPayoutScreenState();
}

class _BankPayoutScreenState extends ConsumerState<BankPayoutScreen> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  WalletSummary? _wallet;
  List<Map<String, dynamic>> _banks = [];
  List<Map<String, dynamic>> _payouts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(driverApiProvider);
      final values = await Future.wait<Object?>([
        api.getWallet(),
        api.getBankAccounts(),
        api.getPayouts(),
      ]);
      if (!mounted) return;
      setState(() {
        _wallet = values[0] as WalletSummary;
        _banks = _maps(values[1] as List<dynamic>);
        _payouts = _maps(values[2] as List<dynamic>);
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _editBank() async {
    final current = _banks.isEmpty ? const <String, dynamic>{} : _banks.first;
    final bank = TextEditingController(text: '${current['bankName'] ?? ''}');
    final holder = TextEditingController(
      text: '${current['accountHolderName'] ?? ''}',
    );
    final iban = TextEditingController(text: '${current['iban'] ?? ''}');
    final account = TextEditingController(
      text: '${current['accountNumber'] ?? ''}',
    );
    final result = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('الحساب البنكي'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: bank, decoration: const InputDecoration(labelText: 'اسم البنك')),
              const SizedBox(height: 10),
              TextField(controller: holder, decoration: const InputDecoration(labelText: 'اسم صاحب الحساب')),
              const SizedBox(height: 10),
              TextField(controller: iban, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'IBAN')),
              const SizedBox(height: 10),
              TextField(controller: account, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'رقم الحساب (اختياري)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              if (bank.text.trim().isEmpty || holder.text.trim().isEmpty || iban.text.trim().isEmpty) return;
              Navigator.pop(dialogContext, [bank.text, holder.text, iban.text, account.text]);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    bank.dispose();
    holder.dispose();
    iban.dispose();
    account.dispose();
    if (result == null) return;
    await _run(() => ref.read(driverApiProvider).putBankAccount(
          bankName: result[0],
          accountHolderName: result[1],
          iban: result[2],
          accountNumber: result[3].trim().isEmpty ? null : result[3],
        ));
  }

  Future<void> _requestPayout() async {
    if (_banks.isEmpty || _wallet == null) {
      _showError(context, 'أضف حسابًا بنكيًا أولًا.');
      return;
    }
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('طلب سحب'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            labelText: 'المبلغ (${_wallet!.currency})',
            helperText: 'الرصيد: ${_wallet!.balance.toStringAsFixed(2)}',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());
              if (value != null && value > 0) Navigator.pop(dialogContext, value);
            },
            child: const Text('إرسال الطلب'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (amount == null) return;
    final bankId = _int(_banks.first['id'], 0);
    if (bankId == 0) return;
    await _run(() => ref.read(driverApiProvider).requestPayout(
          bankAccountId: bankId,
          amount: amount,
          currency: _wallet!.currency,
        ));
  }

  Future<void> _run(Future<Object?> Function() operation) async {
    setState(() => _busy = true);
    try {
      await operation();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ العملية على السيرفر.')),
        );
      }
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الحساب البنكي والسحب'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _RetryState(message: _error!, onRetry: _load)
              : ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    if (_wallet != null)
                      Row(
                        children: [
                          Expanded(
                            child: MetricCard(
                              title: 'الرصيد',
                              value: '${_wallet!.balance.toStringAsFixed(2)} ${_wallet!.currency}',
                              icon: Icons.account_balance_wallet_outlined,
                              accent: MazraaColors.forest,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.account_balance_outlined),
                        title: Text(_banks.isEmpty ? 'لا يوجد حساب بنكي' : '${_banks.first['bankName'] ?? 'حساب بنكي'}'),
                        subtitle: Text(_banks.isEmpty ? 'أضف الحساب الذي تستقبل عليه السحوبات.' : '${_banks.first['iban'] ?? ''}', textDirection: TextDirection.ltr),
                        trailing: const Icon(Icons.edit_outlined),
                        onTap: _busy ? null : _editBank,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _busy ? null : _requestPayout,
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('طلب سحب من المحفظة'),
                    ),
                    const SizedBox(height: 20),
                    SectionHeader(title: 'طلبات السحب السابقة', icon: Icons.history_rounded),
                    const SizedBox(height: 8),
                    if (_payouts.isEmpty) const _EmptyCard('لا توجد طلبات سحب سابقة.'),
                    for (final row in _payouts)
                      Card(
                        child: ListTile(
                          title: Text('${row['amount'] ?? '—'} ${row['currency'] ?? ''}'),
                          subtitle: Text('الحالة: ${row['status'] ?? '—'}\n${row['requestedAt'] ?? ''}'),
                          isThreeLine: true,
                        ),
                      ),
                  ],
                ),
    );
  }
}

class ReturnTasksScreen extends ConsumerStatefulWidget {
  const ReturnTasksScreen({super.key});

  @override
  ConsumerState<ReturnTasksScreen> createState() => _ReturnTasksScreenState();
}

class _ReturnTasksScreenState extends ConsumerState<ReturnTasksScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];
  int? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await ref.read(driverApiProvider).getReturnTasks();
      if (!mounted) return;
      setState(() {
        _rows = _maps(rows);
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _next(Map<String, dynamic> row) async {
    final id = _int(row['id'], 0);
    if (id == 0) return;
    final status = _norm(row['status']);
    setState(() => _busyId = id);
    try {
      final api = ref.read(driverApiProvider);
      if (status == '0' || status == 'assigned') {
        await api.acceptReturnTask(id);
      } else if (status == '1' || status == 'accepted') {
        await api.pickupReturnTask(id);
      } else if (status == '2' || status == 'pickedup') {
        await api.completeReturnTask(id);
      }
      await _load();
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مهام المرتجعات'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _RetryState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(18),
                    children: [
                      if (_rows.isEmpty)
                        const _EmptyCard('لا توجد مهام مرتجع مسندة إليك.'),
                      for (final row in _rows) _returnCard(row),
                    ],
                  ),
                ),
    );
  }

  Widget _returnCard(Map<String, dynamic> row) {
    final id = _int(row['id'], 0);
    final status = _norm(row['status']);
    final completed = status == '3' ||
        status == 'returnedtostore' ||
        status == 'completed';
    final label = switch (status) {
      '0' || 'assigned' => 'قبول مهمة المرتجع',
      '1' || 'accepted' => 'تأكيد استلام المرتجع',
      '2' || 'pickedup' => 'تأكيد الإرجاع للمتجر',
      _ => 'مكتملة',
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('مهمة مرتجع #$id', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 7),
            Text('الشحنة: ${row['shipmentId'] ?? '—'}'),
            Text('الحالة: ${row['status'] ?? '—'}'),
            Text('سبب الإرجاع: ${row['reason'] ?? '—'}'),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: completed || _busyId == id ? null : () => _next(row),
              icon: Icon(completed ? Icons.verified_rounded : Icons.arrow_forward_rounded),
              label: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          Card(child: Column(children: children)),
        ],
      );
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.title, required this.route});
  final IconData icon;
  final String title;
  final String route;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.push(route),
      );
}

class _SwitchCard extends StatelessWidget {
  const _SwitchCard({required this.title, required this.value, required this.onChanged});
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Card(
        child: SwitchListTile(
          title: Text(title),
          value: value,
          onChanged: onChanged,
        ),
      );
}

class _RetryState extends StatelessWidget {
  const _RetryState({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 44),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(Icons.inbox_outlined),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry('$key', value));
  return const {};
}

List<Map<String, dynamic>> _maps(List<dynamic> values) =>
    values.map(_map).where((item) => item.isNotEmpty).toList();

int _int(Object? value, int fallback) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;

double _double(Object? value, double fallback) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? fallback;

String _norm(Object? value) =>
    '${value ?? ''}'.replaceAll('_', '').replaceAll(' ', '').toLowerCase();

String _timeText(Object? value, String fallback) {
  final text = '${value ?? ''}';
  if (text.isEmpty) return fallback;
  final parts = text.split(':');
  if (parts.length < 2) return fallback;
  final h = parts[0].padLeft(2, '0');
  final m = parts[1].padLeft(2, '0');
  final s = parts.length > 2 ? parts[2].split('.').first.padLeft(2, '0') : '00';
  return '$h:$m:$s';
}

String _encodeTime(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';

String _dayLabel(int day) => switch (day) {
      0 => 'الأحد',
      1 => 'الاثنين',
      2 => 'الثلاثاء',
      3 => 'الأربعاء',
      4 => 'الخميس',
      5 => 'الجمعة',
      6 => 'السبت',
      _ => 'اليوم',
    };

void _showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(error.toString())),
  );
}
