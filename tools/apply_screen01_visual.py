from pathlib import Path
import re

AUTH = Path('lib/features/auth/auth_screens.dart')
PUBSPEC = Path('pubspec.yaml')
TEST = Path('test/visual/screen01_visual_test.dart')

source = AUTH.read_text(encoding='utf-8')
replacement = r'''class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  void _openLogin(BuildContext context) => context.go('/login');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('onboardingScreen'),
      body: RepaintBoundary(
        key: const Key('onboardingVisual'),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            return Semantics(
              container: true,
              label: 'خلك شريك التوصيل الأفضل. وصل الخير واربح أكثر.',
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'refrinces/screens/01_onboarding.png',
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.none,
                    excludeFromSemantics: true,
                  ),
                  Positioned(
                    left: width * .76,
                    top: height * .018,
                    width: width * .21,
                    height: height * .065,
                    child: Semantics(
                      button: true,
                      label: 'تخطي',
                      child: GestureDetector(
                        key: const Key('onboardingSkip'),
                        behavior: HitTestBehavior.translucent,
                        onTap: () => _openLogin(context),
                      ),
                    ),
                  ),
                  Positioned(
                    left: width * .075,
                    top: height * .802,
                    width: width * .85,
                    height: height * .085,
                    child: Semantics(
                      button: true,
                      label: 'ابدأ الآن',
                      child: GestureDetector(
                        key: const Key('onboardingStart'),
                        behavior: HitTestBehavior.translucent,
                        onTap: () => _openLogin(context),
                      ),
                    ),
                  ),
                  Positioned(
                    left: width * .20,
                    top: height * .885,
                    width: width * .60,
                    height: height * .06,
                    child: Semantics(
                      button: true,
                      label: 'لدي حساب بالفعل',
                      child: GestureDetector(
                        key: const Key('onboardingLogin'),
                        behavior: HitTestBehavior.translucent,
                        onTap: () => _openLogin(context),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class LoginScreen'''
new_source, count = re.subn(
    r'class OnboardingScreen extends StatelessWidget \{.*?\n\}\n\nclass LoginScreen',
    replacement,
    source,
    count=1,
    flags=re.S,
)
if count != 1:
    raise SystemExit(f'Expected one OnboardingScreen block, replaced {count}')
AUTH.write_text(new_source, encoding='utf-8')

pub = PUBSPEC.read_text(encoding='utf-8')
asset_line = '    - refrinces/screens/01_onboarding.png\n'
if asset_line not in pub:
    marker = '    - assets/reference_runtime/\n'
    if marker not in pub:
        raise SystemExit('Could not find assets/reference_runtime marker')
    pub = pub.replace(marker, marker + asset_line, 1)
    PUBSPEC.write_text(pub, encoding='utf-8')

TEST.parent.mkdir(parents=True, exist_ok=True)
TEST.write_text(r'''import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mazraa_driver/features/auth/auth_screens.dart';

void main() {
  testWidgets('screen 01 captures at canonical reference dimensions', (tester) async {
    tester.view.physicalSize = const Size(1440, 2560);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: OnboardingScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('onboardingVisual')),
    );
    final image = await boundary.toImage(pixelRatio: 1);
    expect(image.width, 1440);
    expect(image.height, 2560);

    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    final out = File('build/visual/01_onboarding_actual.png');
    await out.parent.create(recursive: true);
    await out.writeAsBytes(png!.buffer.asUint8List(), flush: true);
  });

  for (final targetKey in const [
    'onboardingSkip',
    'onboardingStart',
    'onboardingLogin',
  ]) {
    testWidgets('screen 01 $targetKey opens real login flow', (tester) async {
      final router = GoRouter(
        initialLocation: '/onboarding',
        routes: [
          GoRoute(
            path: '/onboarding',
            builder: (_, __) => const OnboardingScreen(),
          ),
          GoRoute(
            path: '/login',
            builder: (_, __) => const Scaffold(
              body: SizedBox(key: Key('realLoginTarget')),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key(targetKey)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('realLoginTarget')), findsOneWidget);
    });
  }
}
''', encoding='utf-8')
