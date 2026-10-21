import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazraa_driver/core/network/providers.dart';
import 'package:mazraa_driver/shared/widgets/mazraa_widgets.dart';
import 'package:mazraa_driver/features/support/driver_support_screen.dart';
import 'driver_tool_screens.dart';
import 'driver_workspace_repository.dart';

final driverTicketProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>(
      (ref, id) => ref
          .watch(apiClientProvider)
          .get<Map<String, dynamic>>('api/support/tickets/$id'),
    );

class DriverTicketScreen extends ConsumerStatefulWidget {
  const DriverTicketScreen({required this.ticketId, super.key});
  final int ticketId;
  @override
  ConsumerState<DriverTicketScreen> createState() => _DriverTicketScreenState();
}

class _DriverTicketScreenState extends ConsumerState<DriverTicketScreen> {
  final _message = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _action(bool close) async {
    if (_busy || !close && _message.text.trim().isEmpty) return;
    if (close &&
        !await confirmAction(
          context,
          title: toolText(context, 'إغلاق التذكرة', 'Close ticket'),
          message: toolText(
            context,
            'هل حُلت المشكلة؟',
            'Has this issue been resolved?',
          ),
          confirmLabel: toolText(context, 'إغلاق', 'Close'),
        ))
      return;
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(apiClientProvider)
          .post<dynamic>(
            'api/support/tickets/${widget.ticketId}/${close ? 'close' : 'messages'}',
            data: close ? null : {'body': _message.text.trim()},
          );
      _message.clear();
      ref.invalidate(driverTicketProvider(widget.ticketId));
      ref.invalidate(supportTicketsProvider);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext c) {
    final data = ref.watch(driverTicketProvider(widget.ticketId));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${toolText(c, 'تذكرة الدعم', 'Support ticket')} #${widget.ticketId}',
        ),
      ),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          error: e,
          onRetry: () => ref.invalidate(driverTicketProvider(widget.ticketId)),
        ),
        data: (ticket) => ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              '${ticket['subject'] ?? ''}',
              style: Theme.of(c).textTheme.titleLarge,
            ),
            Text('${ticket['number'] ?? ''} · ${ticket['status'] ?? ''}'),
            for (final m in recordRows(ticket['messages']))
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${m['senderName'] ?? ''}',
                          style: Theme.of(c).textTheme.labelMedium,
                        ),
                        Text('${m['body'] ?? ''}'),
                        Text(
                          '${m['createdAt'] ?? ''}',
                          style: Theme.of(c).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (ticket['status'] != 'closed') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _message,
                enabled: !_busy,
                maxLines: 4,
                maxLength: 4000,
                decoration: InputDecoration(
                  labelText: toolText(c, 'ردك على الدعم', 'Reply to support'),
                ),
              ),
              FilledButton(
                onPressed: _busy ? null : () => _action(false),
                child: Text(toolText(c, 'إرسال الرد', 'Send reply')),
              ),
              TextButton(
                onPressed: _busy ? null : () => _action(true),
                child: Text(
                  toolText(
                    c,
                    'تم الحل، إغلاق التذكرة',
                    'Resolved, close ticket',
                  ),
                ),
              ),
            ],
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(c).colorScheme.error),
              ),
          ],
        ),
      ),
    );
  }
}

class DriverChatAttachmentScreen extends StatelessWidget {
  const DriverChatAttachmentScreen({required this.url, super.key});
  final String url;
  @override
  Widget build(BuildContext c) {
    final uri = Uri.tryParse(url);
    final valid = uri != null && uri.scheme == 'https';
    return Scaffold(
      appBar: AppBar(
        title: Text(toolText(c, 'الصورة المرفقة', 'Photo attachment')),
      ),
      body: Center(
        child: valid
            ? InteractiveViewer(
                child: Image.network(
                  url,
                  errorBuilder: (c, e, s) => Text(
                    toolText(c, 'تعذر تحميل الصورة', 'Could not load image'),
                  ),
                ),
              )
            : Text(toolText(c, 'رابط الصورة غير صالح', 'Invalid image URL')),
      ),
    );
  }
}
