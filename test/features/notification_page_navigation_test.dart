import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/features/notifications/notification_providers.dart';
import 'package:mazraa_driver/features/notifications/notifications_screen.dart';

void main() {
  testWidgets('chat reply card opens matching conversation and preference toolbar opens settings',
      (tester) async {
    final router = GoRouter(initialLocation: '/notifications', routes: [
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/chats/:id', builder: (_, state) => Scaffold(
        body: Text('chat-id:${state.pathParameters['id']}'),
      )),
      GoRoute(path: '/tools/notification-preferences', builder: (_, __) =>
        const Scaffold(body: Text('notification preferences opened'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        notificationsProvider.overrideWith((ref) async => [
          AppNotification.fromJson({
            'id': 101,
            'title': 'رد العميل',
            'message': 'وصلتني الشحنة، شكرًا',
            'isRead': true,
            'eventType': 'chat.message_received',
            'deepLink': '/chats/82',
            'dataJson': '{"chatId":"82"}',
            'createdAt': '2026-10-24T01:00:00Z',
          }),
        ]),
        unreadNotificationsProvider.overrideWith((ref) async => 0),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('وصلتني الشحنة، شكرًا'), findsOneWidget);
    await tester.tap(find.text('رد العميل'));
    await tester.pumpAndSettle();
    expect(find.text('chat-id:82'), findsOneWidget);
    router.go('/notifications');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('تفضيلات الإشعارات'));
    await tester.pumpAndSettle();
    expect(find.text('notification preferences opened'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
