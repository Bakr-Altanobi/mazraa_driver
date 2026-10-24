import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazraa_driver/core/network/providers.dart';
import 'package:mazraa_driver/features/workspace/driver_workspace_repository.dart';

final availableDriverZonesProvider = FutureProvider.autoDispose<List<dynamic>>(
  (ref) => ref.watch(apiClientProvider)
      .get<List<dynamic>>('api/driver-journey/me/service-areas/available'),
);

/// Zone edits are scoped to the signed-in driver. Global zone prices/geometry
/// are operations-owned and are never mutated from this page.
class DriverServiceAreasEditor extends ConsumerStatefulWidget {
  const DriverServiceAreasEditor({required this.rows, super.key});
  final List<Map<String, dynamic>> rows;

  @override
  ConsumerState<DriverServiceAreasEditor> createState() =>
      _DriverServiceAreasEditorState();
}

class _DriverServiceAreasEditorState
    extends ConsumerState<DriverServiceAreasEditor> {
  int? _zoneId, _editingId;
  final _distance = TextEditingController(text: '50');
  bool _busy = false;

  @override
  void dispose() { _distance.dispose(); super.dispose(); }

  Future<void> _save() async {
    final zone = _zoneId;
    final km = double.tryParse(_distance.text.trim());
    if (_busy || zone == null || km == null || km < 1 || km > 500) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اختر منطقة ومسافة بين 1 و500 كم.')));
      return;
    }
    setState(() => _busy = true);
    try {
      final client = ref.read(apiClientProvider);
      final values = {'deliveryZoneId': zone, 'maxDistanceKm': km};
      if (_editingId != null) {
        await client.put<dynamic>(
            'api/driver-journey/me/service-areas/${_editingId!}', data: values);
      } else {
        await client.post<dynamic>(
            'api/driver-journey/me/service-areas', data: values);
      }
      ref.invalidate(toolDataProvider('service-area'));
      if (mounted) setState(() { _zoneId = null; _editingId = null; _distance.text = '50'; });
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(int id) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(apiClientProvider)
          .delete('api/driver-journey/me/service-areas/$id');
      ref.invalidate(toolDataProvider('service-area'));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final available = ref.watch(availableDriverZonesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(ar
            ? 'أضف نطاق عملك من المناطق المعتمدة. التعديل لا يغير المناطق العامة أو رسومها.'
            : 'Select your service coverage from approved zones; this never changes global pricing.'),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                available.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text(ar
                      ? 'تعذر تحميل المناطق. اسحب للأسفل لإعادة التحميل.'
                      : 'Cannot load zones. Pull down to retry.'),
                  data: (zones) => DropdownButtonFormField<int>(
                    key: ValueKey('zone-${_editingId ?? 'new'}'),
                    initialValue: _zoneId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: ar ? 'منطقة الخدمة' : 'Service zone',
                    ),
                    items: [
                      for (final raw in zones.whereType<Map>())
                        if (raw['id'] is num)
                          DropdownMenuItem(
                            value: (raw['id'] as num).toInt(),
                            child: Text('${raw['name'] ?? raw['id']}'),
                          ),
                    ],
                    onChanged: _busy ? null : (v) => setState(() => _zoneId = v),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _distance,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: ar ? 'أقصى مسافة بالكيلومتر' : 'Maximum distance (km)',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _busy ? null : _save,
                  icon: Icon(_editingId == null ? Icons.add : Icons.save_outlined),
                  label: Text(_editingId == null
                      ? (ar ? 'إضافة منطقة' : 'Add zone')
                      : (ar ? 'حفظ التعديل' : 'Save changes')),
                ),
                if (_editingId != null)
                  TextButton(
                    onPressed: () => setState(() {
                      _editingId = null; _zoneId = null; _distance.text = '50';
                    }),
                    child: Text(ar ? 'إلغاء التعديل' : 'Cancel editing'),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (widget.rows.isEmpty)
          Text(ar ? 'لا توجد مناطق خدمة مضافة.' : 'No areas selected.'),
        for (final row in widget.rows)
          Card(
            child: ListTile(
              title: Text('${row['zoneName'] ?? row['deliveryZoneId']}'),
              subtitle: Text('${row['maxDistanceKm'] ?? 50} km'),
              trailing: Wrap(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  tooltip: ar ? 'تعديل' : 'Edit',
                  onPressed: _busy ? null : () => setState(() {
                    _editingId = (row['id'] as num?)?.toInt();
                    _zoneId = (row['deliveryZoneId'] as num?)?.toInt();
                    _distance.text = '${row['maxDistanceKm'] ?? 50}';
                  }),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: ar ? 'حذف' : 'Delete',
                  onPressed: _busy || row['id'] is! num ? null :
                      () => _delete((row['id'] as num).toInt()),
                  icon: const Icon(Icons.delete_outline),
                ),
              ]),
            ),
          ),
      ],
    );
  }
}
