import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/features/shipments/shipment_handoff_dialogs.dart';
import 'driver_workspace_test.dart' show host;

void main() {
  testWidgets('scanned QR cannot bypass full cash collection confirmation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    DeliveryConfirmation? result;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showDialog<DeliveryConfirmation>(
                  context: context,
                  builder: (_) => DeliveryConfirmationDialog(
                    manifest: {
                      'payment': {
                        'requiresCashCollection': true,
                        'cashCollectionAmount': 125.0,
                        'currency': 'SAR',
                      },
                      'delivery': {'contactless': true},
                    },
                    requestCode: () async {},
                    scanQr: () async => 'signed-server-token',
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
        language: 'en',
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scan customer QR'));
    await tester.pumpAndSettle();
    expect(find.text('QR scanned'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Confirm delivery'),
          )
          .onPressed,
      isNull,
    );
    await tester.enterText(find.byKey(const Key('cash-amount')), '120');
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm delivery'));
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect(find.text('Collect the exact amount due'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('cash-amount')), '125');
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm delivery'));
    await tester.pumpAndSettle();
    expect(result!.qrToken, 'signed-server-token');
    expect(result!.cashConfirmed, true);
    expect(result!.cashAmount, 125.0);
  });
}
