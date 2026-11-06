class MonthlyTrendItem {
  final int year;
  final int month;
  final String monthLabel; // e.g. "Jun", "Jul", "Agt"
  final double income;
  final double expense;

  const MonthlyTrendItem({
    required this.year,
    required this.month,
    required this.monthLabel,
    required this.income,
    required this.expense,
  });

  double get net => income - expense;
}
