import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/shared/widgets/shipment_navigation_button.dart';

void main() {
  test('Google Maps destination uses the exact server coordinates', () {
    final uri = ShipmentNavigationButton.navigationUrl(
      const GeoPoint(15.3694, 44.1910),
    );
    expect(uri.scheme, 'https');
    expect(uri.host, 'www.google.com');
    expect(uri.queryParameters['api'], '1');
    expect(uri.queryParameters['travelmode'], 'driving');
    expect(uri.queryParameters['destination'], '15.3694,44.191');
  });

  test('invalid coordinates are rejected before launching maps', () {
    expect(
      () => ShipmentNavigationButton.navigationUrl(
        const GeoPoint(100.0, 200.0),
      ),
      throwsFormatException,
    );
  });
}
