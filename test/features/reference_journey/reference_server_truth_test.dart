import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reference journey never hard-codes unsupported verification as confirmed', () {
    final body = File(
      'lib/features/reference_journey/reference_production_body.dart',
    ).readAsStringSync();

    expect(body, isNot(contains("('مطابقة رقم الشحنة', true)")));
    expect(body, isNot(contains("('التحقق من الشحنة', true)")));
    expect(body, isNot(contains("('رقم الشحنة', true)")));
  });

  test('driver return screen never consumes customer-scoped returns as driver jobs', () {
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
    expect(catalog, contains('ReferenceAction.completeReturn'));
  });
}
