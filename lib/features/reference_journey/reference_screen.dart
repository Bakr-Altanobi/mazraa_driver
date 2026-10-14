import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mazraa_driver/core/theme/app_theme.dart';
import 'package:mazraa_driver/features/auth/auth_controller.dart';
import 'package:mazraa_driver/features/reference_journey/reference_assets.dart';
import 'package:mazraa_driver/features/reference_journey/reference_catalog.dart';
import 'package:mazraa_driver/features/reference_journey/reference_repository.dart';

class ReferenceJourneyScreen extends ConsumerStatefulWidget {
  const ReferenceJourneyScreen({required this.screenNumber, super.key});

  final int screenNumber;

  @override
  ConsumerState<ReferenceJourneyScreen> createState() =>
      _ReferenceJourneyScreenState();
}

class _ReferenceJourneyScreenState
    extends ConsumerState<ReferenceJourneyScreen> {
  bool _actionBusy = false;

  ReferenceScreenSpec get spec =>
      ReferenceCatalog.screen(widget.screenNumber);

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final userId = auth.profile?.userId;
    final key = userId == null
        ? null
        : ReferenceLoadKey(widget.screenNumber, userId);
    final payload = key == null
        ? const AsyncValue<ReferenceScreenPayload>.loading()
        : ref.watch(referenceScreenPayloadProvider(key));

    return Scaffold(
      key: Key('referenceScreen${widget.screenNumber}'),
      appBar: AppBar(
        title: Text(
          '${widget.screenNumber.toString().padLeft(2, '0')} · ${spec.titleAr}',
        ),
        actions: [
          IconButton(
            tooltip: 'لوحة السائق',
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.home_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (key != null) {
            ref.invalidate(referenceScreenPayloadProvider(key));
            await ref.read(referenceScreenPayloadProvider(key).future);
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
          children: [
            _ScreenHeading(spec: spec),
            const SizedBox(height: 16),
            _AssetGallery(assets: spec.assets),
            const SizedBox(height: 18),
            _CoverageHeader(spec: spec),
            const SizedBox(height: 10),
            if (spec.sources.isEmpty)
              const _InfoCard(
                icon: Icons.devices_rounded,
                title: 'لا تتطلب بيانات ديناميكية',
                body:
                    'هذه شاشة تقديم/هوية. لا يتم اختلاق بيانات سيرفر لها، بينما الأصول مأخوذة مباشرة من مرجع التصميم.',
              )
            else if (userId == null)
              const _InfoCard(
                icon: Icons.lock_outline_rounded,
                title: 'الجلسة غير جاهزة',
                body: 'يجب تسجيل الدخول بحساب سائق فعلي قبل تحميل هذه الشاشة.',
                error: true,
              )
            else
              payload.when(
                loading: () => const _LoadingServerData(),
                error: (error, _) => _InfoCard(
                  icon: Icons.cloud_off_rounded,
                  title: 'تعذر تحميل بيانات السيرفر',
                  body: error.toString(),
                  error: true,
                ),
                data: (data) => _ServerData(results: data.results),
              ),
            if (spec.actions.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                'عمليات مدعومة فعلياً',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              for (final action in spec.actions) ...[
                _ActionButton(
                  action: action,
                  busy: _actionBusy,
                  onPressed: () => _runAction(action, key),
                ),
                const SizedBox(height: 8),
              ],
            ],
            if (spec.unsupported.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                'مطلوب من السيرفر لاحقاً',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              for (final item in spec.unsupported) ...[
                _UnsupportedCard(text: item),
                const SizedBox(height: 8),
              ],
            ],
            const SizedBox(height: 22),
            _JourneyNavigation(number: widget.screenNumber),
          ],
        ),
      ),
    );
  }

  Future<void> _runAction(
    ReferenceAction action,
    ReferenceLoadKey? key,
  ) async {
    if (_actionBusy) return;
    String? reason;
    String? subject;
    String? message;

    if (action == ReferenceAction.failShipment) {
      reason = await _textDialog(
        title: 'سبب تعذر الوصول للعميل',
        label: 'السبب',
        initialValue: 'تعذر الوصول للعميل',
      );
      if (reason == null) return;
    } else if (action == ReferenceAction.createIncident) {
      final incident = await _incidentDialog();
      if (incident == null) return;
      subject = incident.$1;
      message = incident.$2;
    } else {
      final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text(_actionTitle(action)),
              content: const Text(
                'سيتم تنفيذ العملية على الشحنة الحقيقية الأولى المتاحة في حساب السائق، وسيطبق السيرفر قواعد انتقال الحالة.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('تنفيذ'),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirmed) return;
    }

    setState(() => _actionBusy = true);
    try {
      final repository = ref.read(referenceRepositoryProvider);
      if (action == ReferenceAction.createIncident) {
        await repository.createIncident(
          subject: subject!,
          message: message!,
        );
      } else {
        await repository.runShipmentAction(action, reason: reason);
      }
      if (key != null) ref.invalidate(referenceScreenPayloadProvider(key));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت العملية على السيرفر بنجاح.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  Future<String?> _textDialog({
    required String title,
    required String label,
    String initialValue = '',
  }) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<(String, String)?> _incidentDialog() async {
    final subject = TextEditingController();
    final message = TextEditingController();
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('رفع بلاغ للسيرفر'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: subject,
              decoration: const InputDecoration(labelText: 'عنوان البلاغ'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: message,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'تفاصيل البلاغ'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final a = subject.text.trim();
              final b = message.text.trim();
              if (a.isNotEmpty && b.isNotEmpty) {
                Navigator.pop(dialogContext, (a, b));
              }
            },
            child: const Text('رفع البلاغ'),
          ),
        ],
      ),
    );
    subject.dispose();
    message.dispose();
    return result;
  }
}

class _ScreenHeading extends StatelessWidget {
  const _ScreenHeading({required this.spec});

  final ReferenceScreenSpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [Color(0xFFFFFCF5), Color(0xFFF2E9D7)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            spec.titleAr,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: MazraaColors.forest,
                ),
          ),
          const SizedBox(height: 3),
          Text(
            spec.titleEn,
            textDirection: TextDirection.ltr,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: MazraaColors.leaf,
                ),
          ),
          const SizedBox(height: 9),
          Text(spec.descriptionAr),
        ],
      ),
    );
  }
}

