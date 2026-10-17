import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/features/shipments/driver_offers_panel.dart';

void main() {
  test('parses the backend DriverOfferDto without invented fields', () {
    final offer = DriverOffer.fromJson({
      'offerId': 12,
      'shipmentId': 46,
      'shipmentNumber': 'SHP-46',
      'storeId': 6,
      'pickupLatitude': 15.3,
      'pickupLongitude': 44.2,
      'customerLatitude': 15.4,
      'customerLongitude': 44.3,
      'distanceToPickupKm': 5.7,
      'expiresAt': DateTime.now().toUtc().add(const Duration(minutes: 8)).toIso8601String(),
      'secondsRemaining': 480,
      'round': 1,
    });
    expect(offer.offerId, 12);
    expect(offer.shipmentId, 46);
    expect(offer.shipmentNumber, 'SHP-46');
    expect(offer.distanceToPickupKm, 5.7);
    expect(offer.isExpired, isFalse);
  });

  test('rejects an offer without a server-issued ID', () {
    expect(
      () => DriverOffer.fromJson({
        'shipmentId': 46,
        'expiresAt': '2026-10-19T00:00:00Z',
      }),
      throwsFormatException,
    );
  });

  test('expired offers cannot be accepted from stale cached UI', () {
    final offer = DriverOffer.fromJson({
      'offerId': 12,
      'shipmentId': 46,
      'expiresAt': '2020-01-01T00:00:00Z',
      'secondsRemaining': 0,
    });
    expect(offer.isExpired, isTrue);
  });
}
