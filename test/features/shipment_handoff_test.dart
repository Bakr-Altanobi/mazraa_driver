import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/features/shipments/shipment_handoff_dialogs.dart';

const manifest = <String, dynamic>{
  'items': [
    {
      'orderItemId': 9,
      'productVariantId': 4,
      'productName': 'Crates',
      'quantity': 3,
    },
  ],
  'delivery': {'contactless': true},
  'payment': {
    'requiresCashCollection': true,
    'cashCollectionAmount': 150.0,
    'currency': 'SAR',
  },
};
void main() {
  testWidgets(
    'cash handoff requires explicit exact collection and customer code',
    (tester) async {
      DeliveryConfirmation? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showDialog<DeliveryConfirmation>(
                    context: context,
                    builder: (_) => DeliveryConfirmationDialog(
                      manifest: manifest,
                      requestCode: () async {},
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('cash-amount')), '149');
      await tester.enterText(find.byKey(const Key('delivery-code')), '123456');
      await tester.tap(find.text('Confirm delivery'));
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(find.text('Collect the exact amount due'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('cash-amount')), '150');
      await tester.tap(find.text('Confirm delivery'));
      await tester.pumpAndSettle();
      expect(result?.cashAmount, 150);
      expect(result?.cashConfirmed, true);
      expect(result?.numericCode, '123456');
    },
  );
  testWidgets(
    'pickup records counted quantities and rejects unexplained shortage',
    (tester) async {
      Map<String, dynamic>? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (_) =>
                        const PickupChecklistDialog(manifest: manifest),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('received-0')), '2');
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Record inspection'));
      await tester.pumpAndSettle();
      expect(result, isNull);
      await tester.enterText(find.byKey(const ValueKey('received-0')), '3');
      await tester.tap(find.text('Record inspection'));
      await tester.pumpAndSettle();
      expect((result?['lines'] as List).single['receivedQuantity'], 3);
      expect((result?['lines'] as List).single['missingQuantity'], 0);
    },
  );
}
