import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/core/network/providers.dart';
import 'package:mazraa_driver/core/theme/app_theme.dart';
import 'package:mazraa_driver/core/utils/formatters.dart';
import 'package:mazraa_driver/features/notifications/notification_providers.dart';
import 'package:mazraa_driver/shared/widgets/mazraa_widgets.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _markAll(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(driverApiProvider).markAllNotificationsRead();
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationsProvider);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ar = isArabic(context);
    final state = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadNotificationsProvider).valueOrNull ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: Text(ar ? 'الإشعارات' : 'Notifications'),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () => _markAll(context, ref),
              child: Text(ar ? 'قراءة الكل' : 'Mark all read'),
            ),
        ],
      ),
      body: state.when(
        loading: LoadingList.new,
        error: (error, _) => ErrorState(
          error: error,
          onRetry: () => ref.invalidate(notificationsProvider),
        ),
        data: (items) => items.isEmpty
            ? EmptyState(
                title: ar ? 'لا توجد إشعارات' : 'No notifications',
                message: ar
                    ? 'ستصلك هنا تحديثات الشحنات والحساب.'
                    : 'Shipment and account updates will appear here.',
              )
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(notificationsProvider);
                  ref.invalidate(unreadNotificationsProvider);
                  await ref.read(notificationsProvider.future);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 9),
                  itemBuilder: (context, index) =>
                      _NotificationCard(notification: items[index]),
                ),
              ),
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  const _NotificationCard({required this.notification});
  final AppNotification notification;

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    if (!notification.isRead) {
      try {
        await ref.read(driverApiProvider).markNotificationsRead([
          notification.id,
        ]);
        ref.invalidate(notificationsProvider);
        ref.invalidate(unreadNotificationsProvider);
      } catch (_) {
        // Reading the target remains useful even if the read receipt fails.
      }
    }
    if (context.mounted && notification.shipmentId != null) {
      context.push('/shipments/${notification.shipmentId}');
    } else if (context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(notification.title),
          content: SingleChildScrollView(
            child: SelectableText(notification.message),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text(isArabic(c) ? 'إغلاق' : 'Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ar = isArabic(context);
    final color = _notificationColor(notification.eventType);
    return Card(
      color: notification.isRead
          ? null
          : color.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? .12
                  : .06,
            ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _open(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: .13),
                child: Icon(
                  _notificationIcon(notification.eventType),
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatDateTime(
                        notification.createdAt,
                        locale: ar ? 'ar' : 'en',
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (notification.shipmentId != null)
                const Padding(
                  padding: EdgeInsetsDirectional.only(start: 6, top: 25),
                  child: Icon(Icons.chevron_right_rounded),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _notificationColor(String? event) {
  final value = event?.toLowerCase() ?? '';
  if (value.contains('failed') || value.contains('cancel')) {
    return MazraaColors.danger;
  }
  if (value.contains('delivered')) return MazraaColors.success;
  if (value.contains('assigned') || value.contains('created')) {
    return MazraaColors.orange;
  }
  return MazraaColors.forest;
}

IconData _notificationIcon(String? event) {
  final value = event?.toLowerCase() ?? '';
  if (value.contains('failed')) return Icons.report_problem_outlined;
  if (value.contains('delivered')) return Icons.task_alt_rounded;
  if (value.contains('shipment')) return Icons.local_shipping_outlined;
  return Icons.notifications_none_rounded;
}
