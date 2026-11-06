import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../categories/data/datasources/category_local_datasource.dart';
import '../../../categories/data/repositories/category_repository_impl.dart';
import '../../../transactions/data/datasources/transaction_local_datasource.dart';
import '../../../transactions/data/repositories/transaction_repository_impl.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../domain/entities/category_breakdown_item.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/repositories/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final transactionLocal = ref.watch(transactionLocalDataSourceProvider);
  final categoryLocal = ref.watch(categoryLocalDataSourceProvider);
  return DashboardRepositoryImpl(
    transactionLocal: transactionLocal,
    categoryLocal: categoryLocal,
  );
});

class DashboardRepositoryImpl implements DashboardRepository {
  final TransactionLocalDataSource _transactionLocal;
  final CategoryLocalDataSource _categoryLocal;

  DashboardRepositoryImpl({
    required TransactionLocalDataSource transactionLocal,
    required CategoryLocalDataSource categoryLocal,
  })  : _transactionLocal = transactionLocal,
        _categoryLocal = categoryLocal;

  @override
  Future<DashboardData> getDashboardData() async {
    final transactions = await _transactionLocal.getTransactions();
    return _computeDashboardData(transactions);
  }

  @override
  Stream<DashboardData> watchDashboardData() {
    return _transactionLocal.watchTransactions().asyncMap((transactions) async {
      return _computeDashboardData(transactions);
    });
  }

  Future<DashboardData> _computeDashboardData(
    List<TransactionEntity> transactions,
  ) async {
    if (transactions.isEmpty) {
      return DashboardData.empty();
    }

    double totalIncome = 0.0;
    double totalExpense = 0.0;
    final Map<String, _CatAggregate> expenseCatMap = {};

    for (final tx in transactions) {
      if (tx.type == 'income') {
        totalIncome += tx.amount;
      } else if (tx.type == 'expense') {
        totalExpense += tx.amount;

        final existing = expenseCatMap[tx.categoryId];
        if (existing != null) {
          existing.amount += tx.amount;
          existing.count += 1;
        } else {
          expenseCatMap[tx.categoryId] = _CatAggregate(
            categoryId: tx.categoryId,
            name: tx.categoryName ?? 'Kategori',
            icon: tx.categoryIcon,
            color: tx.categoryColor,
            amount: tx.amount,
            count: 1,
          );
        }
      }
    }

    // Sort recent transactions by date descending
    final sortedTx = List<TransactionEntity>.from(transactions)
      ..sort((a, b) {
        final cmp = b.transactionDate.compareTo(a.transactionDate);
        if (cmp != 0) return cmp;
        return b.clientUpdatedAt.compareTo(a.clientUpdatedAt);
      });

    final recent = sortedTx.take(5).toList();

    // Compute category breakdown with percentage
    final List<CategoryBreakdownItem> breakdown = [];
    if (totalExpense > 0) {
      final sortedAggregates = expenseCatMap.values.toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));

      for (final agg in sortedAggregates) {
        final percentage = (agg.amount / totalExpense) * 100.0;
        breakdown.add(CategoryBreakdownItem(
          categoryId: agg.categoryId,
          categoryName: agg.name,
          categoryIcon: agg.icon,
          categoryColor: agg.color,
          totalAmount: agg.amount,
          transactionCount: agg.count,
          percentage: percentage,
        ));
      }
    }

    return DashboardData(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netBalance: totalIncome - totalExpense,
      recentTransactions: recent,
      expenseBreakdown: breakdown,
      totalTransactionCount: transactions.length,
    );
  }
}

class _CatAggregate {
  final String categoryId;
  final String name;
  final String? icon;
  final String? color;
  double amount;
  int count;

  _CatAggregate({
    required this.categoryId,
    required this.name,
    this.icon,
    this.color,
    required this.amount,
    required this.count,
  });
}
