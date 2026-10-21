import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/features/workspace/driver_tool_screens.dart';
import 'package:mazraa_driver/features/workspace/driver_forms.dart';
import 'package:mazraa_driver/features/workspace/driver_workspace_repository.dart';
import 'driver_workspace_test.dart' show host;

void main() {
  testWidgets('capture driver operational screens in Arabic light and dark', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final trip = {
      'id': 8,
      'plannedDepartureAt': '2026-12-01T06:00:00Z',
      'plannedArrivalAt': '2026-12-01T12:00:00Z',
      'dropoffName': 'نقطة استلام السوق',
      'maxWeightKg': 2000,
      'maxVolumeM3': 15,
    };
    for (final dark in [false, true]) {
      for (final screen in ['scheduled-trips', 'availability', 'incident']) {
        final key = GlobalKey();
        final child = screen == 'scheduled-trips'
            ? DriverToolScreen(toolId: screen)
            : DriverToolFormScreen(
                form: screen == 'availability' ? 'availability' : 'incident',
                title: screen == 'availability'
                    ? 'جدول التوفر الأسبوعي'
                    : 'الإبلاغ عن مشكلة',
              );
        await tester.pumpWidget(
          host(
            RepaintBoundary(key: key, child: child),
            dark: dark,
            overrides: [
              toolDataProvider('scheduled-trips').overrideWith(
                (ref) async => [
                  {'trip': trip, 'participation': null},
                ],
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final image =
              await (key.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          final f = File(
            'build/driver-qa/$screen-${dark ? 'dark' : 'light'}.png',
          );
          await f.parent.create(recursive: true);
          await f.writeAsBytes(bytes!.buffer.asUint8List());
        });
      }
    }
  });
}
