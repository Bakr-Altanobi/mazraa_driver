import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:mazraa_driver/core/constants/api_endpoints.dart';
import 'package:mazraa_driver/core/theme/app_theme.dart';
import 'package:mazraa_driver/features/auth/auth_controller.dart';
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
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFCF5), Color(0xFFF4EBD9)],
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
                      color: MazraaColors.forest,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ar ? 'رفيقك في كل رحلة' : 'Your companion on every trip',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: MazraaColors.forest.withValues(alpha: .72),
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
                    FilledButton.icon(
                      key: const Key('bootstrapRetryButton'),
                      onPressed: () => _bootstrap(force: true),
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(ar ? 'إعادة المحاولة' : 'Retry'),
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
    );
  }
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Image.asset(
                        ReferenceAssets.brandLeaf,
                        width: 52,
                        height: 52,
                        fit: BoxFit.contain,
                        cacheWidth: 180,
                      ),
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
                      onPressed: () => context.go('/login'),
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
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: IconButton.filledTonal(
                        onPressed: () => context.go('/onboarding'),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
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
                        onPressed: () => _showUnavailable(context, ar),
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
                      onPressed: busy ? null : () => context.go('/register-driver'),
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

  void _showUnavailable(BuildContext context, bool ar) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.admin_panel_settings_outlined, size: 45),
            const SizedBox(height: 12),
            Text(
              ar ? 'تتطلب مراجعة الإدارة' : 'Admin review required',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              ar
                  ? 'لا يوفر السيرفر الحالي مسارًا عامًا آمنًا لتسجيل السائق أو استعادة كلمة المرور. تواصل مع إدارة المنصة.'
                  : 'The server does not currently expose a safe public driver registration or password recovery endpoint. Contact platform support.',
              textAlign: TextAlign.center,
            ),
          ],
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
