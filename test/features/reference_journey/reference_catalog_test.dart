import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/features/reference_journey/reference_assets.dart';
import 'package:mazraa_driver/features/reference_journey/reference_catalog.dart';

void main() {
  group('48-screen reference catalog', () {
    test('contains exactly screens 01 through 48', () {
      expect(ReferenceCatalog.screens, hasLength(48));
      expect(
        ReferenceCatalog.screens.map((screen) => screen.number).toList(),
        List<int>.generate(48, (index) => index + 1),
      );
    });

    test('every screen exposes exactly five indexed design assets', () {
      expect(ReferenceAssets.byScreen, hasLength(48));
      for (final screen in ReferenceCatalog.screens) {
        expect(
          screen.assets,
          hasLength(5),
          reason: 'screen ${screen.number} must match ASSET_INDEX.csv',
        );
        for (final asset in screen.assets) {
          expect(asset.name, startsWith('asset_'));
          expect(asset.path, startsWith('refrinces/assets_primary/'));
          expect(asset.path, endsWith('.png'));
        }
      }
    });

    test('all post-login screens have a real server source or explicit gap', () {
      for (final screen in ReferenceCatalog.screens.where(
        (screen) => screen.number >= 3,
      )) {
        expect(
          screen.sources.isNotEmpty || screen.unsupported.isNotEmpty,
          isTrue,
          reason:
              'screen ${screen.number} must not silently invent or omit server data',
        );
      }
    });

    test('known unsupported backend contracts stay visible', () {
      expect(ReferenceCatalog.screen(10).unsupported, isNotEmpty);
      expect(ReferenceCatalog.screen(16).unsupported, isNotEmpty);
      expect(ReferenceCatalog.screen(24).unsupported, isNotEmpty);
      expect(ReferenceCatalog.screen(30).unsupported, isNotEmpty);
      expect(ReferenceCatalog.screen(48).unsupported, isNotEmpty);
    });
  });
}
