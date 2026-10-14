import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/features/reference_journey/reference_assets.dart';

void main() {
  test('ReferenceAssets matches ASSET_INDEX.csv screen by screen', () async {
    final file = File('refrinces/assets_primary/ASSET_INDEX.csv');
    expect(await file.exists(), isTrue, reason: 'ASSET_INDEX.csv must exist');

    final lines = await file.readAsLines();
    expect(lines.first, startsWith('screen,asset_filename,source,'));

    final expectedByScreen = <int, List<String>>{};
    for (final line in lines.skip(1)) {
      if (line.trim().isEmpty) continue;
      final columns = line.split(',');
      expect(columns.length, greaterThanOrEqualTo(5));
      final screen = int.parse(columns[0]);
      final sourceName = columns[2].replaceFirst(RegExp(r'\.png$'), '');
      expectedByScreen.putIfAbsent(screen, () => <String>[]).add(sourceName);
    }

    expect(expectedByScreen, hasLength(48));
    expect(ReferenceAssets.byScreen, hasLength(48));

    for (var screen = 1; screen <= 48; screen++) {
      final expected = expectedByScreen[screen];
      final actual = ReferenceAssets.byScreen[screen]?.map((slot) => slot.name).toList();
      expect(expected, isNotNull, reason: 'screen $screen missing from ASSET_INDEX');
      expect(expected, hasLength(5));
      expect(actual, expected, reason: 'screen $screen asset order/name mismatch');
    }
  });
}
