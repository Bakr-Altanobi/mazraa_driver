import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/features/wallet/wallet_providers.dart';
import 'package:mazraa_driver/features/wallet/wallet_screen.dart';

void main() {
  testWidgets('nested failed wallet transaction request displays a stable swipe-retry state',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        walletSummaryProvider.overrideWith((ref) async => const WalletSummary(
          balance: 120, currency: 'SAR', accountNumber: 'WALLET-TEST',
          monthlyCredits: 50, monthlyDebits: 20,
          pendingTopUpBalance: 0, canTransfer: false,
        )),
        walletTransactionsProvider.overrideWith((ref) async {
          throw StateError('controlled transaction outage');
        }),
      ],
      child: const MaterialApp(
        locale: Locale('ar'),
        supportedLocales: [Locale('ar'), Locale('en')],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: WalletScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('controlled transaction outage'), findsOneWidget);
    expect(find.text('اسحب للأسفل لإعادة المحاولة'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
