import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('verification checklists do not claim unsupported steps as confirmed', () {
    final body = File(
      'lib/features/reference_journey/reference_production_body.dart',
    ).readAsStringSync();
    expect(body, isNot(contains("('مطابقة رقم الشحنة', true)")));
    expect(body, isNot(contains("('التحقق من الشحنة', true)")));
    expect(body, isNot(contains("('رقم الشحنة', true)")));
  });

  test('driver return jobs use driver-scoped server contract', () {
    final catalog = File(
      'lib/features/reference_journey/reference_catalog.dart',
    ).readAsStringSync();
    final repository = File(
      'lib/features/reference_journey/reference_repository.dart',
    ).readAsStringSync();
    final body = File(
      'lib/features/reference_journey/reference_production_body.dart',
    ).readAsStringSync();
    expect(catalog, contains('ReferenceDataSource.returns'));
    expect(repository, contains('api/driver-journey/returns'));
    expect(repository, isNot(contains("'api/returns'")));
    expect(body, contains('data.returns'));
  });

  test('all shipment mutations require an explicitly selected target', () {
    final repository = File(
      'lib/features/reference_journey/reference_repository.dart',
    ).readAsStringSync();
    final screen = File(
      'lib/features/reference_journey/reference_screen.dart',
    ).readAsStringSync();
    expect(repository, contains('int? targetId'));
    expect(repository, contains('stillEligible'));
    expect(screen, contains('اختر الطلب المقصود'));
  });

  test('Google Maps never fabricates a default city or fake road', () {
    final map = File('lib/shared/widgets/map_panel.dart').readAsStringSync();
    expect(map, contains('GoogleMap('));
    expect(map, isNot(contains('24.7136')));
    expect(map, isNot(contains('_MapPainter')));
    expect(map, contains('center == null'));
  });
}
