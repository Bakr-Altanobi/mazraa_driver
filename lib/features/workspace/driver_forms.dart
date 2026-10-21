import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mazraa_driver/core/network/api_exception.dart';
import 'package:mazraa_driver/shared/widgets/mazraa_widgets.dart';
import 'driver_workspace_repository.dart';

class ToolField {
  const ToolField(
    this.key,
    this.ar,
    this.en, {
    this.kind = 'text',
    this.required = true,
    this.options,
    this.min,
    this.max,
  });
  final String key, ar, en, kind;
  final bool required;
  final Map<String, String>? options;
  final double? min, max;
}

const _notes = ToolField(
  'notes',
  'ملاحظات',
  'Notes',
  kind: 'multiline',
  required: false,
);
const toolForms = <String, List<ToolField>>{
  'availability': [
    ToolField(
      'dayOfWeek',
      'يوم الأسبوع',
      'Weekday',
      kind: 'choice',
      options: {
        '0': 'الأحد / Sunday',
        '1': 'الاثنين / Monday',
        '2': 'الثلاثاء / Tuesday',
        '3': 'الأربعاء / Wednesday',
        '4': 'الخميس / Thursday',
        '5': 'الجمعة / Friday',
        '6': 'السبت / Saturday',
      },
    ),
    ToolField('startTime', 'وقت البداية', 'Start time', kind: 'time'),
    ToolField('endTime', 'وقت النهاية', 'End time', kind: 'time'),
    ToolField('isActive', 'الفترة مفعّلة', 'Active window', kind: 'bool'),
  ],
  'preferences': [
    ToolField(
      'acceptScheduledTrips',
      'قبول الرحلات المجدولة',
      'Accept scheduled trips',
      kind: 'bool',
    ),
    ToolField(
      'acceptPrivateDeliveries',
      'قبول التوصيل الخاص',
      'Accept private deliveries',
      kind: 'bool',
    ),
    ToolField(
      'acceptBatchDeliveries',
      'قبول توصيل عدة طلبات',
      'Accept batch deliveries',
      kind: 'bool',
    ),
    ToolField(
      'isAvailableForOffers',
      'استقبال عروض جديدة',
      'Receive new offers',
      kind: 'bool',
    ),
    ToolField(
      'offerRadiusKm',
      'نطاق العروض بالكيلومتر',
      'Offer radius (km)',
      kind: 'number',
      min: 1,
      max: 500,
    ),
    ToolField(
      'offerTimeoutSeconds',
      'مهلة العرض بالثواني',
      'Offer timeout (seconds)',
      kind: 'integer',
      min: 15,
      max: 300,
    ),
  ],
  'notifications': [
    ToolField(
      'pushNotifications',
      'إشعارات الهاتف',
      'Push notifications',
      kind: 'bool',
    ),
    ToolField(
      'emailNotifications',
      'البريد الإلكتروني',
      'Email notifications',
      kind: 'bool',
    ),
    ToolField(
      'smsNotifications',
      'الرسائل النصية',
      'SMS notifications',
      kind: 'bool',
    ),
    ToolField(
      'marketingNotifications',
      'العروض التسويقية',
      'Marketing notifications',
      kind: 'bool',
    ),
  ],
  'maintenance': [
    ToolField(
      'serviceAt',
      'تاريخ الصيانة المنجزة',
      'Completed service date',
      kind: 'date',
    ),
    ToolField(
      'odometerKm',
      'عداد المسافة بالكيلومتر',
      'Odometer (km)',
      kind: 'number',
      min: 0,
      max: 99999999,
      required: false,
    ),
    ToolField(
      'nextServiceAt',
      'موعد الصيانة التالية',
      'Next service date',
      kind: 'date',
      required: false,
    ),
    ToolField(
      'nextServiceOdometerKm',
      'العداد للصيانة التالية',
      'Next odometer (km)',
      kind: 'number',
      min: 0,
      max: 99999999,
      required: false,
    ),
    _notes,
  ],
  'bank': [
    ToolField('bankName', 'اسم البنك', 'Bank name'),
    ToolField('accountHolderName', 'اسم صاحب الحساب', 'Account holder'),
    ToolField('iban', 'رقم IBAN', 'IBAN', kind: 'iban'),
    ToolField('accountNumber', 'رقم الحساب', 'Account number', required: false),
  ],
  'incident': [
    ToolField(
      'category',
      'نوع المشكلة',
      'Category',
      kind: 'choice',
      options: {
        'order': 'مشكلة طلب / Order problem',
        'damaged-goods': 'منتجات تالفة / Damaged goods',
        'missing-items': 'نقص منتجات / Missing items',
        'customer-unavailable': 'تعذر الوصول للعميل / Customer unavailable',
        'vehicle': 'عطل المركبة / Vehicle issue',
        'payment': 'تحصيل ومدفوعات / Payment',
        'other': 'أخرى / Other',
      },
    ),
    ToolField('title', 'عنوان البلاغ', 'Report title'),
    ToolField(
      'description',
      'وصف المشكلة',
      'Describe the issue',
      kind: 'multiline',
    ),
  ],
  'emergency': [
    ToolField('title', 'عنوان الحالة العاجلة', 'Urgent report title'),
    ToolField(
      'description',
      'ما الذي حدث؟',
      'What happened?',
      kind: 'multiline',
    ),
  ],
  'profile': [
    ToolField('name', 'الاسم', 'Name'),
    ToolField('phone', 'رقم الهاتف', 'Phone', kind: 'phone'),
  ],
  'password': [
    ToolField(
      'currentPassword',
      'كلمة المرور الحالية',
      'Current password',
      kind: 'password',
    ),
    ToolField(
      'newPassword',
      'كلمة المرور الجديدة',
      'New password',
      kind: 'password',
    ),
    ToolField(
      'confirmPassword',
      'تأكيد كلمة المرور',
      'Confirm password',
      kind: 'password',
    ),
  ],
  'privacy': [
    ToolField(
      'analyticsConsent',
      'الموافقة على تحليلات الاستخدام الاختيارية',
      'Optional usage analytics consent',
      kind: 'bool',
    ),
    ToolField(
      'shareArrivalUpdates',
      'مشاركة تحديثات الوصول مع العميل',
      'Share arrival updates with customer',
      kind: 'bool',
    ),
  ],
  'deletion': [
    ToolField('reason', 'سبب الطلب', 'Reason for request', kind: 'multiline'),
    ToolField(
      'confirmed',
      'أطلب حذف حسابي بعد تسوية الشحنات والمبالغ',
      'Request deletion after delivery and financial settlement',
      kind: 'confirm',
    ),
  ],
};

