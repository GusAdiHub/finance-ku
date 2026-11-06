import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../transactions/data/datasources/transaction_local_datasource.dart';
import '../../../transactions/data/repositories/transaction_repository_impl.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import 'package:mobile/features/dashboard/domain/entities/category_breakdown_item.dart';
import '../../domain/entities/financial_report.dart';
import '../../domain/entities/monthly_trend_item.dart';
import '../../domain/entities/period_filter.dart';
import '../../domain/repositories/report_repository.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final transactionLocal = ref.watch(transactionLocalDataSourceProvider);
  return ReportRepositoryImpl(transactionLocal: transactionLocal);
});

class ReportRepositoryImpl implements ReportRepository {
  final TransactionLocalDataSource _transactionLocal;

  ReportRepositoryImpl({
    required TransactionLocalDataSource transactionLocal,
  }) : _transactionLocal = transactionLocal;

  @override
  Future<FinancialReport> getReport(PeriodFilter period) async {
    final allTransactions = await _transactionLocal.getTransactions();
    return _computeReport(allTransactions, period);
  }

  @override
  Stream<FinancialReport> watchReport(PeriodFilter period) {
    return _transactionLocal.watchTransactions().map((allTransactions) {
      return _computeReport(allTransactions, period);
    });
  }

  FinancialReport _computeReport(
    List<TransactionEntity> allTransactions,
    PeriodFilter period,
  ) {
    // 1. Filter transactions within the selected period window
    final filtered = allTransactions.where((t) {
      return !t.transactionDate.isBefore(period.startDate) &&
          !t.transactionDate.isAfter(period.endDate);
    }).toList();

    double totalIncome = 0.0;
    double totalExpense = 0.0;
    final Map<String, _CatHolder> catMap = {};

    for (final tx in filtered) {
      if (tx.type == 'income') {
        totalIncome += tx.amount;
      } else if (tx.type == 'expense') {
        totalExpense += tx.amount;

        final existing = catMap[tx.categoryId];
        if (existing != null) {
          existing.amount += tx.amount;
          existing.count += 1;
        } else {
          catMap[tx.categoryId] = _CatHolder(
            id: tx.categoryId,
            name: tx.categoryName ?? 'Kategori',
            icon: tx.categoryIcon,
            color: tx.categoryColor,
            amount: tx.amount,
            count: 1,
          );
        }
      }
    }

    // 2. Savings Rate calculation: ((Income - Expense) / Income) * 100
    double savingsRate = 0.0;
    if (totalIncome > 0) {
      savingsRate = ((totalIncome - totalExpense) / totalIncome) * 100.0;
    }

    // 3. Category Breakdown calculation
    final List<CategoryBreakdownItem> breakdown = [];
    if (totalExpense > 0) {
      final sortedCats = catMap.values.toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));

      for (final cat in sortedCats) {
        final percentage = (cat.amount / totalExpense) * 100.0;
        breakdown.add(CategoryBreakdownItem(
          categoryId: cat.id,
          categoryName: cat.name,
          categoryIcon: cat.icon,
          categoryColor: cat.color,
          totalAmount: cat.amount,
          transactionCount: cat.count,
          percentage: percentage,
        ));
      }
    }

    // 4. Monthly Trend calculation (Last 6 calendar months based on period)
    final monthlyTrends = _computeMonthlyTrends(allTransactions, period.endDate);

    // Sort filtered transactions descending by date
    final sortedFiltered = List<TransactionEntity>.from(filtered)
      ..sort((a, b) {
        final cmp = b.transactionDate.compareTo(a.transactionDate);
        if (cmp != 0) return cmp;
        return b.clientUpdatedAt.compareTo(a.clientUpdatedAt);
      });

    return FinancialReport(
      period: period,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netBalance: totalIncome - totalExpense,
      savingsRate: savingsRate,
      categoryBreakdown: breakdown,
      monthlyTrends: monthlyTrends,
      transactions: sortedFiltered,
    );
  }

  List<MonthlyTrendItem> _computeMonthlyTrends(
    List<TransactionEntity> allTransactions,
    DateTime anchorDate,
  ) {
    final List<MonthlyTrendItem> items = [];

    // Last 6 months back from anchorDate
    for (int i = 5; i >= 0; i--) {
      final d = DateTime(anchorDate.year, anchorDate.month - i, 1);
      final next = DateTime(d.year, d.month + 1, 1);
      final monthEnd = next.subtract(const Duration(milliseconds: 1));

      final monthTxs = allTransactions.where((t) {
        return !t.transactionDate.isBefore(d) && !t.transactionDate.isAfter(monthEnd);
      });

      double income = 0.0;
      double expense = 0.0;
      for (final tx in monthTxs) {
        if (tx.type == 'income') {
          income += tx.amount;
        } else if (tx.type == 'expense') {
          expense += tx.amount;
        }
      }

      final label = DateFormatter.formatShortMonth(d);
      items.add(MonthlyTrendItem(
        year: d.year,
        month: d.month,
        monthLabel: label,
        income: income,
        expense: expense,
      ));
    }

    return items;
  }
}

class _CatHolder {
  final String id;
  final String name;
  final String? icon;
  final String? color;
  double amount;
  int count;

  _CatHolder({
    required this.id,
    required this.name,
    this.icon,
    this.color,
    required this.amount,
    required this.count,
  });
}
