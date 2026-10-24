import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/features/shell/driver_context_navigation.dart';

void main() {
  test('five main tabs keep their native shell navigation', () {
    for (final path in [
      '/home', '/shipments', '/wallet', '/notifications', '/profile',
      '/login', '/splash', '/onboarding',
    ]) {
      expect(showContextualDriverBar(path), isFalse);
    }
  });
  test('secondary page footer changes according to current workflow', () {
    expect(driverDestinationsFor('/shipments/9/navigation')
        .map((x) => x.route),
        containsAll(['/shipments', '/tools/current-trips', '/offers']));
    expect(driverDestinationsFor('/tools/scheduled-trips')
        .map((x) => x.route), contains('/tools/availability'));
    expect(driverDestinationsFor('/chats/7')
        .map((x) => x.route), contains('/tools/chats'));
    expect(driverDestinationsFor('/tools/vehicle-change')
        .map((x) => x.route), contains('/tools/vehicle'));
    expect(driverDestinationsFor('/cash-custody')
        .map((x) => x.route), contains('/tools/earnings'));
    expect(showContextualDriverBar('/tools/vehicle-change'), isTrue);
  });
}
