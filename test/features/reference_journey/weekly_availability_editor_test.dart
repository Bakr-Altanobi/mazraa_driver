import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/features/reference_journey/weekly_availability_editor.dart';

void main() {
  test('converts numeric or named DayOfWeek without changing other windows', () {
    final first = AvailabilityWindow.fromServer({
      'dayOfWeek': 'Monday',
      'startTime': '08:15:00',
      'endTime': '17:30:00',
      'isActive': true,
    });
    final second = AvailabilityWindow.fromServer({
      'dayOfWeek': 5,
      'startTime': '09:00:00.1234567',
      'endTime': '12:00:00',
      'isActive': false,
    });
    expect(first.dayOfWeek, 1);
    expect(first.toServer(), {
      'dayOfWeek': 1,
      'startTime': '08:15:00',
      'endTime': '17:30:00',
      'isActive': true,
    });
    expect(second.toServer()['startTime'], '09:00:00.1234567');
    expect(second.isActive, isFalse);
  });

  test('rejects unknown values rather than overwriting server availability', () {
    expect(
      () => AvailabilityWindow.fromServer({
        'dayOfWeek': 'not-a-day',
        'startTime': '08:00:00',
        'endTime': '10:00:00',
        'isActive': true,
      }),
      throwsFormatException,
    );
    expect(
      () => AvailabilityWindow.fromServer({
        'dayOfWeek': 1,
        'startTime': '8 am',
        'endTime': '10:00:00',
        'isActive': true,
      }),
      throwsFormatException,
    );
    expect(
      () => AvailabilityWindow.fromServer({
        'dayOfWeek': 1,
        'startTime': '08:00:00',
        'endTime': '10:00:00',
      }),
      throwsFormatException,
    );
  });
}
