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
      eventType: 'driver.trip_assigned'), '/tools/current-trips');
  });
  test('account, financial, safety and vehicle events route to relevant workflows', () {
    expect(safeDriverNotificationRoute(eventType: 'driver.vehicle_change_reviewed'),
        '/tools/vehicle-change');
    expect(safeDriverNotificationRoute(eventType: 'driver.document_approved'),
        '/tools/documents');
    expect(safeDriverNotificationRoute(eventType: 'driver.cash_remitted'),
        '/cash-custody');
    expect(safeDriverNotificationRoute(eventType: 'driver.incident_update'),
        '/tools/incidents');
    expect(safeDriverNotificationRoute(eventType: 'driver.referral_reward'),
        '/tools/referral');
    expect(safeDriverNotificationRoute(eventType: 'driver.account_suspended'),
        '/tools/account-status');
    expect(safeDriverNotificationRoute(
        deepLink: '/tools/vehicle-change',
        eventType: 'driver.request_reviewed'), '/tools/vehicle-change');
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
