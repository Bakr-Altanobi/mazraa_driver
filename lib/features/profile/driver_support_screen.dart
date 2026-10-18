import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazraa_driver/core/network/providers.dart';

final driverSupportFaqsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) async {
    final data = await ref.watch(driverApiProvider).getSupportFaqs();
    return data.whereType<Map<String, dynamic>>().toList(growable: false);
  },
);

final driverSupportTicketsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) async {
    final data = await ref.watch(driverApiProvider).getSupportTickets();
    return data.whereType<Map<String, dynamic>>().toList(growable: false);
  },
);

/// Uses the real support/tickets and support/faqs endpoints; never promises
/// that a support representative has responded until the backend says so.
class DriverSupportScreen extends ConsumerStatefulWidget {
  const DriverSupportScreen({super.key});

  @override
  ConsumerState<DriverSupportScreen> createState() => _DriverSupportScreenState();
}

class _DriverSupportScreenState extends ConsumerState<DriverSupportScreen> {
  bool _busy = false;

  Future<void> _createTicket() async {
    final subject = TextEditingController();
    final message = TextEditingController();
    var priority = 'normal';
    try {
      final key = GlobalKey<FormState>();
      final send = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, redraw) => AlertDialog(
            title: const Text('تذكرة دعم جديدة'),
            content: SingleChildScrollView(
              child: Form(
                key: key,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: subject,
                      maxLength: 200,
                      decoration: const InputDecoration(labelText: 'موضوع التذكرة'),
                      validator: (v) => v?.trim().isNotEmpty == true
                          ? null : 'موضوع التذكرة مطلوب',
                    ),
                    TextFormField(
                      controller: message,
                      minLines: 3,
                      maxLines: 6,
                      maxLength: 4000,
                      decoration: const InputDecoration(labelText: 'تفاصيل المشكلة'),
                      validator: (v) => v?.trim().isNotEmpty == true
                          ? null : 'تفاصيل المشكلة مطلوبة',
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: priority,
                      decoration: const InputDecoration(labelText: 'الأولوية'),
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('منخفضة')),
                        DropdownMenuItem(value: 'normal', child: Text('عادية')),
                        DropdownMenuItem(value: 'high', child: Text('مرتفعة')),
                        DropdownMenuItem(value: 'urgent', child: Text('عاجلة')),
                      ],
                      onChanged: (v) => redraw(() => priority = v ?? priority),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () {
                  if (key.currentState?.validate() == true) {
                    Navigator.pop(ctx, true);
                  }
                },
                child: const Text('إرسال للسيرفر'),
              ),
            ],
          ),
        ),
      );
      if (send != true || !mounted) return;
      setState(() => _busy = true);
      try {
        await ref.read(driverApiProvider).createSupportTicket(
          subject: subject.text,
          message: message.text,
          priority: priority,
        );
        ref.invalidate(driverSupportTicketsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إنشاء تذكرة دعم في السيرفر.')),
          );
        }
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      subject.dispose();
      message.dispose();
    }
  }

  Future<void> _openTicket(int ticketId) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final api = ref.read(driverApiProvider);
      final ticket = await api.getSupportTicket(ticketId);
      if (!mounted) return;
      final messages = (ticket['messages'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      final isClosed = ticket['status']?.toString().toLowerCase() == 'closed';
      final reply = TextEditingController();
      try {
        final submitted = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('${ticket['subject'] ?? 'تذكرة #$ticketId'}'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final row in messages)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(row['senderName']?.toString() ?? ''),
                              const SizedBox(height: 4),
                              Text(row['body']?.toString() ?? ''),
                              const SizedBox(height: 4),
                              Text(row['createdAt']?.toString() ?? '',
                                  style: Theme.of(ctx).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ),
                    if (isClosed)
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('التذكرة مغلقة؛ لا يمكن الرد عليها.'),
                      )
                    else
                      TextField(
                        key: const Key('supportReplyField'),
                        controller: reply,
                        minLines: 2,
                        maxLines: 5,
                        maxLength: 4000,
                        decoration: const InputDecoration(labelText: 'رد جديد'),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إغلاق'),
              ),
              if (!isClosed)
                FilledButton(
                  onPressed: () {
                    final value = reply.text.trim();
                    if (value.isNotEmpty) Navigator.pop(ctx, value);
                  },
                  child: const Text('إرسال الرد'),
                ),
            ],
          ),
        );
        if (submitted == null || !mounted) return;
        await api.replySupportTicket(ticketId, submitted);
        ref.invalidate(driverSupportTicketsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إرسال الرد إلى السيرفر.')),
          );
        }
      } finally {
        reply.dispose();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final faqs = ref.watch(driverSupportFaqsProvider);
    final tickets = ref.watch(driverSupportTicketsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('المساعدة والدعم'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: () {
              ref.invalidate(driverSupportFaqsProvider);
              ref.invalidate(driverSupportTicketsProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _createTicket,
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('تذكرة جديدة'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          Text('تذاكر الدعم', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          tickets.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ListTile(
              title: const Text('تعذر تحميل التذاكر'),
              subtitle: Text(error.toString()),
              onTap: () => ref.invalidate(driverSupportTicketsProvider),
            ),
            data: (rows) => rows.isEmpty
                ? const ListTile(title: Text('لا توجد تذاكر دعم في الحساب.'))
                : Column(
                    children: [
                      for (final row in rows)
                        ListTile(
                          key: Key('supportTicket${row['id']}'),
                          leading: const Icon(Icons.support_agent_rounded),
                          title: Text(row['subject']?.toString() ?? ''),
                          subtitle: Text(
                            '${row['number'] ?? ''} · ${row['status'] ?? ''}\n'
                            '${row['lastMessage'] ?? ''}',
                            maxLines: 3,
                          ),
                          trailing: const Icon(Icons.chevron_left_rounded),
                          onTap: () {
                            final id = int.tryParse('${row['id'] ?? ''}');
                            if (id != null && id > 0) _openTicket(id);
                          },
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 24),
          Text('الأسئلة الشائعة', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          faqs.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ListTile(
              title: const Text('تعذر تحميل الأسئلة الشائعة'),
              subtitle: Text(error.toString()),
              onTap: () => ref.invalidate(driverSupportFaqsProvider),
            ),
            data: (rows) => rows.isEmpty
                ? const ListTile(title: Text('لم ينشر السيرفر أسئلة شائعة بعد.'))
                : Column(
                    children: [
                      for (final row in rows)
                        ExpansionTile(
                          title: Text(row['question']?.toString() ?? ''),
                          childrenPadding: const EdgeInsets.all(16),
                          children: [Text(row['answer']?.toString() ?? '')],
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: ListTile(
              leading: Icon(Icons.shield_outlined),
              title: Text('السلامة أولًا'),
              subtitle: Text('توقف في مكان آمن قبل تشغيل التطبيق أو إرسال بلاغ.'),
            ),
          ),
        ],
      ),
    );
  }
}
