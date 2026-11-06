import 'package:mobile/features/dashboard/domain/entities/category_breakdown_item.dart';
import 'package:mobile/features/transactions/domain/entities/transaction_entity.dart';
import 'monthly_trend_item.dart';
import 'period_filter.dart';

class FinancialReport {
  final PeriodFilter period;
  final double totalIncome;
  final double totalExpense;
  final double netBalance;
  final double savingsRate; // Percentage e.g. 25.5%
  final List<CategoryBreakdownItem> categoryBreakdown;
  final List<MonthlyTrendItem> monthlyTrends;
  final List<TransactionEntity> transactions;

  const FinancialReport({
    required this.period,
    required this.totalIncome,
    required this.totalExpense,
    required this.netBalance,
    required this.savingsRate,
    required this.categoryBreakdown,
    required this.monthlyTrends,
    required this.transactions,
  });

  bool get hasTransactions => transactions.isNotEmpty;
  bool get isSurplus => netBalance >= 0;

  factory FinancialReport.empty(PeriodFilter period) {
    return FinancialReport(
      period: period,
      totalIncome: 0.0,
      totalExpense: 0.0,
      netBalance: 0.0,
      savingsRate: 0.0,
      categoryBreakdown: const [],
      monthlyTrends: const [],
      transactions: const [],
    );
  }
}
