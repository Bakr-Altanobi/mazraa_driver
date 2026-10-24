import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mazraa_driver/features/shell/driver_context_navigation.dart';

void main() {
  testWidgets('changing contextual destinations never reserves a Navigator key twice', (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, __) =>
            const Scaffold(body: Text('home content'))),
        GoRoute(path: '/tools/scheduled-trips', builder: (_, __) =>
            const Scaffold(body: Text('scheduled content'))),
        GoRoute(path: '/tools/current-trips', builder: (_, __) =>
            const Scaffold(body: Text('assigned content'))),
        GoRoute(path: '/tools/availability', builder: (_, __) =>
            const Scaffold(body: Text('availability content'))),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) => DriverContextNavigation(
        router: router, child: child ?? const SizedBox.shrink(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('home content'), findsOneWidget);
    router.go('/tools/scheduled-trips');
    await tester.pumpAndSettle();
    expect(find.text('scheduled content'), findsOneWidget);
    expect(find.text('التوفر'), findsOneWidget);
    await tester.tap(find.text('التوفر'));
    await tester.pumpAndSettle();
    expect(find.text('availability content'), findsOneWidget);
    await tester.tap(find.text('رحلاتي'));
    await tester.pumpAndSettle();
    expect(find.text('assigned content'), findsOneWidget);
    await tester.tap(find.text('المجدولة'));
    await tester.pumpAndSettle();
    expect(find.text('scheduled content'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
