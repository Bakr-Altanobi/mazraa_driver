import 'package:intl/intl.dart';

String formatMoney(num value, String currency, {String locale = 'ar'}) {
  final formatter = NumberFormat.currency(
    locale: locale,
    symbol: currency == 'SAR' ? 'ر.س' : currency,
    decimalDigits: value % 1 == 0 ? 0 : 2,
  );
  return formatter.format(value);
}

String formatDistance(double? kilometers, {bool arabic = true}) {
  if (kilometers == null) return arabic ? 'غير متاح' : 'Unavailable';
  if (kilometers < 1) {
    final meters = (kilometers * 1000).round();
    return arabic ? '$meters م' : '$meters m';
  }
  final value = kilometers.toStringAsFixed(kilometers >= 10 ? 0 : 1);
  return arabic ? '$value كم' : '$value km';
}

String formatEta(int? minutes, {bool arabic = true}) {
  if (minutes == null) return arabic ? 'غير متاح' : 'Unavailable';
  if (minutes < 60) return arabic ? '$minutes دقيقة' : '$minutes min';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return arabic ? '$hours س $rest د' : '${hours}h ${rest}m';
}

String formatDateTime(DateTime value, {String locale = 'ar'}) =>
    DateFormat('d MMM، h:mm a', locale).format(value.toLocal());
