import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/features/workspace/driver_delivery_screens.dart';

void main() {
  test('decodes a provider road polyline without inventing geometry', () {
    // Google's documented encoded polyline sample: three known coordinates.
    final points = decodeRoadPolyline('_p~iF~ps|U_ulLnnqC_mqNvxq`@');
    expect(points, hasLength(3));
    expect(points.first.latitude, closeTo(38.5, 0.00001));
    expect(points.first.longitude, closeTo(-120.2, 0.00001));
    expect(points.last.latitude, closeTo(43.252, 0.00001));
    expect(points.last.longitude, closeTo(-126.453, 0.00001));
  });

  test('malformed and impossible provider polylines are rejected', () {
    expect(() => decodeRoadPolyline('~'), throwsFormatException);
    expect(() => decodeRoadPolyline('!' * 3), throwsFormatException);
    expect(() => decodeRoadPolyline('a' * 200001), throwsFormatException);
  });
}
