import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazraa_driver/features/workspace/driver_workspace_repository.dart';

/// Server-backed scheduled trips: a request is NOT an assigned delivery.
class DriverScheduledTripsTable extends ConsumerStatefulWidget {
  const DriverScheduledTripsTable({required this.rows, super.key});
  final List<Map<String, dynamic>> rows;
  @override
  ConsumerState<DriverScheduledTripsTable> createState() =>
      _DriverScheduledTripsTableState();
}

class _DriverScheduledTripsTableState
    extends ConsumerState<DriverScheduledTripsTable> {
  int? _selectedId;
  bool _busy = false;

  Future<void> _submit() async {
    final id = _selectedId;
    if (id == null || _busy) return;
    final entry = widget.rows.where((x) =>
        (recordMap(x['trip'])['id'] ?? x['id']) == id).firstOrNull;
    if (entry == null) return;
    final status = statusKey(recordMap(entry['participation'])['status']);
    final action = participationAction(status);
    final trip = recordMap(entry['trip']).isNotEmpty
        ? recordMap(entry['trip']) : entry;
    // An already assigned trip cannot accept a second driver's join request.
    // Existing pending applicants retain the ability to withdraw.
    if (action == null || (action == 'join' && trip['driverId'] != null)) return;
    setState(() => _busy = true);
    try {
      await ref.read(workspaceRepositoryProvider).tripAction(id, action);
      ref.invalidate(toolDataProvider('scheduled-trips'));
      if (mounted) {
        setState(() => _selectedId = null);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(action == 'join'
              ? 'تم إرسال طلب المشاركة للإدارة. لا يُعد إسنادًا نهائيًا.'
              : 'تم سحب طلب المشاركة.'),
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final rows = widget.rows;
    if (rows.isEmpty) return Text(ar
        ? 'لا توجد رحلات مجدولة متاحة حاليًا. اسحب للأسفل للتحقق مجددًا.'
        : 'No scheduled trips available. Pull down to check again.');
    final selected = rows.where((r) =>
        (recordMap(r['trip'])['id'] ?? r['id']) == _selectedId).firstOrNull;
    final action = selected == null ? null :
        participationAction(recordMap(selected['participation'])['status']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(ar
            ? 'اختر رحلة من الجدول. طلب المشاركة يتطلب اعتماد الإدارة قبل استلام شحنات العملاء.'
            : 'Choose a trip. A participation request requires approval before customer shipments are assigned.'),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            showCheckboxColumn: true,
            columns: [
              DataColumn(label: Text(ar ? 'الانطلاق' : 'Departure')),
              DataColumn(label: Text(ar ? 'الوجهة' : 'Destination')),
              DataColumn(label: Text(ar ? 'الحجوزات' : 'Booked')),
              DataColumn(label: Text(ar ? 'المجهزة' : 'Prepared')),
              DataColumn(label: Text(ar ? 'إسناد' : 'Assignment')),
              DataColumn(label: Text(ar ? 'طلب المشاركة' : 'Participation')),
            ],
            rows: [
              for (final raw in rows)
                _row(raw, ar),
            ],
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: action == null || _busy ? null : _submit,
          icon: _busy ? const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(action == 'withdraw'
                  ? Icons.event_busy_outlined : Icons.check_circle_outline),
          label: Text(action == 'withdraw'
              ? (ar ? 'سحب طلب المشاركة المحدد' : 'Withdraw selected request')
              : (ar ? 'طلب المشاركة في الرحلة المحددة' : 'Request selected trip')),
        ),
        Text(ar
            ? 'لا تظهر الشحنة في قائمة مهامك إلا بعد تجهيز التاجر وإسناد الرحلة إليك.'
            : 'A shipment appears in your tasks only after merchant preparation and driver assignment.',
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  DataRow _row(Map<String, dynamic> entry, bool ar) {
    final trip = recordMap(entry['trip']).isNotEmpty
        ? recordMap(entry['trip']) : entry;
    final id = int.tryParse('${trip['id'] ?? ''}');
    final status = statusKey(recordMap(entry['participation'])['status']);
    final action = participationAction(status);
    final selectable = id != null &&
        action != null && !(action == 'join' && trip['driverId'] != null);
    return DataRow(
      selected: selectable && id == _selectedId,
      onSelectChanged: !selectable ? null : (value) =>
          setState(() => _selectedId = value == true ? id : null),
      cells: [
        DataCell(Text('${trip['plannedDepartureAt'] ?? '—'}')),
        DataCell(Text('${trip['dropoffName'] ?? trip['name'] ?? '—'}')),
        DataCell(Text('${entry['bookedOrdersCount'] ?? 0}')),
        DataCell(Text('${entry['preparedShipmentsCount'] ?? 0}')),
        DataCell(Text(trip['driverId'] == null
            ? (ar ? 'بانتظار السائق' : 'Unassigned')
            : (ar ? 'مسندة' : 'Assigned'))),
        DataCell(Text(switch (status) {
          '1' || 'approved' => ar ? 'مقبول' : 'Approved',
          '0' || 'requested' => ar ? 'قيد المراجعة' : 'Requested',
          '3' || 'withdrawn' => ar ? 'مسحوب' : 'Withdrawn',
          '2' || 'rejected' => ar ? 'مرفوض' : 'Rejected',
          _ => ar ? 'لم تطلب المشاركة' : 'Not requested',
        })),
      ],
    );
  }
}

class DriverAvailabilityTable extends ConsumerWidget {
  const DriverAvailabilityTable({required this.rows, super.key});
  final List<Map<String, dynamic>> rows;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final days = ar
        ? const ['الأحد','الاثنين','الثلاثاء','الأربعاء','الخميس','الجمعة','السبت']
        : const ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
    if (rows.isEmpty) return Text(ar
        ? 'لم تُضف ساعات توفر أسبوعية بعد.'
        : 'No weekly availability windows yet.');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text(ar ? 'اليوم' : 'Day')),
          DataColumn(label: Text(ar ? 'من' : 'From')),
          DataColumn(label: Text(ar ? 'إلى' : 'Until')),
          DataColumn(label: Text(ar ? 'الحالة' : 'Status')),
          DataColumn(label: Text(ar ? 'حذف' : 'Delete')),
        ],
        rows: [
          for (final r in rows)
            DataRow(cells: [
              DataCell(Text(days[(int.tryParse('${r['dayOfWeek']}') ?? 0).clamp(0,6).toInt()])),
              DataCell(Text('${r['startTime'] ?? '—'}')),
              DataCell(Text('${r['endTime'] ?? '—'}')),
              DataCell(Icon(r['isActive'] == true ? Icons.check_circle :
                  Icons.pause_circle_outline)),
              DataCell(IconButton(
                tooltip: ar ? 'حذف الفترة' : 'Delete window',
                icon: const Icon(Icons.delete_outline),
                onPressed: r['id'] is! num ? null : () async {
                  await ref.read(workspaceRepositoryProvider)
                      .deleteWindow((r['id'] as num).toInt());
                  ref.invalidate(toolDataProvider('availability'));
                },
              )),
            ]),
        ],
      ),
    );
  }
}