class _AssetGallery extends StatelessWidget {
  const _AssetGallery({required this.assets});

  final List<ReferenceAssetSlot> assets;

  @override
  Widget build(BuildContext context) {
    if (assets.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('أصول الشاشة من ASSET_INDEX',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            SizedBox(
              height: 190,
              width: double.infinity,
              child: Image.asset(
                assets.first.path,
                fit: BoxFit.contain,
                cacheWidth: 720,
                errorBuilder: (_, error, __) => Center(
                  child: Text('تعذر تحميل ${assets.first.name}: $error'),
                ),
              ),
            ),
            Text(
              assets.first.name,
              textDirection: TextDirection.ltr,
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: assets.length - 1,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.25,
              ),
              itemBuilder: (context, index) {
                final asset = assets[index + 1];
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Image.asset(
                          asset.path,
                          fit: BoxFit.contain,
                          cacheWidth: 420,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        asset.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.ltr,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverageHeader extends StatelessWidget {
  const _CoverageHeader({required this.spec});

  final ReferenceScreenSpec spec;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.cloud_done_outlined, color: MazraaColors.success),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'بيانات حقيقية من السيرفر',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Text('${spec.sources.length} مصدر'),
      ],
    );
  }
}

class _LoadingServerData extends StatelessWidget {
  const _LoadingServerData();

  @override
  Widget build(BuildContext context) => const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
}

class _ServerData extends StatelessWidget {
  const _ServerData({required this.results});

  final List<ReferenceSourceResult> results;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final result in results) ...[
          _ServerSourceCard(result: result),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ServerSourceCard extends StatelessWidget {
  const _ServerSourceCard({required this.result});

  final ReferenceSourceResult result;

  @override
  Widget build(BuildContext context) {
    final rows = _flatten(result.payload);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  result.succeeded
                      ? Icons.cloud_done_rounded
                      : Icons.cloud_off_rounded,
                  color: result.succeeded
                      ? MazraaColors.success
                      : Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _sourceTitle(result.source),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        result.endpoint,
                        textDirection: TextDirection.ltr,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (result.error != null) ...[
              const SizedBox(height: 10),
              Text(
                result.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ] else if (result.emptyMessage != null) ...[
              const SizedBox(height: 10),
              Text(result.emptyMessage!),
            ] else if (rows.isEmpty) ...[
              const SizedBox(height: 10),
              const Text('استجابة السيرفر فارغة.'),
            ] else ...[
              const SizedBox(height: 12),
              for (final row in rows.take(60))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          row.$1,
                          textDirection: TextDirection.ltr,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 5,
                        child: SelectableText(
                          row.$2,
                          textDirection: _looksArabic(row.$2)
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                        ),
                      ),
                    ],
                  ),
                ),
              if (rows.length > 60)
                Text('يتم عرض أول 60 قيمة من ${rows.length} قيمة حقيقية.'),
            ],
          ],
        ),
      ),
    );
  }
}

