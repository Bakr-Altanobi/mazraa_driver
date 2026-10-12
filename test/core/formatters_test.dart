import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/core/utils/formatters.dart';

void main() {
  test('distance formatting chooses meters below one kilometer', () {
    expect(formatDistance(.72, arabic: false), '720 m');
    expect(formatDistance(12.4, arabic: false), '12 km');
  });

  test('ETA formatting handles hours and missing values', () {
    expect(formatEta(28, arabic: false), '28 min');
    expect(formatEta(75, arabic: false), '1h 15m');
    expect(formatEta(null, arabic: false), 'Unavailable');
  });

  test('financial formatting preserves the explicit currency', () {
    expect(formatMoney(500, 'SAR', locale: 'en'), contains('500'));
  });
}
