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
          // The logical asset name is the ASSET_INDEX contract. The original
          // PNG source remains under refrinces/assets_primary and is validated
          // separately by reference_asset_index_contract_test.dart. Production
          // intentionally renders the lightweight derivative of those pixels.
          expect(asset.name, startsWith('asset_'));
          expect(asset.path, startsWith('assets/reference_runtime/'));
          expect(asset.path, endsWith('.webp'));
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

    test('new driver journey contracts replace the former fake backend gaps', () {
      expect(
        ReferenceCatalog.screen(10).sources,
        containsAll(<ReferenceDataSource>[
          ReferenceDataSource.bankAccounts,
          ReferenceDataSource.payouts,
        ]),
      );
      expect(ReferenceCatalog.screen(10).unsupported, isEmpty);

      expect(
        ReferenceCatalog.screen(16).sources,
        containsAll(<ReferenceDataSource>[
          ReferenceDataSource.availability,
          ReferenceDataSource.preferences,
          ReferenceDataSource.shifts,
        ]),
      );
      expect(ReferenceCatalog.screen(16).unsupported, isEmpty);

      expect(
        ReferenceCatalog.screen(24).sources,
        contains(ReferenceDataSource.referral),
      );
      expect(ReferenceCatalog.screen(24).unsupported, isEmpty);

      expect(
        ReferenceCatalog.screen(30).sources,
        contains(ReferenceDataSource.bankAccounts),
      );
      expect(ReferenceCatalog.screen(30).unsupported, isEmpty);
    });

    test('genuine backend gaps remain explicit instead of invented', () {
      expect(ReferenceCatalog.screen(2).unsupported, isNotEmpty);
      expect(ReferenceCatalog.screen(5).unsupported, isNotEmpty);
      expect(ReferenceCatalog.screen(33).unsupported, isNotEmpty);
      expect(ReferenceCatalog.screen(48).unsupported, isNotEmpty);
    });
  });
}
