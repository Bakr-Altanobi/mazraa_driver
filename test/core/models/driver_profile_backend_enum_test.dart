import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/core/models/app_models.dart';

void main() {
  Map<String, dynamic> driverJson(int status, int approval, int vehicle) => {
        'userId': 7,
        'name': 'Driver',
        'email': 'driver@example.test',
        'phone': '000',
        'vehicleType': vehicle,
        'approvalStatus': approval,
        'operationalStatus': status,
        'isAcceptingOrders': false,
        'isVerified': true,
        'ratingAverage': 0,
        'ratingCount': 0,
      };

  test('backend status 1 is Offline, status 2 is Online', () {
    expect(DriverProfile.fromJson(driverJson(1, 2, 0)).operationalStatus, 'Offline');
    expect(DriverProfile.fromJson(driverJson(2, 2, 0)).operationalStatus, 'Online');
    expect(DriverProfile.fromJson(driverJson(3, 2, 0)).operationalStatus, 'Available');
    expect(DriverProfile.fromJson(driverJson(4, 2, 0)).operationalStatus, 'Busy');
  });

  test('backend approval 2 is approved, not rejected', () {
    expect(DriverProfile.fromJson(driverJson(1, 2, 1)).isApproved, isTrue);
    expect(DriverProfile.fromJson(driverJson(1, 1, 1)).isApproved, isFalse);
  });

  test('backend vehicle 0 is Car and 1 is Bike', () {
    expect(DriverProfile.fromJson(driverJson(1, 2, 0)).vehicleType, 'Car');
    expect(DriverProfile.fromJson(driverJson(1, 2, 1)).vehicleType, 'Bike');
  });
}
