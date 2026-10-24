import 'package:mazraa_driver/core/models/app_models.dart';

/// Accept only in-app routes that belong to the authenticated driver's UI.
/// Never navigate to an arbitrary server-provided URL or another user's ID
/// without the endpoint's authorization check.
String? safeDriverNotificationRoute({
  String? deepLink,
  String? eventType,
  int? shipmentId,
  int? chatId,
}) {
  if (deepLink != null && deepLink.isNotEmpty) {
    final uri = Uri.tryParse(deepLink);
    if (uri != null &&
        !uri.hasScheme &&
        uri.host.isEmpty &&
        uri.query.isEmpty &&
        uri.fragment.isEmpty) {
      final path = uri.path;
      if (RegExp(r'^/chats/[1-9][0-9]*$').hasMatch(path) ||
          RegExp(r'^/shipments/[1-9][0-9]*
          RegExp(r'^/support/tickets/[1-9][0-9]*$').hasMatch(path)) {
        return path;
      }
      if (const {
        '/offers', '/notifications', '/tools/current-trips',
        '/tools/scheduled-trips', '/tools/earnings', '/wallet',
        '/tools/incidents', '/tools/returns', '/support',
        '/tools/feedback', '/tools/account-status',
      }.contains(path)) {
        return path;
      }
    }
  }
  final event = eventType?.toLowerCase() ?? '';
  if (event.startsWith('chat.') && chatId != null && chatId > 0) {
    return '/chats/$chatId';
  }
  if (event.startsWith('chat.')) return '/tools/chats';
  if (shipmentId != null && shipmentId > 0) return '/shipments/$shipmentId';
  if (event.contains('scheduled') || event.contains('trip')) {
    return '/tools/scheduled-trips';
  }
  if (event.contains('offer')) return '/offers';
  if (event.contains('payout') || event.contains('earning')) {
    return '/tools/earnings';
  }
  if (event.contains('support') || event.contains('ticket')) return '/support';
  if (event.contains('return')) return '/tools/returns';
  return null;
}

String? notificationDestination(AppNotification item) =>
    safeDriverNotificationRoute(
      deepLink: item.deepLink, eventType: item.eventType,
      chatId: item.chatId, shipmentId: item.shipmentId,
    );
).hasMatch(path) ||
          RegExp(r'^/tools/current-trips/[1-9][0-9]*
          RegExp(r'^/support/tickets/[1-9][0-9]*$').hasMatch(path)) {
        return path;
      }
      if (const {
        '/offers', '/notifications', '/tools/current-trips',
        '/tools/scheduled-trips', '/tools/earnings', '/wallet',
        '/tools/incidents', '/tools/returns', '/support',
        '/tools/feedback', '/tools/account-status',
      }.contains(path)) {
        return path;
      }
    }
  }
  final event = eventType?.toLowerCase() ?? '';
  if (event.startsWith('chat.') && chatId != null && chatId > 0) {
    return '/chats/$chatId';
  }
  if (event.startsWith('chat.')) return '/tools/chats';
  if (shipmentId != null && shipmentId > 0) return '/shipments/$shipmentId';
  if (event.contains('scheduled') || event.contains('trip')) {
    return '/tools/scheduled-trips';
  }
  if (event.contains('offer')) return '/offers';
  if (event.contains('payout') || event.contains('earning')) {
    return '/tools/earnings';
  }
  if (event.contains('support') || event.contains('ticket')) return '/support';
  if (event.contains('return')) return '/tools/returns';
  return null;
}

String? notificationDestination(AppNotification item) =>
    safeDriverNotificationRoute(
      deepLink: item.deepLink, eventType: item.eventType,
      chatId: item.chatId, shipmentId: item.shipmentId,
    );
).hasMatch(path) ||
          RegExp(r'^/support/tickets/[1-9][0-9]*$').hasMatch(path)) {
        return path;
      }
      if (const {
        '/offers', '/notifications', '/tools/current-trips',
        '/tools/scheduled-trips', '/tools/earnings', '/wallet',
        '/tools/incidents', '/tools/returns', '/support',
        '/tools/feedback', '/tools/account-status',
      }.contains(path)) {
        return path;
      }
    }
  }
  final event = eventType?.toLowerCase() ?? '';
  if (event.startsWith('chat.') && chatId != null && chatId > 0) {
    return '/chats/$chatId';
  }
  if (event.startsWith('chat.')) return '/tools/chats';
  if (shipmentId != null && shipmentId > 0) return '/shipments/$shipmentId';
  if (event.contains('scheduled') || event.contains('trip')) {
    return '/tools/scheduled-trips';
  }
  if (event.contains('offer')) return '/offers';
  if (event.contains('payout') || event.contains('earning')) {
    return '/tools/earnings';
  }
  if (event.contains('support') || event.contains('ticket')) return '/support';
  if (event.contains('return')) return '/tools/returns';
  return null;
}

String? notificationDestination(AppNotification item) =>
    safeDriverNotificationRoute(
      deepLink: item.deepLink, eventType: item.eventType,
      chatId: item.chatId, shipmentId: item.shipmentId,
    );
