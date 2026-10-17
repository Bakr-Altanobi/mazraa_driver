import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mazraa_driver/features/auth/auth_controller.dart';
import 'package:mazraa_driver/features/reference_journey/reference_catalog.dart';
import 'package:mazraa_driver/features/reference_journey/reference_production_body.dart';
import 'package:mazraa_driver/features/reference_journey/reference_repository.dart';
import 'package:mazraa_driver/features/reference_journey/reference_driver_controls.dart';

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
      bottomNavigationBar: sessionReady &&
              const <int>{10, 12, 15, 16, 30, 39, 42}.contains(widget.screenNumber)
          ? DriverServiceControls(
              screenNumber: widget.screenNumber,
              onSaved: () {
                if (key != null) {
                  ref.invalidate(referenceScreenPayloadProvider(key));
                }
              },
            )
          : null,
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
              content: const Text(
                'سيتم تنفيذ العملية فقط على بيانات حقيقية مؤهلة حسب قواعد السيرفر. إذا لم توجد شحنة أو وردية أو عرض مؤهل فلن يتم إرسال تعديل غير صالح.',
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
      int? selectedTargetId;
      final needsTarget = action != ReferenceAction.createIncident &&
          action != ReferenceAction.startShift &&
          action != ReferenceAction.endShift;
      if (needsTarget) {
        final targets = await repository.eligibleActionTargets(action);
        if (!mounted) return;
        if (targets.isEmpty) {
          throw StateError('لا توجد عناصر حقيقية في حالة تسمح بهذا الإجراء الآن.');
        }
        selectedTargetId = await _selectActionTarget(action, targets);
        if (selectedTargetId == null || !mounted) return;
      }
      String? numericCode;
      String? qrToken;
      if (action == ReferenceAction.deliverShipment) {
        final proof = await _deliveryProofDialog();
        if (proof == null || !mounted) return;
        numericCode = proof.$1;
        qrToken = proof.$2;
      }
      if (action == ReferenceAction.createIncident) {
        await repository.createIncident(
          subject: subject!,
          message: message!,
        );
      } else {
        final isOffer = action == ReferenceAction.acceptOffer ||
            action == ReferenceAction.rejectOffer;
        await repository.runShipmentAction(
          action,
          reason: reason,
          shipmentId: isOffer ? null : selectedTargetId,
          offerId: isOffer ? selectedTargetId : null,
          numericCode: numericCode,
          qrToken: qrToken,
        );
      }
      if (key != null) {
        ref.invalidate(referenceScreenPayloadProvider(key));
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

  Future<int?> _selectActionTarget(
    ReferenceAction action,
    List<Map<String, dynamic>> targets,
  ) {
    final isOffer = action == ReferenceAction.acceptOffer ||
        action == ReferenceAction.rejectOffer;
    return showDialog<int>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(isOffer ? 'اختر عرض التوصيل' : 'اختر الشحنة المطلوبة'),
        children: [
          for (final row in targets)
            Builder(
              builder: (dialogContext) {
                final id = int.tryParse(
                  '${isOffer ? (row['offerId'] ?? row['id']) : row['id']}',
                );
                if (id == null) return const SizedBox.shrink();
                final number = row['shipmentNumber']?.toString() ?? '#$id';
                return SimpleDialogOption(
                  onPressed: () => Navigator.pop(dialogContext, id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text('$number · ${isOffer ? 'عرض' : 'شحنة'} #$id'),
                  ),
                );
              },
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  /// Delivery proof is provided by the recipient and verified by the server.
  /// Standard handoffs may omit it; contactless handoffs cannot be completed
  /// without a valid code or QR token returned to the customer by the backend.
  Future<(String?, String?)?> _deliveryProofDialog() async {
    final controller = TextEditingController();
    var useQr = false;
    try {
      return await showDialog<(String?, String?)>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, update) => AlertDialog(
            title: const Text('إثبات تسليم الشحنة'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'أدخل رمز الاستلام الذي أعطاه العميل. '
                    'للتسليم العادي فقط يمكنك ترك الحقل فارغًا؛ '
                    'السيرفر يرفض التسليم بدون إثبات عندما يكون الطلب بدون تلامس.',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('رمز رقمي'),
                        selected: !useQr,
                        onSelected: (_) => update(() {
                          useQr = false;
                          controller.clear();
                        }),
                      ),
                      ChoiceChip(
                        label: const Text('رمز QR'),
                        selected: useQr,
                        onSelected: (_) => update(() {
                          useQr = true;
                          controller.clear();
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('referenceDeliveryProofField'),
                    controller: controller,
                    textDirection: TextDirection.ltr,
                    keyboardType:
                        useQr ? TextInputType.text : TextInputType.number,
                    decoration: InputDecoration(
                      labelText: useQr ? 'الرمز الموجود في QR' : 'رمز الاستلام',
                    ),
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
                  final value = controller.text.trim();
                  Navigator.pop(
                    dialogContext,
                    (
                      useQr || value.isEmpty ? null : value,
                      useQr && value.isNotEmpty ? value : null,
                    ),
                  );
                },
                child: const Text('تأكيد التسليم'),
              ),
            ],
          ),
        ),
      );
    } finally {
      controller.dispose();
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
    };
