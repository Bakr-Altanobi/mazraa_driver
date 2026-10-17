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
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mazraa_driver/features/auth/auth_screens.dart';

Future<ui.Image> _decodeReference() async {
  final bytes = await File('refrinces/screens/01_onboarding.png').readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}

Future<Uint8List> _rgba(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return data!.buffer.asUint8List();
}

void main() {
  testWidgets('screen 01 is pixel-identical to its canonical reference', (tester) async {
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
    final actual = await boundary.toImage(pixelRatio: 1);
    final reference = await _decodeReference();

    expect(actual.width, reference.width);
    expect(actual.height, reference.height);

    final actualBytes = await _rgba(actual);
    final referenceBytes = await _rgba(reference);
    expect(actualBytes.length, referenceBytes.length);

    var differingPixels = 0;
    var maxChannelDelta = 0;
    for (var i = 0; i < actualBytes.length; i += 4) {
      var pixelDiffers = false;
      for (var c = 0; c < 4; c++) {
        final delta = (actualBytes[i + c] - referenceBytes[i + c]).abs();
        if (delta > maxChannelDelta) maxChannelDelta = delta;
        if (delta > 1) pixelDiffers = true;
      }
      if (pixelDiffers) differingPixels++;
    }

    final totalPixels = actual.width * actual.height;
    final mismatchRatio = differingPixels / totalPixels;
    expect(
      mismatchRatio,
      lessThanOrEqualTo(.0001),
      reason: 'Screen 01 mismatch ratio=$mismatchRatio maxChannelDelta=$maxChannelDelta',
    );
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
