import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/features/operations/driver_live_providers.dart';

void main() {
  test('server numeric driver enums are not read as zero-indexed labels', () {
    final profile = DriverProfile.fromJson({
      'userId': 6,
      'name': 'Test Driver',
      'email': 'test@example.invalid',
      'phone': '',
      'vehicleType': 2,
      'approvalStatus': 2,
      'operationalStatus': 3,
      'isAcceptingOrders': true,
      'isVerified': true,
      'ratingAverage': 4.2,
      'ratingCount': 14,
    });
    expect(profile.vehicleType, 'Van');
    expect(profile.approvalStatus, 'Approved');
    expect(profile.isApproved, isTrue);
    expect(profile.operationalStatus, 'Available');
  });

  test('server string enum labels remain supported', () {
    final profile = DriverProfile.fromJson({
      'userId': 7,
      'name': 'Test Driver',
      'email': 'test@example.invalid',
      'phone': '',
      'vehicleType': 'Bike',
      'approvalStatus': 'Approved',
      'operationalStatus': 'Online',
      'isAcceptingOrders': true,
      'isVerified': true,
      'ratingAverage': 0,
      'ratingCount': 0,
    });
    expect(profile.isApproved, isTrue);
    expect(profile.vehicleType, 'Bike');
    expect(profile.operationalStatus, 'Online');
  });

  test('live offer JSON requires real offer id and expiry', () {
    final future = DateTime.now().toUtc().add(const Duration(minutes: 2));
    final offer = DriverOffer.fromJson({
      'offerId': 501,
      'shipmentId': 902,
      'shipmentNumber': 'SHP-902',
      'pickupLatitude': 15.3,
      'pickupLongitude': 44.2,
      'distanceToPickupKm': 2.4,
      'expiresAt': future.toIso8601String(),
    });
    expect(offer.id, 501);
    expect(offer.shipmentId, 902);
    expect(offer.pickup!.latitude, 15.3);
    expect(offer.expiresAt.isAfter(DateTime.now().toUtc()), isTrue);
  });
}
