import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/core/theme/app_theme.dart';
import 'package:mazraa_driver/features/notifications/notification_providers.dart';
import 'package:mazraa_driver/features/notifications/notifications_screen.dart';
import 'package:mazraa_driver/features/shipments/shipment_providers.dart';
import 'package:mazraa_driver/features/shipments/shipment_screens.dart';
import 'package:mazraa_driver/features/wallet/wallet_providers.dart';
import 'package:mazraa_driver/features/wallet/wallet_screen.dart';

Widget _screen(Widget child, {required List<Override> overrides}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(),
      home: child,
    ),
  );
}

void main() {
  testWidgets('shipments screen renders assigned server model', (tester) async {
    final shipment = Shipment(
      id: 12,
      number: 'SHP-0012',
      orderId: 88,
      status: ShipmentStatus.assigned,
      deliveryFee: 25,
      transportCost: 10,
      netProfit: 15,
      createdAt: DateTime(2026, 10, 10),
    );
    await tester.pumpWidget(
      _screen(
        const ShipmentsScreen(),
        overrides: [
          shipmentsProvider.overrideWith((ref) async => [shipment]),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SHP-0012'), findsOneWidget);
    expect(find.text('مسندة إليك'), findsOneWidget);
  });

  testWidgets('wallet screen distinguishes balance and monthly values', (
    tester,
  ) async {
    const summary = WalletSummary(
      balance: 500,
      currency: 'SAR',
      accountNumber: 'WALLET-00006',
      monthlyCredits: 120,
      monthlyDebits: 20,
      pendingTopUpBalance: 0,
      canTransfer: false,
    );
    await tester.pumpWidget(
      _screen(
        const WalletScreen(),
        overrides: [
          walletSummaryProvider.overrideWith((ref) async => summary),
          walletTransactionsProvider.overrideWith((ref) async => const []),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('الرصيد الحالي'), findsOneWidget);
    expect(find.text('إيداعات'), findsOneWidget);
    expect(find.text('مدفوعات وسحوبات'), findsOneWidget);
  });

  testWidgets('notifications screen renders unread server item', (
    tester,
  ) async {
    final notification = AppNotification(
      id: 7,
      title: 'تم تعيين شحنة',
      message: 'لديك شحنة جديدة',
      isRead: false,
      createdAt: DateTime(2026, 10, 10),
      eventType: 'shipment.driver_assigned',
    );
    await tester.pumpWidget(
      _screen(
        const NotificationsScreen(),
        overrides: [
          notificationsProvider.overrideWith((ref) async => [notification]),
          unreadNotificationsProvider.overrideWith((ref) async => 1),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('تم تعيين شحنة'), findsOneWidget);
    expect(find.text('قراءة الكل'), findsOneWidget);
  });
}
