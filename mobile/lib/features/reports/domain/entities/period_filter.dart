import '../../../../core/utils/date_formatter.dart';

enum PeriodType {
  month,
  day,
  custom,
}

class PeriodFilter {
  final PeriodType type;
  final DateTime startDate;
  final DateTime endDate;
  final String label;

  const PeriodFilter({
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.label,
  });

  /// Factory for the current month
  factory PeriodFilter.thisMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    final end = nextMonth.subtract(const Duration(milliseconds: 1));
    final label = DateFormatter.formatMonthYear(now);

    return PeriodFilter(
      type: PeriodType.month,
      startDate: start,
      endDate: end,
      label: label,
    );
  }

  /// Factory for a specific month
  factory PeriodFilter.forMonth(int year, int month) {
    final start = DateTime(year, month, 1);
    final nextMonth = DateTime(year, month + 1, 1);
    final end = nextMonth.subtract(const Duration(milliseconds: 1));
    final label = DateFormatter.formatMonthYear(start);

    return PeriodFilter(
      type: PeriodType.month,
      startDate: start,
      endDate: end,
      label: label,
    );
  }

  /// Factory for today
  factory PeriodFilter.today() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    final label = 'Hari Ini (${DateFormatter.formatDate(now)})';

    return PeriodFilter(
      type: PeriodType.day,
      startDate: start,
      endDate: end,
      label: label,
    );
  }

  /// Factory for yesterday
  factory PeriodFilter.yesterday() {
    final yest = DateTime.now().subtract(const Duration(days: 1));
    final start = DateTime(yest.year, yest.month, yest.day);
    final end = DateTime(yest.year, yest.month, yest.day, 23, 59, 59, 999);
    final label = 'Kemarin (${DateFormatter.formatDate(yest)})';

    return PeriodFilter(
      type: PeriodType.day,
      startDate: start,
      endDate: end,
      label: label,
    );
  }

  /// Navigate to previous period
  PeriodFilter previous() {
    if (type == PeriodType.month) {
      final prevMonthDate = DateTime(startDate.year, startDate.month - 1, 1);
      return PeriodFilter.forMonth(prevMonthDate.year, prevMonthDate.month);
    } else if (type == PeriodType.day) {
      final prevDay = startDate.subtract(const Duration(days: 1));
      final start = DateTime(prevDay.year, prevDay.month, prevDay.day);
      final end = DateTime(prevDay.year, prevDay.month, prevDay.day, 23, 59, 59, 999);
      return PeriodFilter(
        type: PeriodType.day,
        startDate: start,
        endDate: end,
        label: DateFormatter.formatFullDate(start),
      );
    }
    // For custom, shift back by window duration
    final duration = endDate.difference(startDate);
    final newStart = startDate.subtract(duration);
    final newEnd = endDate.subtract(duration);
    return PeriodFilter(
      type: PeriodType.custom,
      startDate: newStart,
      endDate: newEnd,
      label: '${DateFormatter.formatDayMonth(newStart)} - ${DateFormatter.formatDate(newEnd)}',
    );
  }

  /// Navigate to next period
  PeriodFilter next() {
    if (type == PeriodType.month) {
      final nextMonthDate = DateTime(startDate.year, startDate.month + 1, 1);
      return PeriodFilter.forMonth(nextMonthDate.year, nextMonthDate.month);
    } else if (type == PeriodType.day) {
      final nextDay = startDate.add(const Duration(days: 1));
      final start = DateTime(nextDay.year, nextDay.month, nextDay.day);
      final end = DateTime(nextDay.year, nextDay.month, nextDay.day, 23, 59, 59, 999);
      return PeriodFilter(
        type: PeriodType.day,
        startDate: start,
        endDate: end,
        label: DateFormatter.formatFullDate(start),
      );
    }
    final duration = endDate.difference(startDate);
    final newStart = startDate.add(duration);
    final newEnd = endDate.add(duration);
    return PeriodFilter(
      type: PeriodType.custom,
      startDate: newStart,
      endDate: newEnd,
      label: '${DateFormatter.formatDayMonth(newStart)} - ${DateFormatter.formatDate(newEnd)}',
    );
  }
}
