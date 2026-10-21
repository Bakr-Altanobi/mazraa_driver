import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mazraa_driver/core/network/providers.dart';
import 'package:mazraa_driver/features/reference_journey/reference_assets.dart';
import 'package:mazraa_driver/shared/widgets/mazraa_widgets.dart';

final supportFaqsProvider = FutureProvider<List<dynamic>>(
  (ref) => ref.watch(apiClientProvider).get<List<dynamic>>('api/support/faqs'),
);
final supportTicketsProvider = FutureProvider<List<dynamic>>(
  (ref) =>
      ref.watch(apiClientProvider).get<List<dynamic>>('api/support/tickets'),
);

class DriverSupportScreen extends ConsumerStatefulWidget {
  const DriverSupportScreen({super.key});
  @override
  ConsumerState<DriverSupportScreen> createState() =>
      _DriverSupportScreenState();
}

class _DriverSupportScreenState extends ConsumerState<DriverSupportScreen> {
  bool _sending = false;

  Future<String?> _textInput(
    String title,
    String label, {
    bool multiline = false,
  }) async {
    final controller = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            maxLines: multiline ? 4 : 1,
            autofocus: true,
            decoration: InputDecoration(labelText: label),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(isArabic(context) ? 'إلغاء' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) Navigator.pop(dialogContext, value);
              },
              child: Text(isArabic(context) ? 'متابعة' : 'Continue'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _newTicket() async {
    if (_sending) return;
    final ar = isArabic(context);
    final subject = await _textInput(
      ar ? 'عنوان التذكرة' : 'Ticket subject',
      ar ? 'الموضوع' : 'Subject',
    );
    if (!mounted || subject == null) return;
    final message = await _textInput(
      ar ? 'شرح المشكلة' : 'Describe your issue',
      ar ? 'التفاصيل' : 'Details',
      multiline: true,
    );
    if (!mounted || message == null) return;
    setState(() => _sending = true);
    try {
      final options = await ref
          .read(apiClientProvider)
          .get<Map<String, dynamic>>('api/support/ticket-options');
      final priority = options['defaultPriority']?.toString() ?? 'normal';
      await ref
          .read(apiClientProvider)
          .post<dynamic>(
            'api/support/tickets',
            data: {
              'subject': subject,
              'message': message,
              'priority': priority,
            },
          );
      ref.invalidate(supportTicketsProvider);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ar ? 'أُرسلت التذكرة للدعم' : 'Support ticket created',
            ),
          ),
        );
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _openChat() async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      final data = await ref
          .read(apiClientProvider)
          .post<Map<String, dynamic>>('api/support/live-chat');
      final id = (data['chatId'] as num?)?.toInt();
      if (id == null || id <= 0)
        throw StateError('Support chat ID unavailable');
      if (mounted) context.push('/chats/$id');
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _reply(int ticketId) async {
    if (_sending) return;
    final ar = isArabic(context);
    final body = await _textInput(
      ar ? 'الرد على التذكرة' : 'Reply to ticket',
      ar ? 'نص الرسالة' : 'Message',
      multiline: true,
    );
    if (!mounted || body == null) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(apiClientProvider)
          .post<dynamic>(
            'api/support/tickets/$ticketId/messages',
            data: {'body': body},
          );
      ref.invalidate(supportTicketsProvider);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ar ? 'تم إرسال الرد' : 'Reply sent')),
        );
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    final faqs = ref.watch(supportFaqsProvider);
    final tickets = ref.watch(supportTicketsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(ar ? 'المساعدة والدعم' : 'Help & support'),
        actions: [
          IconButton(
            onPressed: () {
              ref.invalidate(supportFaqsProvider);
              ref.invalidate(supportTicketsProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(supportFaqsProvider);
          ref.invalidate(supportTicketsProvider);
          await Future.wait([
            ref
                .read(supportFaqsProvider.future)
                .then((_) {}, onError: (Object e, StackTrace st) {}),
            ref
                .read(supportTicketsProvider.future)
                .then((_) {}, onError: (Object e, StackTrace st) {}),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 36),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(17),
                child: Row(
                  children: [
                    Image.asset(
                      ReferenceAssets.supportHeadset,
                      width: 90,
                      height: 90,
                      cacheWidth: 220,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ar ? 'نحن هنا لمساعدتك' : 'We are here to help',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            ar
                                ? 'المحادثات والتذاكر محفوظة على سيرفر مزرعتي.'
                                : 'Messages and tickets are saved in Mazraa.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _sending ? null : _openChat,
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: Text(ar ? 'محادثة الدعم' : 'Support chat'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _sending ? null : _newTicket,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(ar ? 'تذكرة جديدة' : 'New ticket'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              ar ? 'تذاكرك' : 'Your tickets',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            tickets.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorState(
                error: error,
                onRetry: () => ref.invalidate(supportTicketsProvider),
              ),
              data: (rows) => rows.isEmpty
                  ? ListTile(
                      title: Text(ar ? 'لا توجد تذاكر بعد' : 'No tickets yet'),
                    )
                  : Column(
                      children: [
                        for (final row
                            in rows.whereType<Map<String, dynamic>>())
                          Card(
                            child: ListTile(
                              leading: const Icon(
                                Icons.confirmation_number_outlined,
                              ),
                              title: Text(row['subject']?.toString() ?? ''),
                              onTap: () =>
                                  context.push('/support/tickets/${row['id']}'),
                              subtitle: Text(
                                '${row['number'] ?? '#'} · ${row['status'] ?? ''}',
                              ),
                              trailing: row['status'] == 'closed'
                                  ? null
                                  : IconButton(
                                      tooltip: ar ? 'الرد' : 'Reply',
                                      icon: const Icon(Icons.reply_rounded),
                                      onPressed: _sending
                                          ? null
                                          : () => _reply(
                                              (row['id'] as num).toInt(),
                                            ),
                                    ),
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),
            Text(
              ar ? 'الأسئلة الشائعة' : 'FAQs',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            faqs.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorState(
                error: error,
                onRetry: () => ref.invalidate(supportFaqsProvider),
              ),
              data: (rows) => rows.isEmpty
                  ? ListTile(
                      title: Text(
                        ar ? 'لا توجد أسئلة منشورة' : 'No FAQs published',
                      ),
                    )
                  : Card(
                      child: Column(
                        children: [
                          for (final row
                              in rows.whereType<Map<String, dynamic>>())
                            ExpansionTile(
                              title: Text(row['question']?.toString() ?? ''),
                              childrenPadding: const EdgeInsets.all(16),
                              children: [Text(row['answer']?.toString() ?? '')],
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

final driverChatMessagesProvider = FutureProvider.autoDispose
    .family<List<dynamic>, int>((ref, id) async {
      final response = await ref
          .watch(apiClientProvider)
          .get<Map<String, dynamic>>('api/chats/$id/messages');
      return response['data'] as List<dynamic>? ?? const [];
    });

class DriverChatScreen extends ConsumerStatefulWidget {
  const DriverChatScreen({required this.chatId, super.key});
  final int chatId;
  @override
  ConsumerState<DriverChatScreen> createState() => _DriverChatScreenState();
}

class _DriverChatScreenState extends ConsumerState<DriverChatScreen> {
  final _message = TextEditingController();
  bool _sending = false;
  XFile? _image;
  int? _pendingMessageId;
  Timer? _poll;
  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted &&
          ModalRoute.of(context)?.isCurrent == true &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed)
        ref.invalidate(driverChatMessagesProvider(widget.chatId));
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _message.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 82,
      );
      if (mounted && image != null) setState(() => _image = image);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _send() async {
    final body = _message.text.trim();
    if (_sending || (body.isEmpty && _image == null)) return;
    setState(() => _sending = true);
    try {
      final client = ref.read(apiClientProvider);
      if (_pendingMessageId == null) {
        final result = await client.post<Map<String, dynamic>>(
          'api/chats/${widget.chatId}/messages',
          data: {
            'body': body.isEmpty
                ? (isArabic(context) ? 'صورة مرفقة' : 'Photo attachment')
                : body,
          },
        );
        if (_image != null) _pendingMessageId = (result['id'] as num?)?.toInt();
        if (_image != null && _pendingMessageId == null)
          throw StateError('Message ID unavailable; attachment not sent');
      }
      if (_image != null)
        await client.uploadFile(
          'api/chats/${widget.chatId}/messages/$_pendingMessageId/attachment',
          filePath: _image!.path,
          fileName: _image!.name,
          fields: const {},
        );
      _message.clear();
      if (mounted)
        setState(() {
          _image = null;
          _pendingMessageId = null;
        });
      ref.invalidate(driverChatMessagesProvider(widget.chatId));
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _pendingMessageId != null
                  ? '${isArabic(context) ? 'حُفظ النص، تعذر رفع الصورة. أعد الإرسال لإعادة رفعها.' : 'Text was saved. Retry to upload the photo.'} $error'
                  : '$error',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    final messages = ref.watch(driverChatMessagesProvider(widget.chatId));
    return Scaffold(
      appBar: AppBar(
        title: Text(ar ? 'المحادثة' : 'Conversation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.invalidate(driverChatMessagesProvider(widget.chatId)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorState(
                error: error,
                onRetry: () =>
                    ref.invalidate(driverChatMessagesProvider(widget.chatId)),
              ),
              data: (rows) => ListView.builder(
                padding: const EdgeInsets.all(16),
                reverse: true,
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final row = rows[rows.length - 1 - index];
                  if (row is! Map) return const SizedBox.shrink();
                  return Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${row['senderName'] ?? ''}',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            Text(row['body']?.toString() ?? ''),
                            if (row['attachmentUrl'] is String)
                              TextButton.icon(
                                onPressed: () => context.push(
                                  '/chat-attachment',
                                  extra: row['attachmentUrl'],
                                ),
                                icon: const Icon(Icons.photo_outlined),
                                label: Text(ar ? 'فتح الصورة' : 'Open photo'),
                              ),
                            Text(
                              '${row['createdAt'] ?? ''}',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (_image != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Image.file(File(_image!.path), width: 60, height: 60),
                  Expanded(child: Text(_image!.name)),
                  if (_pendingMessageId == null)
                    IconButton(
                      onPressed: _sending
                          ? null
                          : () => setState(() => _image = null),
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _sending || _pendingMessageId != null
                        ? null
                        : _pick,
                    icon: const Icon(Icons.attach_file),
                  ),
                  Expanded(
                    child: TextField(
                      enabled: !_sending && _pendingMessageId == null,
                      controller: _message,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: ar ? 'رسالتك' : 'Message',
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
