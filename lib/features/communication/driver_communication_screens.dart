import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mazraa_driver/core/network/driver_communication_api.dart';
import 'package:mazraa_driver/features/auth/auth_controller.dart';
import 'package:mazraa_driver/features/reference_journey/reference_assets.dart';

class DriverChatsScreen extends ConsumerStatefulWidget {
  const DriverChatsScreen({super.key});

  @override
  ConsumerState<DriverChatsScreen> createState() => _DriverChatsScreenState();
}

class _DriverChatsScreenState extends ConsumerState<DriverChatsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _chats = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await ref.read(driverCommunicationApiProvider).getChats();
      if (!mounted) return;
      setState(() {
        _chats = _maps(rows);
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المحادثات'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _Retry(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(18),
                    children: [
                      if (_chats.isEmpty)
                        const _Empty(
                          'لا توجد محادثات حالية. ستظهر محادثة العميل هنا عندما تكون مرتبطة بحسابك.',
                        ),
                      for (final chat in _chats) _chatTile(chat),
                    ],
                  ),
                ),
    );
  }

  Widget _chatTile(Map<String, dynamic> chat) {
    final id = _int(chat['id']);
    final other = _map(chat['otherUser']);
    final last = _map(chat['lastMessage']);
    final unread = _int(chat['unreadCount']);
    final isSupport = chat['isSupport'] == true;
    final name = isSupport
        ? 'الدعم'
        : '${other['name'] ?? 'محادثة العميل'}';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: id == 0 ? null : () => context.push('/chats/$id'),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: isSupport
              ? const Icon(Icons.support_agent_rounded)
              : ClipOval(
                  child: Image.asset(
                    ReferenceAssets.driverAvatar,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                ),
        ),
        title: Text(name),
        subtitle: Text(
          '${last['body'] ?? 'لا توجد رسائل بعد'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: unread > 0
            ? Badge(label: Text('$unread'))
            : const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class DriverChatThreadScreen extends ConsumerStatefulWidget {
  const DriverChatThreadScreen({required this.chatId, super.key});
  final int chatId;

  @override
  ConsumerState<DriverChatThreadScreen> createState() =>
      _DriverChatThreadScreenState();
}

class _DriverChatThreadScreenState
    extends ConsumerState<DriverChatThreadScreen> {
  final _message = TextEditingController();
  bool _loading = true;
  bool _sending = false;
  String? _error;
  Map<String, dynamic> _chat = {};
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(driverCommunicationApiProvider);
      final chat = await api.getChat(widget.chatId);
      final messages = await api.getChatMessages(widget.chatId);
      if (!mounted) return;
      setState(() {
        _chat = chat;
        _messages = _maps(messages);
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _send() async {
    final text = _message.text.trim();
    if (text.isEmpty || _sending || _chat['isClosed'] == true) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(driverCommunicationApiProvider)
          .sendChatMessage(widget.chatId, text);
      _message.clear();
      await _load();
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = ref.watch(authControllerProvider).profile?.userId;
    final customer = _map(_chat['customer']);
    final recipient = _map(_chat['recipient']);
    final other = customer['id'] == myId ? recipient : customer;
    final title = _chat['isSupport'] == true
        ? 'الدعم'
        : '${other['name'] ?? 'المحادثة'}';
    final closed = _chat['isClosed'] == true;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _Retry(message: _error!, onRetry: _load)
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final row = _messages[index];
                            final mine = _int(row['senderId']) == myId;
                            return Align(
                              alignment: mine
                                  ? AlignmentDirectional.centerEnd
                                  : AlignmentDirectional.centerStart,
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 300),
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: mine
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${row['body'] ?? ''}',
                                      style: TextStyle(
                                        color: mine ? Colors.white : null,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${row['createdAt'] ?? ''}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: mine
                                            ? Colors.white70
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _message,
                                enabled: !closed,
                                minLines: 1,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText: closed
                                      ? 'تم إغلاق المحادثة'
                                      : 'اكتب رسالة…',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: closed || _sending ? null : _send,
                              icon: _sending
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.send_rounded),
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

class DriverSupportCenterScreen extends ConsumerStatefulWidget {
  const DriverSupportCenterScreen({super.key});

  @override
  ConsumerState<DriverSupportCenterScreen> createState() =>
      _DriverSupportCenterScreenState();
}

class _DriverSupportCenterScreenState
    extends ConsumerState<DriverSupportCenterScreen> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  List<Map<String, dynamic>> _faqs = [];
  List<Map<String, dynamic>> _tickets = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(driverCommunicationApiProvider);
      final faqs = await api.getFaqs();
      final tickets = await api.getTickets();
      if (!mounted) return;
      setState(() {
        _faqs = _maps(faqs);
        _tickets = _maps(tickets);
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _createTicket() async {
    final draft = await _ticketDialog();
    if (draft == null) return;
    setState(() => _busy = true);
    try {
      final created = await ref
          .read(driverCommunicationApiProvider)
          .createTicket(
            subject: draft.subject,
            message: draft.message,
            priority: draft.priority,
          );
      await _load();
      if (!mounted) return;
      final id = _int(created['id']);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إنشاء التذكرة ${created['number'] ?? ''}.')),
      );
      if (id > 0) context.push('/support/tickets/$id');
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<_TicketDraft?> _ticketDialog() async {
    final subject = TextEditingController();
    final message = TextEditingController();
    var priority = 'normal';
    final result = await showDialog<_TicketDraft>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('تذكرة دعم جديدة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: subject,
                  maxLength: 200,
                  decoration: const InputDecoration(labelText: 'الموضوع'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: message,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: 4000,
                  decoration: const InputDecoration(labelText: 'شرح المشكلة'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: priority,
                  decoration: const InputDecoration(labelText: 'الأولوية'),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('منخفضة')),
                    DropdownMenuItem(value: 'normal', child: Text('عادية')),
                    DropdownMenuItem(value: 'high', child: Text('مرتفعة')),
                    DropdownMenuItem(value: 'urgent', child: Text('عاجلة')),
                  ],
                  onChanged: (value) =>
                      setLocal(() => priority = value ?? 'normal'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                if (subject.text.trim().isEmpty ||
                    message.text.trim().isEmpty) {
                  return;
                }
                Navigator.pop(
                  dialogContext,
                  _TicketDraft(
                    subject.text.trim(),
                    message.text.trim(),
                    priority,
                  ),
                );
              },
              child: const Text('إرسال'),
            ),
          ],
        ),
      ),
    );
    subject.dispose();
    message.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مركز الدعم'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _createTicket,
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('تذكرة جديدة'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _Retry(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
                    children: [
                      SizedBox(
                        height: 125,
                        child: Image.asset(
                          ReferenceAssets.supportHeadset,
                          fit: BoxFit.contain,
                          cacheWidth: 620,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'تذاكري',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      if (_tickets.isEmpty)
                        const _Empty('لا توجد تذاكر دعم حالية.'),
                      for (final ticket in _tickets) _ticketTile(ticket),
                      const SizedBox(height: 20),
                      Text(
                        'الأسئلة الشائعة',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      if (_faqs.isEmpty)
                        const _Empty('لا توجد أسئلة شائعة منشورة حاليًا.'),
                      for (final faq in _faqs)
                        Card(
                          child: ExpansionTile(
                            title: Text('${faq['question'] ?? ''}'),
                            subtitle: faq['category'] == null
                                ? null
                                : Text('${faq['category']}'),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Text('${faq['answer'] ?? ''}'),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _ticketTile(Map<String, dynamic> ticket) {
    final id = _int(ticket['id']);
    return Card(
      child: ListTile(
        onTap: id == 0 ? null : () => context.push('/support/tickets/$id'),
        leading: const Icon(Icons.support_agent_rounded),
        title: Text('${ticket['subject'] ?? ticket['number'] ?? 'تذكرة'}'),
        subtitle: Text(
          '${ticket['number'] ?? ''} · ${ticket['status'] ?? ''}\n'
          '${ticket['lastMessage'] ?? ''}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class SupportTicketThreadScreen extends ConsumerStatefulWidget {
  const SupportTicketThreadScreen({required this.ticketId, super.key});
  final int ticketId;

  @override
  ConsumerState<SupportTicketThreadScreen> createState() =>
      _SupportTicketThreadScreenState();
}

class _SupportTicketThreadScreenState
    extends ConsumerState<SupportTicketThreadScreen> {
  final _reply = TextEditingController();
  bool _loading = true;
  bool _busy = false;
  String? _error;
  Map<String, dynamic> _ticket = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final ticket = await ref
          .read(driverCommunicationApiProvider)
          .getTicket(widget.ticketId);
      if (!mounted) return;
      setState(() {
        _ticket = ticket;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _send() async {
    final text = _reply.text.trim();
    if (text.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(driverCommunicationApiProvider)
          .replyTicket(widget.ticketId, text);
      _reply.clear();
      await _load();
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _close() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(driverCommunicationApiProvider)
          .closeTicket(widget.ticketId);
      await _load();
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = _maps(_ticket['messages'] as List<dynamic>? ?? const []);
    final closed = '${_ticket['status'] ?? ''}'.toLowerCase() == 'closed';
    final myId = ref.watch(authControllerProvider).profile?.userId;
    return Scaffold(
      appBar: AppBar(
        title: Text('${_ticket['number'] ?? 'التذكرة'}'),
        actions: [
          if (!closed)
            IconButton(
              tooltip: 'إغلاق التذكرة',
              onPressed: _busy ? null : _close,
              icon: const Icon(Icons.check_circle_outline_rounded),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _Retry(message: _error!, onRetry: _load)
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_ticket['subject'] ?? ''}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            'الحالة: ${_ticket['status'] ?? ''} · الأولوية: ${_ticket['priority'] ?? ''}',
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final row = messages[index];
                          final mine = _int(row['senderId']) == myId;
                          return Align(
                            alignment: mine
                                ? AlignmentDirectional.centerEnd
                                : AlignmentDirectional.centerStart,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 300),
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: mine
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                '${row['body'] ?? ''}',
                                style: TextStyle(
                                  color: mine ? Colors.white : null,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _reply,
                                enabled: !closed,
                                minLines: 1,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText: closed
                                      ? 'التذكرة مغلقة'
                                      : 'أضف ردًا…',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: closed || _busy ? null : _send,
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

class _TicketDraft {
  const _TicketDraft(this.subject, this.message, this.priority);
  final String subject;
  final String message;
  final String priority;
}

class _Retry extends StatelessWidget {
  const _Retry({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 44),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
}

class _Empty extends StatelessWidget {
  const _Empty(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(Icons.inbox_outlined),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry('$key', value));
  return const {};
}

List<Map<String, dynamic>> _maps(List<dynamic> values) =>
    values.map(_map).where((item) => item.isNotEmpty).toList();

int _int(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

void _showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(error.toString())),
  );
}
