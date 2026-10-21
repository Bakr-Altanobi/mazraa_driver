import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mazraa_driver/core/network/providers.dart';
import 'package:mazraa_driver/features/reference_journey/reference_assets.dart';
import 'package:mazraa_driver/shared/widgets/mazraa_widgets.dart';

class DriverDocumentUploadScreen extends ConsumerStatefulWidget {
  const DriverDocumentUploadScreen({super.key});

  @override
  ConsumerState<DriverDocumentUploadScreen> createState() =>
      _DriverDocumentUploadScreenState();
}

class _DriverDocumentUploadScreenState extends ConsumerState<DriverDocumentUploadScreen> {
  final _picker = ImagePicker();
  final _number = TextEditingController();
  XFile? _image;
  int _type = 0;
  DateTime? _expires;
  bool _saving = false;

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source, maxWidth: 1600, imageQuality: 82,
      );
      if (file != null && mounted) setState(() => _image = file);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _upload() async {
    if (_saving || _image == null) return;
    setState(() => _saving = true);
    try {
      final fields = <String, dynamic>{
        'type': _type,
        if (_number.text.trim().isNotEmpty) 'documentNumber': _number.text.trim(),
        if (_expires != null) 'expiresAt': _expires!.toUtc().toIso8601String(),
      };
      final uploaded = await ref.read(apiClientProvider).uploadFile(
        'api/driver-media/documents',
        filePath: _image!.path, fileName: _image!.name, fields: fields,
      );
      if (uploaded['id'] == null) throw StateError('Document upload not confirmed by server');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isArabic(context)
            ? 'رُفع المستند إلى السيرفر وهو بانتظار مراجعة الإدارة.'
            : 'Document uploaded; awaiting operations review.'),
      ));
      setState(() { _image = null; _number.clear(); _expires = null; });
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    final types = ar
        ? const ['الهوية', 'رخصة القيادة', 'استمارة المركبة', 'تأمين المركبة', 'مستند آخر']
        : const ['Identity', 'Driving license', 'Registration', 'Insurance', 'Other'];
    return Scaffold(
      appBar: AppBar(title: Text(ar ? 'رفع مستند السائق' : 'Upload driver document')),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        Image.asset(ReferenceAssets.documentShield, height: 122, cacheWidth: 300),
        const SizedBox(height: 14),
        Text(ar ? 'ارفع صورة فعلية، لا رابطًا أو بيانات وهمية.'
                : 'Upload a real document photo, not an external placeholder link.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 18),
        DropdownButtonFormField<int>(
          value: _type,
          decoration: InputDecoration(labelText: ar ? 'نوع المستند' : 'Document type'),
          items: [for (var index = 0; index < types.length; index++)
            DropdownMenuItem(value: index, child: Text(types[index]))],
          onChanged: _saving ? null : (value) => setState(() => _type = value ?? 0),
        ),
        const SizedBox(height: 12),
        TextField(controller: _number,
          decoration: InputDecoration(labelText: ar ? 'رقم المستند (اختياري)' : 'Document number (optional)')),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _saving ? null : () async {
            final date = await showDatePicker(
              context: context,
              firstDate: DateTime.now().subtract(const Duration(days: 3650)),
              lastDate: DateTime.now().add(const Duration(days: 3650)),
              initialDate: _expires ?? DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null && mounted) setState(() => _expires = date);
          },
          icon: const Icon(Icons.event_outlined),
          label: Text(_expires == null
              ? (ar ? 'تاريخ انتهاء المستند' : 'Document expiration')
              : _expires!.toIso8601String().substring(0, 10)),
        ),
        const SizedBox(height: 15),
        if (_image != null) ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(File(_image!.path), height: 180, fit: BoxFit.contain),
        ),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: _saving ? null : () => _pick(ImageSource.camera),
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(ar ? 'الكاميرا' : 'Camera'),
          )),
          const SizedBox(width: 10),
          Expanded(child: OutlinedButton.icon(
            onPressed: _saving ? null : () => _pick(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(ar ? 'المعرض' : 'Gallery'),
          )),
        ]),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _saving || _image == null ? null : _upload,
          icon: _saving ? const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.cloud_upload_outlined),
          label: Text(ar ? 'حفظ المستند على السيرفر' : 'Submit document'),
        ),
      ]),
    );
  }
}

