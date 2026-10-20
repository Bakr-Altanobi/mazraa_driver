import 'package:flutter/material.dart';
import 'package:mazraa_driver/shared/widgets/mazraa_widgets.dart';

List<Map<String, dynamic>> _items(Map<String, dynamic> manifest) =>
    (manifest['items'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
String _itemName(Map<String, dynamic> item) =>
    (item['productName'] ?? item['sku'] ?? '#${item['productVariantId']}')
        .toString();

class ShipmentManifestDialog extends StatelessWidget {
  const ShipmentManifestDialog({
    required this.manifest,
    this.confirmPickup = false,
    super.key,
  });
  final Map<String, dynamic> manifest;
  final bool confirmPickup;
  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    final delivery = manifest['delivery'] as Map<String, dynamic>? ?? const {};
    final payment = manifest['payment'] as Map<String, dynamic>? ?? const {};
    return AlertDialog(
      title: Text(ar ? 'منتجات الشحنة' : 'Shipment items'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in _items(manifest))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_itemName(item)),
                  subtitle: Text(
                    '${ar ? 'الكمية' : 'Quantity'}: ${item['quantity']}',
                  ),
                ),
              if (delivery['instructions'] != null)
                Text(delivery['instructions'].toString()),
              if (delivery['callBeforeArrival'] == true)
                Text(
                  ar
                      ? 'اتصل بالعميل قبل الوصول'
                      : 'Call the customer before arrival',
                ),
              if (delivery['contactless'] == true)
                Text(
                  ar
                      ? 'التسليم يتطلب رمز العميل'
                      : 'Customer delivery code required',
                ),
              if (payment['requiresCashCollection'] == true)
                Text(
                  '${ar ? 'التحصيل النقدي' : 'Cash collection'}: ${payment['cashCollectionAmount']} ${payment['currency'] ?? ''}',
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(ar ? 'إغلاق' : 'Close'),
        ),
        if (confirmPickup)
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              ar ? 'راجعت المنتجات واستلمتها' : 'Reviewed and received items',
            ),
          ),
      ],
    );
  }
}

class PickupChecklistDialog extends StatefulWidget {
  const PickupChecklistDialog({required this.manifest, super.key});
  final Map<String, dynamic> manifest;
  @override
  State<PickupChecklistDialog> createState() => _PickupChecklistDialogState();
}

