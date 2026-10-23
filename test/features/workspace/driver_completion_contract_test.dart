import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/features/workspace/driver_tool_catalog.dart';
import 'package:mazraa_driver/features/workspace/driver_forms.dart';

void main() {
  test('completed driver requests use real endpoints, not pending placeholders', () {
    final vehicle = driverTool('vehicle-change');
    final deletion = driverTool('delete-account');
    expect(vehicle.endpoint, 'api/driver-journey/me/vehicle-change-requests');
    expect(deletion.endpoint, 'api/driver-journey/me/deletion-request');
    expect(vehicle.pending, isFalse);
    expect(deletion.pending, isFalse);
    expect(vehicle.form, 'vehicle-change');
    expect(deletion.form, 'deletion');
  });

  test('per-delivery earnings are distinct from wallet transactions', () {
    expect(driverTool('earnings').endpoint, 'api/driver-journey/earnings');
    expect(driverTool('earnings').endpoint, isNot('api/wallets/transactions'));
  });

  test('request deletion requires affirmative consent before server submission', () {
    expect(
      () => normalizeToolForm('deletion', {
        'reason': 'I would like to close my driver account',
        'confirmed': false,
      }),
      throwsFormatException,
    );
    final accepted = normalizeToolForm('deletion', {
      'reason': 'I would like to close my driver account',
      'confirmed': true,
    });
    expect(accepted['confirmed'], isTrue);
  });
}
