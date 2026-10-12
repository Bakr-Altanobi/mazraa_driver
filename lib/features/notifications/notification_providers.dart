import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/core/network/providers.dart';

final notificationsProvider = FutureProvider<List<AppNotification>>((
  ref,
) async {
  return ref.watch(driverApiProvider).getNotifications();
});

final unreadNotificationsProvider = FutureProvider<int>((ref) async {
  return ref.watch(driverApiProvider).unreadNotificationCount();
});