class _PickupChecklistDialogState extends State<PickupChecklistDialog> {
  final _form = GlobalKey<FormState>();
  late final List<Map<String, dynamic>> _lines = _items(widget.manifest);
  late final List<TextEditingController> _received = List.generate(
    _lines.length,
    (_) => TextEditingController(),
  );
  late final List<TextEditingController> _damaged = List.generate(
    _lines.length,
    (_) => TextEditingController(text: '0'),
  );
  final _notes = TextEditingController();
  bool _confirmed = false;
  @override
  void dispose() {
    for (final c in [..._received, ..._damaged, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate() || !_confirmed || _lines.isEmpty)
      return;
    final rows = <Map<String, dynamic>>[];
    for (var i = 0; i < _lines.length; i++) {
      final expected = (_lines[i]['quantity'] as num).toInt();
      final received = int.parse(_received[i].text.trim());
      final damaged = int.parse(_damaged[i].text.trim());
      final missing = expected - received - damaged;
      if (missing < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic(context)
                  ? 'مجموع الكميات يتجاوز كمية الطلب'
                  : 'Quantities exceed the order quantity',
            ),
          ),
        );
        return;
      }
      if ((missing > 0 || damaged > 0) && _notes.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic(context)
                  ? 'اشرح النقص أو التلف في الملاحظات'
                  : 'Explain missing or damaged items in the notes',
            ),
          ),
        );
        return;
      }
      rows.add({
        'orderItemId': _lines[i]['orderItemId'],
        'receivedQuantity': received,
        'missingQuantity': missing,
        'damagedQuantity': damaged,
        'notes': null,
      });
    }
    Navigator.pop(context, {'lines': rows, 'notes': _notes.text.trim()});
  }

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    String? quantity(String? s) =>
        int.tryParse(s?.trim() ?? '') == null || int.parse(s!.trim()) < 0
        ? (ar ? 'أدخل عددًا صحيحًا' : 'Enter a whole number')
        : null;
    return AlertDialog(
      title: Text(ar ? 'فحص الاستلام من المخزن' : 'Warehouse pickup checklist'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ar
                      ? 'عدّ المنتجات فعليًا. الكمية الناقصة تُحسب من الفرق، ولا يمكن تعديل السجل بعد تأكيده.'
                      : 'Count the items received. Missing quantities are calculated from the difference. Confirmation is permanent.',
                ),
                for (var i = 0; i < _lines.length; i++) ...[
                  const SizedBox(height: 16),
                  Text(
                    '${_itemName(_lines[i])} • ${ar ? 'المطلوب' : 'Expected'}: ${_lines[i]['quantity']}',
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: ValueKey('received-$i'),
                          controller: _received[i],
                          keyboardType: TextInputType.number,
                          validator: quantity,
                          decoration: InputDecoration(
                            labelText: ar
                                ? 'المستلم السليم'
                                : 'Received intact',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          key: ValueKey('damaged-$i'),
                          controller: _damaged[i],
                          keyboardType: TextInputType.number,
                          validator: quantity,
                          decoration: InputDecoration(
                            labelText: ar ? 'التالف' : 'Damaged',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                TextFormField(
                  controller: _notes,
                  maxLength: 1000,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: ar
                        ? 'ملاحظات النقص أو التلف'
                        : 'Discrepancy notes',
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _confirmed,
                  onChanged: (v) => setState(() => _confirmed = v == true),
                  title: Text(
                    ar
                        ? 'أؤكد مطابقة الأعداد للفحص الفعلي'
                        : 'I confirm these counts match my inspection',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(ar ? 'إلغاء' : 'Cancel'),
        ),
        FilledButton(
          onPressed: _confirmed ? _submit : null,
          child: Text(ar ? 'تسجيل الفحص' : 'Record inspection'),
        ),
      ],
    );
  }
}

class DeliveryConfirmation {
  const DeliveryConfirmation({
    this.numericCode,
    this.cashConfirmed = false,
    this.cashAmount,
  });
  final String? numericCode;
  final bool cashConfirmed;
  final double? cashAmount;
}

class DeliveryConfirmationDialog extends StatefulWidget {
  const DeliveryConfirmationDialog({
    required this.manifest,
    required this.requestCode,
    super.key,
  });
  final Map<String, dynamic> manifest;
  final Future<void> Function() requestCode;
  @override
  State<DeliveryConfirmationDialog> createState() =>
      _DeliveryConfirmationDialogState();
}

class _DeliveryConfirmationDialogState
    extends State<DeliveryConfirmationDialog> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController(), _amount = TextEditingController();
  bool _cashConfirmed = false, _requesting = false;
  String? _message;
  @override
  void dispose() {
    _code.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    setState(() {
      _requesting = true;
      _message = null;
    });
    try {
      await widget.requestCode();
      if (mounted)
        setState(
          () => _message = isArabic(context)
              ? 'تم إرسال الرمز للعميل'
              : 'Code sent to the customer',
        );
    } catch (e) {
      if (mounted) setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    final payment =
        widget.manifest['payment'] as Map<String, dynamic>? ?? const {};
    final contactless =
        (widget.manifest['delivery']
            as Map<String, dynamic>?)?['contactless'] ==
        true;
    final cash = payment['requiresCashCollection'] == true;
    final expected = (payment['cashCollectionAmount'] as num?)?.toDouble();
    return AlertDialog(
      title: Text(ar ? 'تأكيد تسليم الطلب' : 'Confirm delivery'),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (cash) ...[
                Text(
                  '${ar ? 'المطلوب تحصيله' : 'Cash due'}: $expected ${payment['currency'] ?? ''}',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('cash-amount'),
                  controller: _amount,
                  textDirection: TextDirection.ltr,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: ar
                        ? 'المبلغ المستلم فعليًا'
                        : 'Amount actually received',
                  ),
                  validator: (s) {
                    final amount = double.tryParse(s?.trim() ?? '');
                    return expected == null ||
                            amount == null ||
                            !amount.isFinite ||
                            amount != expected
                        ? (ar
                              ? 'يجب استلام كامل المبلغ المطلوب'
                              : 'Collect the exact amount due')
                        : null;
                  },
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _cashConfirmed,
                  onChanged: (v) => setState(() => _cashConfirmed = v == true),
                  title: Text(
                    ar
                        ? 'استلمت النقد وأتحمل عهدته'
                        : 'I received the cash and accept custody',
                  ),
                ),
              ],
              TextFormField(
                key: const Key('delivery-code'),
                controller: _code,
                textDirection: TextDirection.ltr,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: ar
                      ? 'رمز الاستلام من العميل'
                      : 'Customer delivery code',
                ),
                validator: (s) => contactless && (s?.trim().isEmpty ?? true)
                    ? (ar ? 'رمز العميل مطلوب' : 'Customer code required')
                    : null,
              ),
              if (contactless)
                TextButton(
                  onPressed: _requesting ? null : _requestCode,
                  child: Text(ar ? 'إرسال رمز للعميل' : 'Send customer code'),
                ),
              if (_message != null) Text(_message!),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(ar ? 'إلغاء' : 'Cancel'),
        ),
        FilledButton(
          onPressed: _requesting || (cash && !_cashConfirmed)
              ? null
              : () {
                  if (!_form.currentState!.validate()) return;
                  Navigator.pop(
                    context,
                    DeliveryConfirmation(
                      numericCode: _code.text.trim().isEmpty
                          ? null
                          : _code.text.trim(),
                      cashConfirmed: cash && _cashConfirmed,
                      cashAmount: cash
                          ? double.parse(_amount.text.trim())
                          : null,
                    ),
                  );
                },
          child: Text(ar ? 'تأكيد التسليم' : 'Confirm delivery'),
        ),
      ],
    );
  }
}
