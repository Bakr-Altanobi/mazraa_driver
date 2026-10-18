import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mazraa_driver/core/constants/api_endpoints.dart';
import 'package:mazraa_driver/core/network/driver_media_api.dart';
import 'package:mazraa_driver/core/network/providers.dart';
import 'package:mazraa_driver/features/auth/auth_controller.dart';
import 'package:mazraa_driver/features/reference_journey/reference_assets.dart';

class DriverDocumentsScreen extends ConsumerStatefulWidget {
  const DriverDocumentsScreen({super.key});

  @override
  ConsumerState<DriverDocumentsScreen> createState() =>
      _DriverDocumentsScreenState();
}

class _DriverDocumentsScreenState extends ConsumerState<DriverDocumentsScreen> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  List<Map<String, dynamic>> _documents = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await ref.read(driverApiProvider).getDriverDocuments();
      if (!mounted) return;
      setState(() {
        _documents = _maps(rows);
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

  Future<void> _addDocument() async {
    final driverId = ref.read(authControllerProvider).profile?.userId;
    if (driverId == null) return;
    final meta = await _documentDialog();
    if (meta == null || !mounted) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('التقاط صورة بالكاميرا'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('اختيار من الصور'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    final photo = await ImagePicker().pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 2000,
    );
    if (photo == null) return;

    setState(() => _busy = true);
    try {
      final mediaUrl = await ref
          .read(driverMediaApiProvider)
          .uploadDriverDocument(filePath: photo.path, driverId: driverId);
      await ref.read(driverApiProvider).addDriverDocument(
            type: meta.type,
            mediaUrl: mediaUrl,
            documentNumber: meta.number,
            expiresAt: meta.expiresAt,
          );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفع الصورة وحفظ الوثيقة على السيرفر.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<_DocumentDraft?> _documentDialog() async {
    var type = 0;
    DateTime? expiresAt;
    final number = TextEditingController();
    final result = await showDialog<_DocumentDraft>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('إضافة وثيقة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'نوع الوثيقة'),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('الهوية')),
                    DropdownMenuItem(value: 1, child: Text('رخصة القيادة')),
                    DropdownMenuItem(value: 2, child: Text('استمارة المركبة')),
                    DropdownMenuItem(value: 3, child: Text('تأمين المركبة')),
                    DropdownMenuItem(value: 4, child: Text('وثيقة أخرى')),
                  ],
                  onChanged: (value) => setLocal(() => type = value ?? 0),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: number,
                  decoration: const InputDecoration(
                    labelText: 'رقم الوثيقة (اختياري)',
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_outlined),
                  title: const Text('تاريخ الانتهاء'),
                  subtitle: Text(
                    expiresAt == null ? 'غير محدد' : _date(expiresAt!),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) setLocal(() => expiresAt = picked);
                  },
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
              onPressed: () => Navigator.pop(
                dialogContext,
                _DocumentDraft(
                  type,
                  number.text.trim().isEmpty ? null : number.text.trim(),
                  expiresAt,
                ),
              ),
              child: const Text('اختيار الصورة'),
            ),
          ],
        ),
      ),
    );
    number.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('وثائق السائق والمركبة'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _addDocument,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('إضافة وثيقة'),
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
                        height: 135,
                        child: Image.asset(
                          ReferenceAssets.identityScan,
                          fit: BoxFit.contain,
                          cacheWidth: 620,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_documents.isEmpty)
                        const _Empty(
                          'لا توجد وثائق محفوظة. ارفع الهوية أو الرخصة أو وثيقة المركبة.',
                        ),
                      for (final row in _documents) _documentCard(row),
                    ],
                  ),
                ),
    );
  }

  Widget _documentCard(Map<String, dynamic> row) {
    final url = _absoluteUrl('${row['mediaUrl'] ?? ''}');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 72,
                height: 72,
                child: url.isEmpty
                    ? const ColoredBox(
                        color: Color(0xFFF2F1EC),
                        child: Icon(Icons.description_outlined),
                      )
                    : Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const ColoredBox(
                          color: Color(0xFFF2F1EC),
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _documentType(row['type']),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text('الحالة: ${_documentStatus(row['status'])}'),
                  if ('${row['documentNumber'] ?? ''}'.isNotEmpty)
                    Text('الرقم: ${row['documentNumber']}'),
                  if (row['expiresAt'] != null)
                    Text('الانتهاء: ${row['expiresAt']}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VehicleMaintenanceScreen extends ConsumerStatefulWidget {
  const VehicleMaintenanceScreen({super.key});

  @override
  ConsumerState<VehicleMaintenanceScreen> createState() =>
      _VehicleMaintenanceScreenState();
}

class _VehicleMaintenanceScreenState
    extends ConsumerState<VehicleMaintenanceScreen> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  int? _vehicleId;
  Map<String, dynamic> _vehicle = {};
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(driverApiProvider);
      final me = await api.getJourneyMe();
      final rows = await api.getVehicleMaintenance();
      final vehicle = _map(me['vehicle']);
      if (!mounted) return;
      setState(() {
        _vehicle = vehicle;
        _vehicleId = _nullableInt(vehicle['id']);
        _rows = _maps(rows);
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

  Future<void> _add() async {
    final vehicleId = _vehicleId;
    if (vehicleId == null) {
      _showError(context, 'لا توجد مركبة نشطة مسندة إلى حساب السائق.');
      return;
    }
    final draft = await _maintenanceDialog();
    if (draft == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(driverApiProvider).addVehicleMaintenance(
            vehicleId: vehicleId,
            serviceAt: draft.serviceAt,
            odometerKm: draft.odometerKm,
            nextServiceAt: draft.nextServiceAt,
            nextServiceOdometerKm: draft.nextOdometerKm,
            notes: draft.notes,
          );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ سجل الصيانة على السيرفر.')),
        );
      }
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<_MaintenanceDraft?> _maintenanceDialog() async {
    final odometer = TextEditingController();
    final nextOdometer = TextEditingController();
    final notes = TextEditingController();
    var serviceAt = DateTime.now();
    DateTime? nextServiceAt;
    final result = await showDialog<_MaintenanceDraft>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('تسجيل صيانة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('تاريخ الصيانة'),
                  subtitle: Text(_date(serviceAt)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: serviceAt,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setLocal(() => serviceAt = picked);
                  },
                ),
                TextField(
                  controller: odometer,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'عداد المركبة كم (اختياري)',
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('موعد الصيانة التالية'),
                  subtitle: Text(
                    nextServiceAt == null ? 'غير محدد' : _date(nextServiceAt!),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: nextServiceAt ??
                          DateTime.now().add(const Duration(days: 90)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) setLocal(() => nextServiceAt = picked);
                  },
                ),
                TextField(
                  controller: nextOdometer,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'عداد الصيانة التالية (اختياري)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notes,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'ملاحظات'),
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
              onPressed: () => Navigator.pop(
                dialogContext,
                _MaintenanceDraft(
                  serviceAt: serviceAt,
                  odometerKm: double.tryParse(odometer.text.trim()),
                  nextServiceAt: nextServiceAt,
                  nextOdometerKm: double.tryParse(nextOdometer.text.trim()),
                  notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
                ),
              ),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    odometer.dispose();
    nextOdometer.dispose();
    notes.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('صيانة المركبة'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy || _vehicleId == null ? null : _add,
        icon: const Icon(Icons.build_circle_outlined),
        label: const Text('تسجيل صيانة'),
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
                        height: 130,
                        child: Image.asset(
                          ReferenceAssets.carMaintenance,
                          fit: BoxFit.contain,
                          cacheWidth: 620,
                        ),
                      ),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.local_shipping_outlined),
                          title: Text(
                            _vehicle.isEmpty
                                ? 'لا توجد مركبة نشطة'
                                : '${_vehicle['make'] ?? ''} ${_vehicle['model'] ?? ''}'.trim(),
                          ),
                          subtitle: Text(
                            _vehicle.isEmpty
                                ? 'يجب أن تسند الإدارة مركبة للسائق قبل تسجيل الصيانة.'
                                : 'المركبة #${_vehicleId ?? '—'} · ${_vehicle['plateNumber'] ?? _vehicle['licensePlate'] ?? ''}',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_rows.isEmpty)
                        const _Empty('لا توجد سجلات صيانة سابقة.'),
                      for (final row in _rows)
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.handyman_outlined),
                            title: Text('صيانة ${row['serviceAt'] ?? ''}'),
                            subtitle: Text(
                              'العداد: ${row['odometerKm'] ?? '—'} كم\n'
                              'القادمة: ${row['nextServiceAt'] ?? 'غير محدد'}\n'
                              '${row['notes'] ?? ''}',
                            ),
                            isThreeLine: true,
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _DocumentDraft {
  const _DocumentDraft(this.type, this.number, this.expiresAt);
  final int type;
  final String? number;
  final DateTime? expiresAt;
}

class _MaintenanceDraft {
  const _MaintenanceDraft({
    required this.serviceAt,
    this.odometerKm,
    this.nextServiceAt,
    this.nextOdometerKm,
    this.notes,
  });
  final DateTime serviceAt;
  final double? odometerKm;
  final DateTime? nextServiceAt;
  final double? nextOdometerKm;
  final String? notes;
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

int _int(Object? value, int fallback) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;

int? _nullableInt(Object? value) {
  if (value == null) return null;
  final parsed = _int(value, 0);
  return parsed == 0 ? null : parsed;
}

String _documentType(Object? value) => switch (_int(value, -1)) {
      0 => 'الهوية',
      1 => 'رخصة القيادة',
      2 => 'استمارة المركبة',
      3 => 'تأمين المركبة',
      4 => 'وثيقة أخرى',
      _ => 'وثيقة',
    };

String _documentStatus(Object? value) => switch (_int(value, -1)) {
      0 => 'قيد المراجعة',
      1 => 'معتمدة',
      2 => 'مرفوضة',
      3 => 'منتهية',
      _ => '$value',
    };

String _date(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

String _absoluteUrl(String value) {
  if (value.isEmpty) return '';
  final uri = Uri.tryParse(value);
  if (uri?.hasScheme == true) return value;
  return Uri.parse(ApiEndpoints.baseUrl).resolve(value).toString();
}

void _showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(error.toString())),
  );
}
