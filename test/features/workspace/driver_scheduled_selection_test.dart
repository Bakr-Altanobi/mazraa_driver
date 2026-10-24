import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/features/workspace/driver_schedule_widgets.dart';

void main() {
  testWidgets('scheduled checkbox table does not offer assigned trip to second driver',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DriverScheduledTripsTable(rows: [
              {
                'trip': {
                  'id': 10,
                  'plannedDepartureAt': '2026-11-01T09:00:00Z',
                  'dropoffName': 'Trip assigned elsewhere',
                  'driverId': 88,
                },
                'participation': null,
                'bookedOrdersCount': 1,
                'preparedShipmentsCount': 0,
              },
              {
                'trip': {
                  'id': 11,
                  'plannedDepartureAt': '2026-11-02T09:00:00Z',
                  'dropoffName': 'Open trip',
                  'driverId': null,
                },
                'participation': null,
                'bookedOrdersCount': 2,
                'preparedShipmentsCount': 1,
              },
            ]),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final table = tester.widget<DataTable>(find.byType(DataTable));
    expect(table.rows.length, 2);
    expect(table.rows.first.onSelectChanged, isNull,
        reason: 'An assigned trip must not accept a second driver');
    expect(table.rows.last.onSelectChanged, isNotNull,
        reason: 'An open trip must allow a selected participation request');
    expect(find.text('Trip assigned elsewhere'), findsOneWidget);
    expect(find.text('Open trip'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
