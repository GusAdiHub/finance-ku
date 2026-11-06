import 'package:intl/intl.dart';

/// Utility for Indonesian Date and Time Formatting
class DateFormatter {
  DateFormatter._();

  static const List<String> _monthsIndonesian = [
    '',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const List<String> _shortMonthsIndonesian = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  /// Standard readable date in Indonesian
  /// Example: 6 Nov 2026
  static String formatDate(DateTime date) {
    final local = date.toLocal();
    final month = _shortMonthsIndonesian[local.month];
    return '${local.day} $month ${local.year}';
  }

  /// Day and Short Month
  /// Example: 6 Nov
  static String formatDayMonth(DateTime date) {
    final local = date.toLocal();
    final month = _shortMonthsIndonesian[local.month];
    return '${local.day} $month';
  }

  /// Short Month Name
  /// Example: Nov
  static String formatShortMonth(DateTime date) {
    final local = date.toLocal();
    return _shortMonthsIndonesian[local.month];
  }

  /// Full date with month name
  /// Example: 6 November 2026
  static String formatFullDate(DateTime date) {
    final local = date.toLocal();
    final month = _monthsIndonesian[local.month];
    return '${local.day} $month ${local.year}';
  }

  /// Date and Time
  /// Example: 6 Nov 2026, 14:30
  static String formatDateTime(DateTime date) {
    final local = date.toLocal();
    final month = _shortMonthsIndonesian[local.month];
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.day} $month ${local.year}, $hour:$minute';
  }

  /// Month and Year
  /// Example: November 2026
  static String formatMonthYear(DateTime date) {
    final local = date.toLocal();
    final month = _monthsIndonesian[local.month];
    return '$month ${local.year}';
  }

  /// Time only (24-hour format)
  /// Example: 14:30
  static String formatTime(DateTime date) {
    final local = date.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Converts DateTime to ISO 8601 UTC String required by FastAPI PostgreSQL
  /// Example: "2026-11-06T14:30:00.000Z"
  static String toIsoUtcString(DateTime date) {
    return date.toUtc().toIso8601String();
  }

  /// Parses an ISO 8601 UTC String safely
  static DateTime? parseIsoUtcString(String? isoString) {
    if (isoString == null || isoString.isEmpty) return null;
    return DateTime.tryParse(isoString)?.toUtc();
  }
}