class _UnsupportedCard extends StatelessWidget {
  const _UnsupportedCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MazraaColors.warning.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MazraaColors.warning.withValues(alpha: .45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.construction_rounded, color: MazraaColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'السيرفر لا يدعم هذا الجزء حالياً',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 3),
                Text(text),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
    this.error = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool error;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: error
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(body),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.action,
    required this.busy,
    required this.onPressed,
  });

  final ReferenceAction action;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
        onPressed: busy ? null : onPressed,
        icon: busy
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(_actionIcon(action)),
        label: Text(_actionTitle(action)),
      );
}

class _JourneyNavigation extends StatelessWidget {
  const _JourneyNavigation({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: number <= 1
                ? null
                : () => context.go(
                      '/journey/${(number - 1).toString().padLeft(2, '0')}',
                    ),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('السابق'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: number >= 48
                ? () => context.go('/home')
                : () => context.go(
                      '/journey/${(number + 1).toString().padLeft(2, '0')}',
                    ),
            icon: Icon(
              number >= 48 ? Icons.home_rounded : Icons.arrow_forward_rounded,
            ),
            label: Text(number >= 48 ? 'إنهاء' : 'التالي'),
          ),
        ),
      ],
    );
  }
}

List<(String, String)> _flatten(Object? value, [String prefix = '']) {
  final rows = <(String, String)>[];

  void visit(Object? node, String path, int depth) {
    if (rows.length >= 120) return;
    if (depth > 6) {
      rows.add((path, node.toString()));
      return;
    }
    if (node is Map) {
      if (node.isEmpty) {
        rows.add((path.isEmpty ? 'object' : path, '{}'));
        return;
      }
      for (final entry in node.entries) {
        final next = path.isEmpty ? '${entry.key}' : '$path.${entry.key}';
        visit(entry.value, next, depth + 1);
      }
      return;
    }
    if (node is List) {
      rows.add((path.isEmpty ? 'items.count' : '$path.count', '${node.length}'));
      for (var i = 0; i < node.length && i < 12; i++) {
        visit(node[i], '$path[$i]', depth + 1);
      }
      return;
    }
    rows.add((path.isEmpty ? 'value' : path, node?.toString() ?? 'null'));
  }

  if (value != null) visit(value, prefix, 0);
  return rows;
}

String _sourceTitle(ReferenceDataSource source) => switch (source) {
      ReferenceDataSource.driver => 'ملف السائق',
      ReferenceDataSource.shipments => 'الشحنات',
      ReferenceDataSource.shipmentDetail => 'تفاصيل الشحنة',
      ReferenceDataSource.tracking => 'تتبع الشحنة',
      ReferenceDataSource.wallet => 'المحفظة',
      ReferenceDataSource.walletTransactions => 'معاملات المحفظة',
      ReferenceDataSource.notifications => 'الإشعارات',
      ReferenceDataSource.vehicle => 'المركبة الحالية',
      ReferenceDataSource.supportFaqs => 'الأسئلة الشائعة',
      ReferenceDataSource.supportTickets => 'تذاكر الدعم',
      ReferenceDataSource.chats => 'المحادثات',
      ReferenceDataSource.deliveryZones => 'مناطق التوصيل',
      ReferenceDataSource.returns => 'طلبات الإرجاع',
    };

String _actionTitle(ReferenceAction action) => switch (action) {
      ReferenceAction.pickupShipment => 'تأكيد استلام الشحنة',
      ReferenceAction.deliverShipment => 'تأكيد تسليم الشحنة',
      ReferenceAction.failShipment => 'تسجيل تعذر التسليم',
      ReferenceAction.createIncident => 'رفع بلاغ جديد',
    };

IconData _actionIcon(ReferenceAction action) => switch (action) {
      ReferenceAction.pickupShipment => Icons.inventory_2_outlined,
      ReferenceAction.deliverShipment => Icons.task_alt_rounded,
      ReferenceAction.failShipment => Icons.person_off_outlined,
      ReferenceAction.createIncident => Icons.report_gmailerrorred_rounded,
    };

bool _looksArabic(String value) => RegExp(r'[\u0600-\u06FF]').hasMatch(value);
