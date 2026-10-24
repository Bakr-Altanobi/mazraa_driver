import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/features/notifications/notification_navigation.dart';

void main() {
  test('chat replies open the exact server conversation, not shipment', () {
    final item = AppNotification.fromJson({
      'id': 1, 'title': 'رسالة جديدة', 'message': 'شكراً',
      'isRead': false, 'eventType': 'chat.message_received',
      'deepLink': '/chats/82',
      'dataJson': '{"chatId":"82","senderId":"12"}',
    });
    expect(item.chatId, 82);
    expect(notificationDestination(item), '/chats/82');
  });
  test('saved chat data enables fallback when old notification lacks a deep link', () {
    final item = AppNotification.fromJson({
      'id': 2, 'title': 'New chat', 'eventType': 'chat.message_received',
      'dataJson': '{"chatId":"25"}',
    });
    expect(notificationDestination(item), '/chats/25');
  });
  test('shipment and scheduled event routes are preserved', () {
    expect(safeDriverNotificationRoute(
      eventType: 'driver.scheduled_shipment_ready',
      shipmentId: 42), '/shipments/42');
    expect(safeDriverNotificationRoute(
      eventType: 'driver.trip_assigned',
      deepLink: '/tools/current-trips/77'), '/tools/current-trips/77');
    expect(safeDriverNotificationRoute(
      eventType: 'driver.trip_assigned'), '/tools/scheduled-trips');
  });
  test('untrusted deep links never navigate outside the app', () {
    for (final link in [
      'https://malicious.example', '//malicious.example',
      '/chats/-2', '/tools/delete-account', '/../../../admin',
      '/chats/7?token=abc',
    ]) {
      expect(safeDriverNotificationRoute(deepLink: link), isNull);
    }
  });
}
