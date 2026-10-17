import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazraa_driver/core/network/providers.dart';

/// Creates genuine maintenance records against the driver's currently
/// assigned vehicle. Ownership is also verified by the backend.
class VehicleMaintenanceEditor extends ConsumerStatefulWidget {
  const VehicleMaintenanceEditor({required this.onSaved, super.key});

  final VoidCallback onSaved;

  @override
  ConsumerState<VehicleMaintenanceEditor> createState() =>
      _VehicleMaintenanceEditorState();
}

class _VehicleMaintenanceEditorState
    extends ConsumerState<VehicleMaintenanceEditor> {
  bool _busy = false;

  Future<void> _addRecord() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final api = ref.read(driverApiProvider);
      final vehicle = await api.getMyCurrentVehicle();
      final vehicleId = int.tryParse('${vehicle['id'] ?? ''}');
      if (vehicleId == null || vehicleId <= 0) {
        throw StateError('لا توجد مركبة فعلية مسندة إلى حساب السائق.');
      }
      if (!mounted) return;
      final form = GlobalKey<FormState>();
      final distance = TextEditingController();
      final nextDistance = TextEditingController();
      final notes = TextEditingController();
      var serviceDate = DateTime.now();
      DateTime? nextService;
      try {
        final submitted = await showDialog<bool>(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, update) => AlertDialog(
              title: const Text('إضافة سجل صيانة للمركبة'),
              content: SingleChildScrollView(
                child: Form(
                  key: form,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('المركبة المسندة: ${vehicle['vehicleCode'] ?? vehicleId}'),
                      const SizedBox(height: 10),
                      ListTile(
                        title: const Text('تاريخ الصيانة'),
                        subtitle: Text('${serviceDate.year}-${serviceDate.month.toString().padLeft(2, '0')}-${serviceDate.day.toString().padLeft(2, '0')}'),
                        trailing: const Icon(Icons.date_range_outlined),
                        onTap: () async {
                          final selected = await showDatePicker(
                            context: ctx,
                            firstDate: DateTime(2010),
                            lastDate: DateTime.now(),
                            initialDate: serviceDate,
                          );
                          if (selected != null) update(() => serviceDate = selected);
                        },
                      ),
                      TextFormField(
                        controller: distance,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'عداد الكيلومترات (اختياري)'),
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) return null;
                          final number = double.tryParse(value!.trim());
                          return number != null && number >= 0 && number.isFinite
                              ? null : 'أدخل قيمة غير سالبة';
                        },
                      ),
                      TextFormField(
                        controller: notes,
                        minLines: 2,
                        maxLines: 4,
                        maxLength: 1000,
                        decoration: const InputDecoration(labelText: 'تفاصيل الصيانة'),
                      ),
                      ListTile(
                        title: const Text('موعد الصيانة القادمة (اختياري)'),
                        subtitle: Text(nextService == null
                            ? 'لم يُحدد'
                            : '${nextService!.year}-${nextService!.month.toString().padLeft(2, '0')}-${nextService!.day.toString().padLeft(2, '0')}'),
                        trailing: const Icon(Icons.event_outlined),
                        onTap: () async {
                          final now = DateTime.now();
                          final selected = await showDatePicker(
                            context: ctx,
                            firstDate: now,
                            lastDate: DateTime(now.year + 10),
                            initialDate: nextService ?? now,
                          );
                          if (selected != null) update(() => nextService = selected);
                        },
                      ),
                      TextFormField(
                        controller: nextDistance,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'عداد الصيانة القادمة (اختياري)'),
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) return null;
                          final number = double.tryParse(value!.trim());
                          if (number == null || !number.isFinite || number < 0) {
                            return 'أدخل قيمة غير سالبة';
                          }
                          final previous = double.tryParse(distance.text.trim());
                          return previous != null && number < previous
                              ? 'القيمة القادمة أصغر من العداد الحالي' : null;
                        },
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
                    if (form.currentState?.validate() == true) {
                      Navigator.pop(ctx, true);
                    }
                  },
                  child: const Text('تسجيل الصيانة'),
                ),
              ],
            ),
          ),
        );
        if (submitted != true || !mounted) return;
        await api.addVehicleMaintenance(
          vehicleId: vehicleId,
          serviceAt: serviceDate,
          odometerKm: double.tryParse(distance.text.trim()),
          nextServiceAt: nextService,
          nextServiceOdometerKm: double.tryParse(nextDistance.text.trim()),
          notes: notes.text.isEmpty ? null : notes.text,
        );
        if (mounted) {
          widget.onSaved();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تمت إضافة سجل صيانة المركبة في السيرفر.')),
          );
        }
      } finally {
        distance.dispose();
        nextDistance.dispose();
        notes.dispose();
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
  Widget build(BuildContext context) => FilledButton.icon(
        key: const Key('addVehicleMaintenanceButton'),
        onPressed: _busy ? null : _addRecord,
        icon: const Icon(Icons.build_circle_outlined),
        label: const Text('إضافة صيانة للمركبة'),
      );
}