/// Pure validation used by the form and contract tests. Returns normalized API
/// fields; never invents a vehicle, shipment, currency or preference value.
Map<String, dynamic> normalizeToolForm(
  String form,
  Map<String, dynamic> values,
) {
  final out = Map<String, dynamic>.from(values);
  if (form == 'availability') {
    if ('${out['startTime']}'.compareTo('${out['endTime']}') >= 0)
      throw const FormatException(
        'وقت النهاية يجب أن يلي البداية / End must follow start',
      );
    out['startTime'] = '${out['startTime']}:00';
    out['endTime'] = '${out['endTime']}:00';
  }
  if (form == 'bank') {
    out['iban'] = '${out['iban']}'.replaceAll(' ', '').toUpperCase();
  }
  if (form == 'password') {
    if ('${out['newPassword']}'.length < 8)
      throw const FormatException(
        'كلمة المرور 8 أحرف على الأقل / Use at least 8 characters',
      );
    if (out['newPassword'] != out['confirmPassword'])
      throw const FormatException(
        'كلمتا المرور غير متطابقتين / Passwords do not match',
      );
    out.remove('confirmPassword');
  }
  if (form == 'maintenance') {
    final service = DateTime.parse('${out['serviceAt']}');
    if (service.isAfter(DateTime.now()))
      throw const FormatException(
        'الصيانة المنجزة لا تكون في المستقبل / Service cannot be in the future',
      );
    if (out['nextServiceAt'] != null &&
        DateTime.parse('${out['nextServiceAt']}').isBefore(service))
      throw const FormatException(
        'موعد الصيانة التالية يسبق الصيانة الحالية / Invalid next service date',
      );
    if (out['odometerKm'] != null &&
        out['nextServiceOdometerKm'] != null &&
        (out['nextServiceOdometerKm'] as num) < (out['odometerKm'] as num))
      throw const FormatException(
        'العداد التالي أقل من الحالي / Next odometer is too low',
      );
  }
  if (form == 'deletion' && out['confirmed'] != true)
    throw const FormatException(
      'أكّد طلب الحذف أولًا / Confirm deletion first',
    );
  return out;
}

