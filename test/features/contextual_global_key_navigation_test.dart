import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mazraa_driver/features/shell/driver_context_navigation.dart';

void main() {
  testWidgets('Navigator identity remains stable between root, trips, tools and chats',
      (tester) async {
    final router = GoRouter(initialLocation: '/home', routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => Scaffold(body: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (_, __) =>
                const Scaffold(body: Center(child: Text('Home route')))),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (_, __) =>
                const Scaffold(body: Center(child: Text('Profile route')))),
          ]),
        ],
      ),
      for (final path in [
        '/tools/scheduled-trips',
        '/tools/availability',
        '/tools/current-trips',
        '/tools/chats',
        '/chats/7',
        '/shipments',
        '/offers',
      ])
        GoRoute(path: path, builder: (_, __) =>
            Scaffold(body: Center(child: Text(path)))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(
      routerConfig: router,
      locale: const Locale('ar'),
      builder: (context, child) => DriverContextNavigation(
        router: router, child: child ?? const SizedBox.shrink(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Home route'), findsOneWidget);
    for (final path in [
      '/tools/scheduled-trips',
      '/tools/availability',
      '/tools/current-trips',
      '/chats/7',
      '/tools/chats',
      '/home',
      '/tools/scheduled-trips',
    ]) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(find.text(path), path == '/home' ? findsNothing : findsOneWidget);
      if (path == '/home') expect(find.text('Home route'), findsOneWidget);
      expect(tester.takeException(), isNull,
          reason: 'Unexpected Navigator/GlobalKey reservation on $path');
    }
    // Switching context tabs must open a real route, not duplicate an
    // existing Navigator with the same GlobalKey.
    await tester.tap(find.byKey(const ValueKey('context-tab-/tools/availability')));
    await tester.pumpAndSettle();
    expect(find.text('/tools/availability'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
