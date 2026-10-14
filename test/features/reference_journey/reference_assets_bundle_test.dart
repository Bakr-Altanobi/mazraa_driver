import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/features/reference_journey/reference_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('all 48-screen runtime assets are lightweight and readable', (
    tester,
  ) async {
    final uniquePaths = ReferenceAssets.byScreen.values
        .expand((assets) => assets)
        .map((asset) => asset.path)
        .toSet()
        .toList()
      ..sort();

    expect(uniquePaths, hasLength(24));

    var totalBytes = 0;
    for (final path in uniquePaths) {
      expect(
        path,
        startsWith('assets/reference_runtime/'),
        reason: 'Production UI must not bundle the original 1920px reference PNGs.',
      );
      expect(path, endsWith('.webp'));

      final data = await rootBundle.load(path);
      expect(
        data.lengthInBytes,
        greaterThan(0),
        reason: 'Reference runtime asset must be bundled: $path',
      );
      totalBytes += data.lengthInBytes;
    }

    expect(
      totalBytes,
      lessThan(2500000),
      reason: 'Reference artwork must stay below the runtime bundle size budget.',
    );
  });
}
