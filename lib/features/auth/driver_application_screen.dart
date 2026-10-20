import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mazraa_driver/core/network/providers.dart';
import 'package:mazraa_driver/features/reference_journey/reference_assets.dart';
import 'package:mazraa_driver/shared/widgets/mazraa_widgets.dart';

/// Real server registration -> JWT -> driver application -> pending admin
/// approval. No synthetic driver approval or automatic activation is shown.
class DriverApplicationScreen extends ConsumerStatefulWidget {
  const DriverApplicationScreen({super.key});

  @override
  ConsumerState<DriverApplicationScreen> createState() => _DriverApplicationScreenState();
}

class _DriverApplicationScreenState extends ConsumerState<DriverApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _newAccount = true;
  bool _busy = false;
  bool _showPassword = false;
  int _vehicleType = 1;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    final ar = isArabic(context);
    final ok = await confirmAction(
      context,
      title: ar ? 'تقديم طلب الانضمام' : 'Apply to drive',
      message: ar
          ? 'سيتم إرسال طلبك إلى سيرفر مزرعتي للمراجعة. لا يمكنك استقبال الطلبات حتى اعتماد حسابك والتحقق منه.'
          : 'Your application will be sent for review. You cannot receive delivery offers until approval and verification.',
      confirmLabel: ar ? 'إرسال الطلب' : 'Submit application',
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(driverApiProvider).submitDriverApplication(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        vehicleType: _vehicleType,
        createAccount: _newAccount,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(ar ? 'تم استلام طلبك' : 'Application received'),
          content: Text(ar
              ? 'أصبح طلب الانضمام محفوظًا على السيرفر. انتظر مراجعة الإدارة ثم سجّل الدخول بحساب السائق عند الموافقة.'
              : 'Your application has been saved. After admin approval, sign in to your driver account.'),
          actions: [FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(ar ? 'حسنًا' : 'OK'),
          )],
        ),
      );
      if (mounted) context.go('/login');
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    final color = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(ar ? 'الانضمام كمندوب' : 'Become a driver')),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Image.asset(ReferenceAssets.identityScan,
                  height: 165, fit: BoxFit.contain, cacheWidth: 480),
              const SizedBox(height: 10),
              Text(ar ? 'ابدأ رحلتك مع مزرعتي' : 'Start driving with Mazraa',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(ar
                  ? 'حسابك وبيانات مركبتك تُرسل للسيرفر الحقيقي، ويبدأ العمل بعد موافقة الإدارة.'
                  : 'Your account and vehicle details are sent to the real server. Work starts after approval.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color.onSurfaceVariant,
                  )),
              const SizedBox(height: 22),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: true, label: Text(ar ? 'حساب جديد' : 'New account')),
                  ButtonSegment(value: false, label: Text(ar ? 'لدي حساب' : 'Existing account')),
                ],
                selected: {_newAccount},
                onSelectionChanged: _busy ? null : (v) => setState(() => _newAccount = v.first),
              ),
              const SizedBox(height: 16),
              if (_newAccount) ...[
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(labelText: ar ? 'الاسم الكامل' : 'Full name',
                    prefixIcon: const Icon(Icons.person_outline_rounded)),
                  validator: (v) => (v?.trim().length ?? 0) < 3
                      ? (ar ? 'الاسم مطلوب' : 'Name required') : null,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _email,
                textDirection: TextDirection.ltr,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: ar ? 'البريد الإلكتروني' : 'Email',
                  prefixIcon: const Icon(Icons.email_outlined)),
                validator: (v) => v == null || !v.contains('@')
                    ? (ar ? 'بريد إلكتروني غير صالح' : 'Invalid email') : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                textDirection: TextDirection.ltr,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  labelText: ar ? 'كلمة المرور' : 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                    icon: Icon(_showPassword
                        ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  ),
                ),
                validator: (v) => (v?.length ?? 0) < 8
                    ? (ar ? '8 أحرف على الأقل' : 'Minimum 8 characters') : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                initialValue: _vehicleType,
                decoration: InputDecoration(
                  labelText: ar ? 'نوع المركبة' : 'Vehicle type',
                  prefixIcon: const Icon(Icons.local_shipping_outlined),
                ),
                items: [
                  DropdownMenuItem(value: 0, child: Text(ar ? 'سيارة' : 'Car')),
                  DropdownMenuItem(value: 1, child: Text(ar ? 'دراجة' : 'Bike')),
                  DropdownMenuItem(value: 2, child: Text(ar ? 'فان' : 'Van')),
                  DropdownMenuItem(value: 3, child: Text(ar ? 'شاحنة' : 'Truck')),
                ],
                onChanged: _busy ? null : (v) {
                  if (v != null) setState(() => _vehicleType = v);
                },
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _busy ? null : _submit,
                icon: _busy
                    ? const SizedBox.square(dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send_rounded),
                label: Text(ar ? 'إرسال طلب الانضمام' : 'Submit driver application'),
              ),
            ]),
          ),
        ),
      ))),
    );
  }
}
