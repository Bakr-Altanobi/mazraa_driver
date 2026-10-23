import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/features/workspace/driver_tool_catalog.dart';
import 'package:mazraa_driver/features/workspace/driver_tool_screens.dart';
import 'package:mazraa_driver/features/workspace/driver_workspace_repository.dart';
import 'workspace/driver_workspace_test.dart' show host, loadDriverFonts;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadDriverFonts);

  testWidgets('every operational tool shows a meaningful empty result instead of a blank card',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final tool in driverTools.where((t) => t.id != 'health' &&
        t.id != 'shifts' && t.id != 'training')) {
      await tester.pumpWidget(host(
        DriverToolScreen(key: ValueKey(tool.id), toolId: tool.id),
        overrides: [
          toolDataProvider(tool.id).overrideWith(
            (ref) async => <String, dynamic>{},
          ),
        ],
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(Key('tool-${tool.id}')), findsOneWidget);
      expect(find.text('لا توجد بيانات متاحة بعد لهذه الخدمة.'), findsOneWidget,
          reason: 'Empty account response must be visible for ${tool.id}');
      expect(tester.takeException(), isNull,
          reason: 'UI exception for ${tool.id}');
    }
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('API failure is shown and user can retry rather than waiting forever',
      (tester) async {
    var callCount = 0;
    await tester.pumpWidget(host(
      const DriverToolScreen(toolId: 'documents'),
      overrides: [
        toolDataProvider('documents').overrideWith((ref) async {
          callCount++;
          throw StateError('controlled service failure');
        }),
      ],
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('controlled service failure'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(callCount, greaterThanOrEqualTo(2));
    expect(find.textContaining('controlled service failure'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
