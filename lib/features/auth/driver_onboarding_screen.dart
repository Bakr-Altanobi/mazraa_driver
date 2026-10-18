import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mazraa_driver/features/reference_journey/reference_assets.dart';

/// Public welcome journey. All operational numbers are loaded after login.
class DriverOnboardingScreen extends StatefulWidget {
  const DriverOnboardingScreen({super.key});

  @override
  State<DriverOnboardingScreen> createState() => _DriverOnboardingScreenState();
}

class _DriverOnboardingScreenState extends State<DriverOnboardingScreen> {
  final PageController _pages = PageController();
  int _page = 0;

  static const _art = [
    ReferenceAssets.onboardingFarm,
    ReferenceAssets.routeMap,
    ReferenceAssets.earningsArrow,
  ];
  static const _titles = [
    'انطلق مع مزرعتي',
    'رحلتك واضحة على الخريطة',
    'كل أعمالك في مكان واحد',
  ];
  static const _messages = [
    'استقبل الشحنات المسندة إليك وتابع كل طلب من المتجر إلى العميل.',
    'اعرض نقاط الاستلام والتسليم الحقيقية باستخدام Google Maps.',
    'تعرّف على الورديات ورحلاتك ومحفظتك من بيانات حسابك المباشرة.',
  ];
  static const _features = [
    ['طلبات واضحة', 'حالة توصيل مباشرة', 'تسليم موثّق'],
    ['موقع الاستلام', 'موقع العميل', 'تنقّل سهل'],
    ['ملخص الرحلات', 'الرصيد الحقيقي', 'مساعدة ودعم'],
  ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _advance() {
    if (_page == 2) {
      context.go('/login');
    } else {
      _pages.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context);
    const green = Color(0xFF235641);
    return Scaffold(
      key: const Key('onboardingScreen'),
      body: SafeArea(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFFCF6), Color(0xFFF3EDDB)],
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Row(
                  children: [
                    Image.asset(ReferenceAssets.brandLeaf, width: 45, height: 45),
                    const SizedBox(width: 10),
                    Text('مزرعتي', style: style.textTheme.titleLarge?.copyWith(
                      color: green, fontWeight: FontWeight.w800,
                    )),
                    const Spacer(),
                    TextButton(
                      key: const Key('onboardingSkipButton'),
                      onPressed: () => context.go('/login'),
                      child: const Text('تخطي'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  key: const Key('onboardingPages'),
                  controller: _pages,
                  itemCount: 3,
                  onPageChanged: (index) => setState(() => _page = index),
                  itemBuilder: (context, index) => LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(_titles[index],
                              key: Key('onboardingTitle$index'),
                              textAlign: TextAlign.center,
                              style: style.textTheme.headlineMedium?.copyWith(
                                color: green, fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 14),
                            AspectRatio(
                              aspectRatio: 1.5,
                              child: Image.asset(_art[index],
                                fit: BoxFit.contain, cacheWidth: 768),
                            ),
                            const SizedBox(height: 14),
                            Text(_messages[index],
                              textAlign: TextAlign.center,
                              style: style.textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 18),
                            for (final benefit in _features[index])
                              Card(
                                elevation: 0,
                                color: Colors.white,
                                child: ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.check_circle_outline,
                                    color: green),
                                  title: Text(benefit),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < 3; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: i == _page ? 26 : 8,
                            height: 7,
                            decoration: BoxDecoration(
                              color: i == _page ? green : green.withValues(alpha: .24),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      key: const Key('onboardingNextButton'),
                      onPressed: _advance,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(_page == 2 ? 'ابدأ الآن' : 'التالي'),
                      ),
                    ),
                    TextButton(
                      key: const Key('onboardingLoginButton'),
                      onPressed: () => context.go('/login'),
                      child: const Text('لدي حساب بالفعل'),
                    ),
                    OutlinedButton.icon(
                      key: const Key('onboardingRegisterButton'),
                      onPressed: () => context.go('/register-driver'),
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                      label: const Text('انضم كسائق جديد'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
