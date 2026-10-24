import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:mazraa_driver/core/constants/api_endpoints.dart';
import 'package:mazraa_driver/app/app_settings.dart';
import 'package:mazraa_driver/core/theme/app_theme.dart';
import 'package:mazraa_driver/features/auth/auth_controller.dart';
import 'package:mazraa_driver/core/network/providers.dart';
import 'package:mazraa_driver/features/home/home_bootstrap.dart';
import 'package:mazraa_driver/features/reference_journey/reference_assets.dart';
import 'package:mazraa_driver/shared/widgets/mazraa_widgets.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap({bool force = false}) {
    return ref.read(authControllerProvider).initialize(
      force: force,
      preloadHome: () => preloadDriverHome(ref),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final ar = isArabic(context);
    final failed = auth.state == AuthState.bootstrapFailed;
    final preparingHome = auth.state == AuthState.preparingHome;

    return Scaffold(
      key: const Key('splashScreen'),
      body: RefreshIndicator(
        onRefresh: () => _bootstrap(force: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height -
                  MediaQuery.paddingOf(context).top,
              child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Theme.of(context).brightness == Brightness.dark
                ? const [Color(0xFF101B18), Color(0xFF21352C)]
                : const [Color(0xFFFFFCF5), Color(0xFFF4EBD9)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Hero(
                    tag: 'mazraa-logo',
                    child: SvgPicture.asset(
                      'assets/branding/mazraa_mark.svg',
                      width: 96,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'مزرعتي',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : MazraaColors.forest,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ar ? 'رفيقك في كل رحلة' : 'Your companion on every trip',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : MazraaColors.forest.withValues(alpha: .72),
                    ),
                  ),
                  const SizedBox(height: 34),
                  if (failed) ...[
                    Icon(
                      Icons.cloud_off_rounded,
                      size: 34,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      auth.errorMessage ??
                          (ar
                              ? 'تعذر إكمال تهيئة التطبيق.'
                              : 'App initialization could not be completed.'),
                      key: const Key('bootstrapError'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      ar ? 'اسحب للأسفل لإعادة المحاولة'
                          : 'Pull down to retry',
                      textAlign: TextAlign.center,
                    ),
                  ] else ...[
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.7),
                    ),
                    const SizedBox(height: 13),
                    Text(
                      preparingHome
                          ? (ar
                              ? 'جاري تحميل بيانات الشاشة الرئيسية…'
                              : 'Loading home data…')
                          : (ar
                              ? 'جاري استعادة الجلسة…'
                              : 'Restoring your session…'),
                      key: Key(
                        preparingHome
                            ? 'homeBootstrapProgress'
                            : 'sessionRestoreProgress',
                      ),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ar = isArabic(context);
    return Scaffold(
      key: const Key('onboardingScreen'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final artworkHeight = constraints.maxHeight < 660 ? 205.0 : 270.0;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 42).clamp(0, double.infinity),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          ReferenceAssets.brandLeaf,
                          width: 52,
                          height: 52,
                          fit: BoxFit.contain,
                          cacheWidth: 180,
                        ),
                        const Spacer(),
                        const _WelcomeAppearanceControls(),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: artworkHeight,
                      width: double.infinity,
                      child: Image.asset(
                        ReferenceAssets.onboardingFarm,
                        fit: BoxFit.contain,
                        cacheWidth: 900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _ReferenceAssetRow(
                      paths: [
                        ReferenceAssets.driverAvatar,
                        ReferenceAssets.routeArrow,
                        ReferenceAssets.deliveryTote,
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      ar ? 'رحلات أوضح، يوم أسهل' : 'Clear trips. Easier days.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      ar
                          ? 'تابع شحناتك، موقعك، ومحفظتك من مكان واحد مع تحديثات حقيقية من منصة مزرعتي.'
                          : 'Track shipments, location, and wallet in one place with live data from Mazraa.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () async {
                        await ref.read(appSettingsProvider).completeOnboarding();
                        if (context.mounted) context.go('/login');
                      },
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          ar ? 'البدء الآن' : 'Get started',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email = TextEditingController(
    text: AppEnvironment.testDriverEmail,
  );
  late final TextEditingController _password = TextEditingController(
    text: AppEnvironment.testDriverPassword,
  );
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authControllerProvider).login(
      _email.text.trim(),
      _password.text,
      preloadHome: () => preloadDriverHome(ref),
    );
  }

  Future<void> _forgotPassword() async {
    final ar = isArabic(context);
    final controller = TextEditingController(text: _email.text.trim());
    try {
      final email = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(ar ? 'استعادة كلمة المرور' : 'Reset your password'),
          content: TextField(
            controller: controller,
            textDirection: TextDirection.ltr,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: ar ? 'البريد الإلكتروني' : 'Email address'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext),
              child: Text(ar ? 'إلغاء' : 'Cancel')),
            FilledButton(onPressed: () {
              if (controller.text.trim().contains('@')) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            }, child: Text(ar ? 'إرسال' : 'Send')),
          ],
        ),
      );
      if (!mounted || email == null) return;
      await ref.read(apiClientProvider).post<dynamic>(
        'api/auth/forgot-password', data: {'email': email});
      if (!mounted) return;
      final resetNow = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(ar ? 'تحقق من بريدك' : 'Check your email'),
          content: Text(ar
              ? 'إذا كان البريد مرتبطًا بحساب، ستصلك رسالة تتضمن رمز إعادة التعيين. هل تريد إدخال الرمز الآن؟'
              : 'If an account exists, a reset token will be emailed. Enter the token now?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(ar ? 'لاحقًا' : 'Later')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(ar ? 'لدي رمز' : 'I have a token')),
          ],
        ),
      );
      if (resetNow == true && mounted) await _resetPassword();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())));
    } finally {
      controller.dispose();
    }
  }

  Future<void> _resetPassword() async {
    final ar = isArabic(context);
    final token = TextEditingController();
    final password = TextEditingController();
    try {
      final data = await showDialog<(String, String)>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(ar ? 'إعادة تعيين كلمة المرور' : 'Set a new password'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: token,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(labelText: ar ? 'رمز البريد' : 'Email token'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: password,
              obscureText: true,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(labelText: ar ? 'كلمة المرور الجديدة' : 'New password'),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext),
              child: Text(ar ? 'إلغاء' : 'Cancel')),
            FilledButton(onPressed: () {
              if (token.text.trim().isNotEmpty && password.text.length >= 8) {
                Navigator.pop(dialogContext, (token.text.trim(), password.text));
              }
            }, child: Text(ar ? 'تغيير كلمة المرور' : 'Reset password')),
          ],
        ),
      );
      if (!mounted || data == null) return;
      await ref.read(apiClientProvider).post<dynamic>(
        'api/auth/reset-password',
        data: {'token': data.$1, 'newPassword': data.$2},
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ar ? 'تم تحديث كلمة المرور، سجّل الدخول الآن' : 'Password updated. Sign in now.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      token.dispose();
      password.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final ar = isArabic(context);
    final busy = auth.state == AuthState.signingIn ||
        auth.state == AuthState.preparingHome;
    return Scaffold(
      key: const Key('loginScreen'),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton.filledTonal(
                          onPressed: () => context.go('/onboarding'),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const Spacer(),
                        const _WelcomeAppearanceControls(),
                      ],
                    ),
                    SizedBox(
                      height: 145,
                      child: Image.asset(
                        ReferenceAssets.loginPhoneOtp,
                        fit: BoxFit.contain,
                        cacheWidth: 520,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const _ReferenceAssetRow(
                      paths: [
                        ReferenceAssets.driverAvatar,
                        ReferenceAssets.identityScan,
                        ReferenceAssets.supportHeadset,
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Image.asset(
                          ReferenceAssets.brandLeaf,
                          width: 48,
                          height: 48,
                          cacheWidth: 160,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            ar ? 'أهلًا بك يا كابتن' : 'Welcome, driver',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ar
                          ? 'سجّل دخولك بحساب السائق المعتمد للبدء. بعد نجاح الدخول لن ينتقل التطبيق قبل اكتمال بيانات الشاشة التالية.'
                          : 'Sign in with your approved driver account. The app waits for the next screen data before navigating.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 26),
                    TextFormField(
                      key: const Key('emailField'),
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: ar ? 'البريد الإلكتروني' : 'Email',
                        prefixIcon: const Icon(Icons.mail_outline_rounded),
                      ),
                      validator: (value) {
                        if (value == null || !value.contains('@')) {
                          return ar ? 'أدخل بريدًا صحيحًا' : 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      key: const Key('passwordField'),
                      controller: _password,
                      obscureText: _obscure,
                      textDirection: TextDirection.ltr,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: ar ? 'كلمة المرور' : 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) => (value?.length ?? 0) < 6
                          ? (ar ? 'كلمة المرور قصيرة' : 'Password is too short')
                          : null,
                      onFieldSubmitted: (_) => busy ? null : _submit(),
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: _forgotPassword,
                        child: Text(
                          ar ? 'نسيت كلمة المرور؟' : 'Forgot password?',
                        ),
                      ),
                    ),
                    if (auth.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                auth.errorMessage!,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    FilledButton(
                      key: const Key('loginButton'),
                      onPressed: busy ? null : _submit,
                      child: busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : Text(ar ? 'تسجيل الدخول' : 'Sign in'),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/apply'),
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: Text(
                        ar ? 'طلب الانضمام كسائق' : 'Apply as a driver',
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      ar
                          ? 'تُحفظ رموز الجلسة داخل التخزين الآمن للجهاز.'
                          : 'Session tokens are kept in secure device storage.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
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

class _ReferenceAssetRow extends StatelessWidget {
  const _ReferenceAssetRow({required this.paths});

  final List<String> paths;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 66,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < paths.length; index++) ...[
            Container(
              width: 66,
              height: 66,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Image.asset(
                paths[index],
                fit: BoxFit.contain,
                cacheWidth: 220,
              ),
            ),
            if (index != paths.length - 1) const SizedBox(width: 9),
          ],
        ],
      ),
    );
  }
}

/// Appearance controls remain available *before* authentication too.
class _WelcomeAppearanceControls extends ConsumerWidget {
  const _WelcomeAppearanceControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final ar = settings.locale.languageCode == 'ar';
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          key: const Key('welcomeLanguageToggle'),
          onPressed: () => settings.setLocale(Locale(ar ? 'en' : 'ar')),
          child: Text(ar ? 'English' : 'العربية'),
        ),
        IconButton(
          key: const Key('welcomeThemeToggle'),
          tooltip: dark ? (ar ? 'الوضع الفاتح' : 'Light mode')
              : (ar ? 'الوضع الداكن' : 'Dark mode'),
          onPressed: () => settings.setThemeMode(
            dark ? ThemeMode.light : ThemeMode.dark,
          ),
          icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
        ),
      ],
    );
  }
}