class DriverProofPhotoScreen extends ConsumerStatefulWidget {
  const DriverProofPhotoScreen({required this.shipmentId, this.initialType = 0, super.key});
  final int initialType;
  final int shipmentId;
  @override
  ConsumerState<DriverProofPhotoScreen> createState() => _DriverProofPhotoScreenState();
}

class _DriverProofPhotoScreenState extends ConsumerState<DriverProofPhotoScreen> {
  XFile? _image;
  late int _type = widget.initialType;
  final _recipient = TextEditingController();
  final _notes = TextEditingController();
  bool _saving = false;

  @override
  void dispose() { _recipient.dispose(); _notes.dispose(); super.dispose(); }

  Future<void> _pick(ImageSource source) async {
    try {
      final selected = await ImagePicker().pickImage(source: source,
          maxWidth: 1600, imageQuality: 82);
      if (selected != null && mounted) setState(() => _image = selected);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
  }

  Future<void> _save() async {
    if (_image == null || _saving) return;
    setState(() => _saving = true);
    try {
      final data = await ref.read(apiClientProvider).uploadFile(
        'api/driver-media/shipments/${widget.shipmentId}/proof-photo',
        filePath: _image!.path, fileName: _image!.name,
        fields: {
          'type': _type,
          if (_recipient.text.trim().isNotEmpty) 'recipientName': _recipient.text.trim(),
          if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
        },
      );
      if (data['id'] == null) throw StateError('Proof record was not confirmed');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isArabic(context) ? 'تم حفظ إثبات الشحنة فعليًا.'
            : 'Shipment evidence has been saved.'),
      ));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    return Scaffold(
      appBar: AppBar(title: Text(ar ? 'إثبات الشحنة' : 'Shipment evidence')),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        Image.asset(ReferenceAssets.deliveryParcel, height: 105, cacheWidth: 260),
        const SizedBox(height: 14),
        Text(ar ? 'شحنة #${widget.shipmentId}' : 'Shipment #${widget.shipmentId}',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        SegmentedButton<int>(
          segments: [
            ButtonSegment(value: 0, label: Text(ar ? 'الاستلام' : 'Pickup')),
            ButtonSegment(value: 1, label: Text(ar ? 'التسليم' : 'Delivery')),
          ],
          selected: {_type},
          onSelectionChanged: _saving ? null : (selection) =>
              setState(() => _type = selection.first),
        ),
        const SizedBox(height: 12),
        TextField(controller: _recipient,
            decoration: InputDecoration(labelText: ar ? 'اسم المستلم (اختياري)' : 'Recipient (optional)')),
        TextField(controller: _notes,
            maxLines: 3, decoration: InputDecoration(labelText: ar ? 'ملاحظات' : 'Notes')),
        if (_image != null) Image.file(File(_image!.path), height: 175, fit: BoxFit.contain),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: _saving ? null : () => _pick(ImageSource.camera),
            icon: const Icon(Icons.camera_alt_outlined), label: Text(ar ? 'تصوير' : 'Camera'),
          )),
          const SizedBox(width: 10),
          Expanded(child: OutlinedButton.icon(
            onPressed: _saving ? null : () => _pick(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined), label: Text(ar ? 'المعرض' : 'Gallery'),
          )),
        ]),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _saving || _image == null ? null : _save,
          icon: const Icon(Icons.cloud_upload_outlined),
          label: Text(_saving ? (ar ? 'جارٍ الرفع...' : 'Uploading...')
              : (ar ? 'رفع صورة الإثبات' : 'Upload evidence')),
        ),
      ]),
    );
  }
}
