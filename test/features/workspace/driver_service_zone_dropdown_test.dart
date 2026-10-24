import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/features/workspace/driver_service_areas_screen.dart';

void main() {
  test('duplicate zone ids from service API become one dropdown value', () {
    final items = serviceZoneOptions([
      {'id': 3, 'name': 'North'},
      {'id': 3, 'name': 'North - updated'},
      {'id': 7, 'name': 'South'},
    ], selectedId: 3);
    expect(items.length, 2);
    expect(items[3], 'North - updated');
  });

  test('editing previously chosen area remains renderable if removed from catalog', () {
    final items = serviceZoneOptions([
      {'id': 7, 'name': 'South'},
    ], selectedId: 3, selectedLabel: 'North');
    expect(items.keys.where((id) => id == 3).length, 1);
    expect(items[3], 'North');
  });

  test('invalid and non-positive zone identifiers do not become options', () {
    final items = serviceZoneOptions([
      {'id': null, 'name': 'Invalid'},
      {'id': -1, 'name': 'Invalid'},
      {'id': '7', 'name': 'Untrusted'},
      {'id': 9, 'name': 'Valid'},
    ]);
    expect(items, {9: 'Valid'});
  });
}
