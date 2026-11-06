import 'package:mobile/features/transactions/domain/entities/transaction_entity.dart';
import 'category_breakdown_item.dart';

class DashboardData {
  final double totalIncome;
  final double totalExpense;
  final double netBalance;
  final List<TransactionEntity> recentTransactions;
  final List<CategoryBreakdownItem> expenseBreakdown;
  final int totalTransactionCount;

  const DashboardData({
    this.totalIncome = 0.0,
    this.totalExpense = 0.0,
    this.netBalance = 0.0,
    this.recentTransactions = const [],
    this.expenseBreakdown = const [],
    this.totalTransactionCount = 0,
  });

  bool get hasTransactions => totalTransactionCount > 0;
  bool get hasExpenses => totalExpense > 0;
  bool get isNetPositive => netBalance >= 0;

  factory DashboardData.empty() => const DashboardData();
}
