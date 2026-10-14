import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/features/reference_journey/reference_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('all 48-screen canonical assets are packaged and readable', (
    tester,
  ) async {
    final uniquePaths = ReferenceAssets.byScreen.values
        .expand((assets) => assets)
        .map((asset) => asset.path)
        .toSet()
        .toList()
      ..sort();

    expect(uniquePaths, isNotEmpty);

    for (final path in uniquePaths) {
      final data = await rootBundle.load(path);
      expect(
        data.lengthInBytes,
        greaterThan(0),
        reason: 'Reference asset must be bundled: $path',
      );
    }
  });
}
