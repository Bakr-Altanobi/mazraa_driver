import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mazraa_driver/core/network/driver_registration_api.dart';
import 'package:mazraa_driver/features/auth/auth_controller.dart';
import 'package:mazraa_driver/features/reference_journey/reference_assets.dart';

class DriverRegistrationScreen extends ConsumerStatefulWidget {
  const DriverRegistrationScreen({super.key});

  @override
  ConsumerState<DriverRegistrationScreen> createState() => _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends ConsumerState<DriverRegistrationScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  int _vehicleType = 0;
  bool _busy = false;
  bool _obscure = true;
  bool _resumeExisting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate() || _busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      final api = ref.read(driverRegistrationApiProvider);
      if (_resumeExisting) {
        await api.signInAndApply(
          email: _email.text,
          password: _password.text,
          vehicleType: _vehicleType,
        );
      } else {
        await api.registerAndApply(
          name: _name.text,
          email: _email.text,
          password: _password.text,
          vehicleType: _vehicleType,
        );
      }
      await ref.read(authControllerProvider).initialize(force: true);
      if (!mounted) return;
      final auth = ref.read(authControllerProvider);
      if (auth.isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم إنشاء الحساب وإرسال طلب السائق. ارفع وثائقك وتابع حالة الاعتماد من التطبيق.'),
        ));
        context.go('/home');
      } else {
        setState(() => _error = auth.errorMessage ?? 'تعذر تحميل ملف السائق بعد إنشاء الحساب.');
      }
    } catch (error) {
      if (mounted) setState(() => _error =
          '$error\nإذا تم إنشاء الحساب بالفعل ولم يكتمل طلب السائق، اختر «استكمال طلب حساب موجود» أدناه.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الانضمام كسائق'),
        leading: IconButton(
          onPressed: () => context.go('/login'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 34),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 150,
                      child: Image.asset(
                        ReferenceAssets.deliveryScooter,
                        fit: BoxFit.contain,
                        cacheWidth: 620,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ابدأ رحلة التوصيل مع مزرعتي',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'أنشئ حسابك وأرسل طلب السائق مباشرة. يبدأ الحساب قيد المراجعة حتى تعتمد الإدارة الوثائق.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 22),
                    if (!_resumeExisting) ...[
                    TextFormField(
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'الاسم الكامل',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (v) => (v?.trim().length ?? 0) < 2 ? 'أدخل الاسم الكامل' : null,
                    ),
                    const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      validator: (v) => v?.contains('@') == true ? null : 'أدخل بريدًا صحيحًا',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      textDirection: TextDirection.ltr,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        ),
                      ),
                      validator: (v) => (v?.length ?? 0) < 6 ? 'استخدم 6 أحرف على الأقل' : null,
                    ),
                    const SizedBox(height: 12),
                    if (!_resumeExisting) ...[
                    TextFormField(
                      controller: _confirm,
                      obscureText: _obscure,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(
                        labelText: 'تأكيد كلمة المرور',
                        prefixIcon: Icon(Icons.lock_reset_rounded),
                      ),
                      validator: (v) => v == _password.text ? null : 'كلمتا المرور غير متطابقتين',
                    ),
                    const SizedBox(height: 12),
                    ],
                    DropdownButtonFormField<int>(
                      initialValue: _vehicleType,
                      decoration: const InputDecoration(
                        labelText: 'وسيلة التوصيل',
                        prefixIcon: Icon(Icons.local_shipping_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('سيارة')),
                        DropdownMenuItem(value: 1, child: Text('دراجة')),
                        DropdownMenuItem(value: 2, child: Text('فان')),
                        DropdownMenuItem(value: 3, child: Text('شاحنة')),
                      ],
                      onChanged: (v) => setState(() => _vehicleType = v ?? 0),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(_error!),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _busy ? null : _submit,
                      icon: _busy
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.how_to_reg_rounded),
                      label: Text(_resumeExisting
                          ? 'تسجيل الدخول واستكمال الطلب'
                          : 'إنشاء الحساب وإرسال الطلب'),
                    ),
                    OutlinedButton.icon(
                      key: const Key('resumeDriverApplicationButton'),
                      onPressed: _busy ? null : () => setState(() {
                        _resumeExisting = !_resumeExisting;
                        _error = null;
                      }),
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: Text(_resumeExisting
                          ? 'إنشاء حساب جديد'
                          : 'استكمال طلب حساب موجود'),
                    ),
                    TextButton(
                      onPressed: _busy ? null : () => context.go('/login'),
                      child: const Text('لدي حساب سائق بالفعل'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