class DriverToolFormScreen extends ConsumerStatefulWidget {
  const DriverToolFormScreen({
    required this.form,
    required this.title,
    this.initial = const {},
    this.pending = false,
    super.key,
  });
  final String form, title;
  final Map<String, dynamic> initial;
  final bool pending;
  @override
  ConsumerState<DriverToolFormScreen> createState() =>
      _DriverToolFormScreenState();
}

class _DriverToolFormScreenState extends ConsumerState<DriverToolFormScreen> {
  final _key = GlobalKey<FormState>();
  final _text = <String, TextEditingController>{};
  final _values = <String, dynamic>{};
  bool _saving = false, _locating = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _values.addAll(widget.initial);
    for (final f in toolForms[widget.form]!) {
      if (f.kind == 'bool' || f.kind == 'confirm') {
        if (!_values.containsKey(f.key)) _values[f.key] = false;
      } else {
        _text[f.key] = TextEditingController(
          text: '${widget.initial[f.key] ?? ''}',
        );
      }
    }
  }

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _location() async {
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled())
        throw StateError('فعّل خدمة الموقع / Enable location services');
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied)
        p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied ||
          p == LocationPermission.deniedForever)
        throw StateError(
          'لم يُمنح إذن الموقع / Location permission not granted',
        );
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      _values.addAll({'latitude': pos.latitude, 'longitude': pos.longitude});
      if (mounted) setState(() => _error = null);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    if (_saving || !_key.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final data = Map<String, dynamic>.from(_values);
      for (final f in toolForms[widget.form]!) {
        if (!_text.containsKey(f.key)) continue;
        final value = _text[f.key]!.text.trim();
        data[f.key] = value.isEmpty
            ? null
            : switch (f.kind) {
                'number' => double.parse(value),
                'integer' => int.parse(value),
                'choice' => int.tryParse(value) ?? value,
                _ => value,
              };
      }
      if (widget.form == 'incident' || widget.form == 'emergency') {
        data['isEmergency'] = widget.form == 'emergency';
        if (widget.form == 'emergency') data['category'] = 'emergency';
      }
      await ref
          .read(workspaceRepositoryProvider)
          .submit(widget.form, normalizeToolForm(widget.form, data));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        setState(
          () => _error =
              e is ApiException &&
                  (e.statusCode == 404 ||
                      e.statusCode == 405 ||
                      e.statusCode == 501)
              ? 'هذه الخدمة لم تُفعّل في السيرفر بعد. بقيت مدخلاتك هنا. / This service is not supported by the server yet. Your input is retained.'
              : '$e',
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Form(
        key: _key,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            if (widget.pending)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    ar
                        ? 'الواجهة جاهزة. يعتمد حفظ هذا الطلب على دعم السيرفر لهذه الخدمة.'
                        : 'The form is ready. Saving requires server support for this service.',
                  ),
                ),
              ),
            if (widget.form == 'bank')
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  ar
                      ? 'تعديل الحساب يعيده إلى المراجعة قبل السماح بالسحب.'
                      : 'Changing bank details requires verification before payouts.',
                ),
              ),
            if (widget.form == 'emergency')
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  ar
                      ? 'إذا كان هناك خطر فوري، اتصل بخدمات الطوارئ المحلية مباشرة. هذا البلاغ يُرسل لفريق التشغيل.'
                      : 'For immediate danger, contact local emergency services directly. This report is sent to operations.',
                ),
              ),
            for (final f in toolForms[widget.form]!)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: f.kind == 'bool' || f.kind == 'confirm'
                    ? Card(
                        child: SwitchListTile(
                          title: Text(ar ? f.ar : f.en),
                          value: _values[f.key] == true,
                          onChanged: _saving
                              ? null
                              : (v) => setState(() => _values[f.key] = v),
                        ),
                      )
                    : f.kind == 'choice'
                    ? DropdownButtonFormField<String>(
                        initialValue: _text[f.key]!.text.isEmpty
                            ? null
                            : _text[f.key]!.text,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: ar ? f.ar : f.en,
                        ),
                        items: f.options!.entries
                            .map(
                              (o) => DropdownMenuItem(
                                value: o.key,
                                child: Text(o.value),
                              ),
                            )
                            .toList(),
                        onChanged: _saving
                            ? null
                            : (v) => _text[f.key]!.text = v ?? '',
                        validator: (v) => f.required && v == null
                            ? (ar ? 'مطلوب' : 'Required')
                            : null,
                      )
                    : TextFormField(
                        key: Key('field-${f.key}'),
                        controller: _text[f.key],
                        enabled: !_saving,
                        obscureText: f.kind == 'password',
                        maxLines: f.kind == 'multiline' ? 4 : 1,
                        readOnly: f.kind == 'date' || f.kind == 'time',
                        keyboardType: f.kind == 'number' || f.kind == 'integer'
                            ? const TextInputType.numberWithOptions(
                                decimal: true,
                              )
                            : f.kind == 'phone'
                            ? TextInputType.phone
                            : TextInputType.text,
                        decoration: InputDecoration(
                          labelText:
                              '${ar ? f.ar : f.en}${f.required ? ' *' : ''}',
                          suffixIcon: f.kind == 'date'
                              ? const Icon(Icons.calendar_today)
                              : f.kind == 'time'
                              ? const Icon(Icons.schedule)
                              : null,
                        ),
                        onTap: f.kind == 'date'
                            ? () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      DateTime.tryParse(_text[f.key]!.text) ??
                                      DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (d != null && mounted)
                                  _text[f.key]!.text = d.toIso8601String();
                              }
                            : f.kind == 'time'
                            ? () async {
                                final t = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (t != null && mounted)
                                  _text[f.key]!.text =
                                      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                              }
                            : null,
                        validator: (v) {
                          final s = v?.trim() ?? '';
                          if (s.isEmpty)
                            return f.required
                                ? (ar ? 'مطلوب' : 'Required')
                                : null;
                          if (f.kind == 'number' || f.kind == 'integer') {
                            final n = double.tryParse(s);
                            if (n == null ||
                                !n.isFinite ||
                                (f.min != null && n < f.min!) ||
                                (f.max != null && n > f.max!) ||
                                (f.kind == 'integer' && n != n.roundToDouble()))
                              return ar
                                  ? 'أدخل قيمة صحيحة ضمن النطاق'
                                  : 'Enter a valid number in range';
                          }
                          if (f.kind == 'iban' &&
                              !RegExp(
                                r'^[A-Za-z]{2}[0-9A-Za-z ]{13,32}$',
                              ).hasMatch(s))
                            return ar
                                ? 'أدخل IBAN صالحًا'
                                : 'Enter a valid IBAN';
                          return null;
                        },
                      ),
              ),
            if (widget.form == 'incident' || widget.form == 'emergency')
              OutlinedButton.icon(
                onPressed: _saving || _locating ? null : _location,
                icon: const Icon(Icons.my_location),
                label: Text(
                  _values['latitude'] != null
                      ? (ar
                            ? 'أُرفق موقعي الحالي'
                            : 'Current location attached')
                      : (ar
                            ? 'إرفاق موقعي (اختياري)'
                            : 'Attach location (optional)'),
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _error!,
                  key: const Key('form-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 10),
            FilledButton.icon(
              key: const Key('submit-tool-form'),
              onPressed: _saving || _locating ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(ar ? 'حفظ وإرسال' : 'Save & submit'),
            ),
          ],
        ),
      ),
    );
  }
}
