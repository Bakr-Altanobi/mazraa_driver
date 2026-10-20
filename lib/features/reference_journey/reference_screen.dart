import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mazraa_driver/features/auth/auth_controller.dart';
import 'package:mazraa_driver/features/reference_journey/reference_catalog.dart';
import 'package:mazraa_driver/features/reference_journey/reference_production_body.dart';
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
    final sessionReady = userId != null;
    final key = userId == null
        ? null
        : ReferenceLoadKey(widget.screenNumber, userId);
    final asyncPayload = key == null
        ? null
        : ref.watch(referenceScreenPayloadProvider(key));

    return Scaffold(
      key: Key('referenceScreen${widget.screenNumber}'),
      appBar: AppBar(
        title: Text(
          '${widget.screenNumber.toString().padLeft(2, '0')} · ${spec.titleAr}',
        ),
        actions: [
          if (auth.isAuthenticated)
            IconButton(
              tooltip: 'الرئيسية',
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.home_outlined),
            ),
        ],
      ),
      body: ReferenceProductionBody(
        spec: spec,
        payload: asyncPayload?.valueOrNull,
        loading: asyncPayload?.isLoading ?? false,
        sessionReady: sessionReady,
        actionBusy: _actionBusy,
        onAction: (action) => _runAction(action, key),
        onPrevious: widget.screenNumber > 1
            ? () => context.go(_route(widget.screenNumber - 1))
            : null,
        onNext: widget.screenNumber < 48
            ? () => _goNext(context, auth)
            : () => context.go('/home'),
      ),
    );
  }

  void _goNext(BuildContext context, AuthController auth) {
    if (widget.screenNumber == 1) {
      context.go('/login');
      return;
    }
    if (widget.screenNumber == 2 && !auth.isAuthenticated) {
      context.go('/login');
      return;
    }
    context.go(_route(widget.screenNumber + 1));
  }

  String _route(int number) =>
      '/journey/${number.toString().padLeft(2, '0')}';

  Future<void> _runAction(
    ReferenceAction action,
    ReferenceLoadKey? key,
  ) async {
    if (_actionBusy) return;

    int? targetId;
    String? targetLabel;
    if (referenceActionNeedsTarget(action)) {
      try {
        final options = await ref.read(referenceRepositoryProvider)
            .targetsForAction(action);
        if (!mounted) return;
        if (options.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لا توجد مهمة مؤهلة لهذا الإجراء في بيانات السيرفر الحالية.')),
          );
          return;
        }
        final selected = await showDialog<ReferenceActionTarget>(
          context: context,
          builder: (dialogContext) => SimpleDialog(
            title: const Text('حدد المهمة المقصودة'),
            children: [
              for (final option in options)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(dialogContext, option),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(option.label),
                  ),
                ),
            ],
          ),
        );
        if (!mounted || selected == null) return;
        targetId = selected.id;
        targetLabel = selected.label;
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تعذر تحميل الخيارات: $error')),
          );
        }
        return;
      }
    }

    Map<String, dynamic>? fields;
    if (action == ReferenceAction.addPickupProof ||
        action == ReferenceAction.addDeliveryProof ||
        action == ReferenceAction.saveBankAccount ||
        action == ReferenceAction.requestPayout ||
        action == ReferenceAction.addAvailabilityWindow ||
        action == ReferenceAction.sendChatMessage ||
        action == ReferenceAction.createSupportTicket ||
        action == ReferenceAction.replySupportTicket) {
      fields = await _fieldsDialog(action);
      if (!mounted || fields == null) return;
    }

    String? reason;
    String? subject;
    String? message;
    if (action == ReferenceAction.failShipment) {
      reason = await _textDialog(
        title: 'سبب تعذر التسليم',
        label: 'السبب الذي سيُرسل إلى السيرفر',
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
              content: Text(
                targetLabel == null
                  ? 'سيتم إرسال العملية إلى السيرفر الحقيقي بعد التأكيد.'
                  : 'ستنفذ هذه العملية على $targetLabel فقط. هل تؤكد؟',
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
        await repository.runShipmentAction(action, targetId: targetId, reason: reason, fields: fields);
      }
      if (key != null) {
        // A mutation may affect more than its current screen: online status,
        // offers, shipments, payouts and shift summaries share server data.
        for (final screen in ReferenceCatalog.screens) {
          ref.invalidate(referenceScreenPayloadProvider(
            ReferenceLoadKey(screen.number, key.userId),
          ));
        }
      }
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

  Future<Map<String, dynamic>?> _fieldsDialog(ReferenceAction action) async {
    final inputs = switch (action) {
      ReferenceAction.saveBankAccount => const <String, String>{
          'bankName': 'اسم البنك',
          'accountHolderName': 'اسم صاحب الحساب',
          'iban': 'رقم IBAN',
          'accountNumber': 'رقم الحساب (اختياري)',
        },
      ReferenceAction.requestPayout => const <String, String>{
          'amount': 'مبلغ السحب بالعملة المسجلة في المحفظة',
        },
      ReferenceAction.addPickupProof => const <String, String>{
          'verificationReference': 'رقم التحقق عند الاستلام',
          'notes': 'ملاحظات (اختياري)',
        },
      ReferenceAction.sendChatMessage ||
      ReferenceAction.replySupportTicket => const <String, String>{
          'message': 'نص الرسالة',
        },
      ReferenceAction.createSupportTicket => const <String, String>{
          'subject': 'عنوان التذكرة',
          'message': 'تفاصيل طلب الدعم',
        },
      ReferenceAction.addAvailabilityWindow => const <String, String>{
          'dayOfWeek': 'يوم الأسبوع (0 الأحد إلى 6 السبت)',
          'startTime': 'وقت البداية HH:mm',
          'endTime': 'وقت النهاية HH:mm',
        },
      ReferenceAction.addDeliveryProof => const <String, String>{
          'recipientName': 'اسم المستلم',
          'verificationReference': 'رمز/مرجع التحقق (اختياري)',
          'notes': 'ملاحظات (اختياري)',
        },
      _ => const <String, String>{},
    };
    final controllers = {
      for (final key in inputs.keys) key: TextEditingController(),
    };
    try {
      return await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(_actionTitle(action)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final field in inputs.entries) ...[
                  TextField(
                    controller: controllers[field.key],
                    keyboardType: field.key == 'amount'
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.text,
                    textDirection: field.key == 'iban' || field.key == 'amount'
                        ? TextDirection.ltr
                        : null,
                    decoration: InputDecoration(labelText: field.value),
                  ),
                  const SizedBox(height: 8),
                ],
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
                final data = {
                  for (final field in controllers.entries)
                    field.key: field.value.text.trim(),
                };
                final required = switch (action) {
                  ReferenceAction.saveBankAccount =>
                    const ['bankName', 'accountHolderName', 'iban'],
                  ReferenceAction.requestPayout => const ['amount'],
                  ReferenceAction.addPickupProof =>
                    const ['verificationReference'],
                  ReferenceAction.addDeliveryProof => const ['recipientName'],
                  ReferenceAction.addAvailabilityWindow => const ['dayOfWeek', 'startTime', 'endTime'],
                  ReferenceAction.createSupportTicket => const ['subject', 'message'],
                  ReferenceAction.sendChatMessage ||
                  ReferenceAction.replySupportTicket => const ['message'],
                  _ => const <String>[],
                };
                if (required.any((key) => (data[key] ?? '').isEmpty)) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('أكمل الحقول المطلوبة أولًا.')),
                  );
                  return;
                }
                Navigator.pop(dialogContext, data);
              },
              child: const Text('التالي'),
            ),
          ],
        ),
      );
    } finally {
      for (final controller in controllers.values) {
        controller.dispose();
      }
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
        title: const Text('رفع بلاغ إلى السيرفر'),
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

String _actionTitle(ReferenceAction action) => switch (action) {
      ReferenceAction.acceptShipment => 'قبول الشحنة',
      ReferenceAction.pickupShipment => 'تأكيد استلام الشحنة',
      ReferenceAction.startTransit => 'بدء التوجه للعميل',
      ReferenceAction.nearCustomer => 'تأكيد الوصول قرب العميل',
      ReferenceAction.deliverShipment => 'تأكيد تسليم الشحنة',
      ReferenceAction.failShipment => 'تسجيل تعذر التسليم',
      ReferenceAction.startShift => 'بدء الوردية',
      ReferenceAction.endShift => 'إنهاء الوردية',
      ReferenceAction.acceptOffer => 'قبول عرض التوصيل',
      ReferenceAction.rejectOffer => 'رفض عرض التوصيل',
      ReferenceAction.createIncident => 'رفع بلاغ',
      ReferenceAction.goOnline => 'تفعيل استقبال الطلبات',
      ReferenceAction.goOffline => 'إيقاف استقبال الطلبات',
      ReferenceAction.joinScheduledTrip => 'طلب الانضمام لرحلة مجدولة',
      ReferenceAction.withdrawScheduledTrip => 'سحب طلب الانضمام',
      ReferenceAction.acceptReturn => 'قبول مهمة المرتجع',
      ReferenceAction.pickupReturn => 'استلام المرتجع',
      ReferenceAction.completeReturn => 'تسليم المرتجع للمتجر',
      ReferenceAction.addPickupProof => 'تسجيل مرجع إثبات الاستلام',
      ReferenceAction.addDeliveryProof => 'تسجيل إثبات التسليم',
      ReferenceAction.saveBankAccount => 'حفظ الحساب البنكي',
      ReferenceAction.requestPayout => 'طلب سحب الرصيد',
      ReferenceAction.markAllNotificationsRead => 'تحديد كل الإشعارات كمقروءة',
      ReferenceAction.toggleOffersPreference => 'تبديل استقبال عروض التوصيل',
      ReferenceAction.toggleScheduledTripsPreference => 'تبديل الرحلات المجدولة',
      ReferenceAction.addAvailabilityWindow => 'إضافة فترة توفر أسبوعية',
      ReferenceAction.removeAvailabilityWindow => 'حذف فترة التوفر المحددة',
      ReferenceAction.sendChatMessage => 'إرسال رسالة في المحادثة',
      ReferenceAction.createSupportTicket => 'فتح تذكرة دعم',
      ReferenceAction.replySupportTicket => 'الرد على تذكرة دعم',
      ReferenceAction.startSupportChat => 'بدء محادثة مع الدعم',
    };
