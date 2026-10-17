import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazraa_driver/core/network/providers.dart';

/// Converts backend TimeSpan and DayOfWeek values without guessing.
class AvailabilityWindow {
  const AvailabilityWindow({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isActive,
  });

  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final bool isActive;

  static const dayNames = [
    'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء',
    'الخميس', 'الجمعة', 'السبت',
  ];
  static const englishDays = [
    'sunday', 'monday', 'tuesday', 'wednesday',
    'thursday', 'friday', 'saturday',
  ];

  static int parseDay(Object? raw) {
    final day = int.tryParse(raw?.toString() ?? '');
    if (day != null && day >= 0 && day <= 6) return day;
    final index = englishDays.indexOf(raw?.toString().toLowerCase() ?? '');
    if (index >= 0) return index;
    throw const FormatException('قيمة يوم الأسبوع غير متوقعة من السيرفر.');
  }

  static String parseClock(Object? raw) {
    final value = raw?.toString() ?? '';
    // C# TimeSpan is serialized as HH:mm:ss or HH:mm:ss.fffffff.
    final match = RegExp(r'^(\d{2}):(\d{2}):(\d{2})(?:\.\d{1,7})?$')
        .firstMatch(value);
    if (match == null) {
      throw const FormatException('صيغة وقت التوفر من السيرفر غير مفهومة.');
    }
    final hh = int.parse(match.group(1)!);
    final mm = int.parse(match.group(2)!);
    final ss = int.parse(match.group(3)!);
    if (hh >= 24 || mm >= 60 || ss >= 60) {
      throw const FormatException('وقت التوفر خارج النطاق المسموح.');
    }
    return value;
  }

  factory AvailabilityWindow.fromServer(Map<String, dynamic> row) {
    if (row['isActive'] is! bool) {
      throw const FormatException('حقل isActive مفقود من جدول التوفر.');
    }
    return AvailabilityWindow(
      dayOfWeek: parseDay(row['dayOfWeek']),
      startTime: parseClock(row['startTime']),
      endTime: parseClock(row['endTime']),
      isActive: row['isActive'] as bool,
    );
  }

  Map<String, dynamic> toServer() => {
        'dayOfWeek': dayOfWeek,
        'startTime': startTime,
        'endTime': endTime,
        'isActive': isActive,
      };

  String get label =>
      '${dayNames[dayOfWeek]} · ${startTime.substring(0, 5)} – '
      '${endTime.substring(0, 5)}';
}

class WeeklyAvailabilityEditor extends ConsumerStatefulWidget {
  const WeeklyAvailabilityEditor({required this.onSaved, super.key});

  final VoidCallback onSaved;

  @override
  ConsumerState<WeeklyAvailabilityEditor> createState() =>
      _WeeklyAvailabilityEditorState();
}

class _WeeklyAvailabilityEditorState
    extends ConsumerState<WeeklyAvailabilityEditor> {
  bool _saving = false;

  Future<void> _showEditor() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final api = ref.read(driverApiProvider);
      final raw = await api.getDriverAvailability();
      final windows = raw.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('صف جدول التوفر غير صالح.');
        }
        return AvailabilityWindow.fromServer(item);
      }).toList();
      if (!mounted) return;

      final chosen = await showDialog<int>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('جدول التوفر الأسبوعي'),
          children: [
            for (var i = 0; i < windows.length; i++)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('${windows[i].label} '
                      '${windows[i].isActive ? '· نشطة' : '· متوقفة'}'),
                ),
              ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, -1),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('＋ إضافة نافذة توفر'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      );
      if (chosen == null || !mounted) return;
      final existing = chosen >= 0 ? windows[chosen] : null;
      final updated = await _askWindow(existing);
      if (updated == null || !mounted) return;
      if (chosen == -1) {
        windows.add(updated);
      } else {
        windows[chosen] = updated;
      }
      // The server's PUT replaces all windows, so only submit a full,
      // losslessly parsed list after explicit confirmation.
      final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('تأكيد حفظ جدول التوفر'),
              content: Text(
                'سيُحفظ الجدول الكامل (${windows.length} نافذة)، '
                'بما يشمل جميع النوافذ السابقة. هل تريد المتابعة؟',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('حفظ في السيرفر'),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirmed || !mounted) return;
      await api.updateDriverAvailability(
        windows.map((window) => window.toServer()).toList(),
      );
      if (mounted) {
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ جدول التوفر في السيرفر.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<AvailabilityWindow?> _askWindow(AvailabilityWindow? current) async {
    var day = current?.dayOfWeek ?? 0;
    var active = current?.isActive ?? true;
    var start = current == null
        ? const TimeOfDay(hour: 8, minute: 0)
        : TimeOfDay(
            hour: int.parse(current.startTime.substring(0, 2)),
            minute: int.parse(current.startTime.substring(3, 5)),
          );
    var end = current == null
        ? const TimeOfDay(hour: 17, minute: 0)
        : TimeOfDay(
            hour: int.parse(current.endTime.substring(0, 2)),
            minute: int.parse(current.endTime.substring(3, 5)),
          );
    String clock(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

    return showDialog<AvailabilityWindow>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: Text(current == null ? 'نافذة توفر جديدة' : 'تعديل نافذة التوفر'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: day,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'يوم الأسبوع'),
                items: [
                  for (var i = 0; i < 7; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text(AvailabilityWindow.dayNames[i]),
                    ),
                ],
                onChanged: (value) => update(() => day = value ?? day),
              ),
              ListTile(
                title: const Text('من الساعة'),
                trailing: Text(start.format(ctx)),
                onTap: () async {
                  final selected = await showTimePicker(
                    context: ctx,
                    initialTime: start,
                    builder: (ctx, child) => MediaQuery(
                      data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
                      child: child!,
                    ),
                  );
                  if (selected != null) update(() => start = selected);
                },
              ),
              ListTile(
                title: const Text('إلى الساعة'),
                trailing: Text(end.format(ctx)),
                onTap: () async {
                  final selected = await showTimePicker(
                    context: ctx,
                    initialTime: end,
                    builder: (ctx, child) => MediaQuery(
                      data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
                      child: child!,
                    ),
                  );
                  if (selected != null) update(() => end = selected);
                },
              ),
              SwitchListTile(
                title: const Text('متاح للرحلات'),
                value: active,
                onChanged: (value) => update(() => active = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final from = start.hour * 60 + start.minute;
                final to = end.hour * 60 + end.minute;
                if (to <= from) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('وقت النهاية يجب أن يكون بعد البداية.'),
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx, AvailabilityWindow(
                  dayOfWeek: day,
                  startTime: clock(start),
                  endTime: clock(end),
                  isActive: active,
                ));
              },
              child: const Text('متابعة'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        key: const Key('editWeeklyAvailabilityButton'),
        onPressed: _saving ? null : _showEditor,
        icon: const Icon(Icons.edit_calendar_rounded),
        label: const Text('تحرير جدول التوفر'),
      );
}
