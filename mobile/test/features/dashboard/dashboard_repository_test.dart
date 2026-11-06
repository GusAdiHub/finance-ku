import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/categories/data/datasources/category_local_datasource.dart';
import 'package:mobile/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:mobile/features/transactions/data/datasources/transaction_local_datasource.dart';

void main() {
  group('DashboardRepository Tests (Local Aggregations)', () {
    late TransactionLocalDataSource txLocal;
    late CategoryLocalDataSource catLocal;
    late DashboardRepositoryImpl repository;

    setUp(() {
      txLocal = TransactionLocalDataSourceImpl();
      catLocal = CategoryLocalDataSourceImpl();
      repository = DashboardRepositoryImpl(
        transactionLocal: txLocal,
        categoryLocal: catLocal,
      );
    });

    test('getDashboardData returns empty data when no transactions exist', () async {
      final data = await repository.getDashboardData();

      expect(data.hasTransactions, isFalse);
      expect(data.totalIncome, 0.0);
      expect(data.totalExpense, 0.0);
      expect(data.netBalance, 0.0);
      expect(data.recentTransactions, isEmpty);
      expect(data.expenseBreakdown, isEmpty);
    });

    test('getDashboardData aggregates income, expense, and net balance correctly', () async {
      final now = DateTime.now();

      // Income 1: 5.000.000
      await txLocal.insertTransaction(
        type: 'income',
        amount: 5000000.0,
        categoryId: 'cat-inc-1',
        categoryName: 'Gaji Pokok',
        transactionDate: now,
        userId: 'user-001',
      );

      // Expense 1: 200.000 (Makanan)
      await txLocal.insertTransaction(
        type: 'expense',
        amount: 200000.0,
        categoryId: 'cat-exp-1',
        categoryName: 'Makanan & Minuman',
        transactionDate: now,
        userId: 'user-001',
      );

      // Expense 2: 300.000 (Makanan)
      await txLocal.insertTransaction(
        type: 'expense',
        amount: 300000.0,
        categoryId: 'cat-exp-1',
        categoryName: 'Makanan & Minuman',
        transactionDate: now,
        userId: 'user-001',
      );

      // Expense 3: 500.000 (Transportasi)
      await txLocal.insertTransaction(
        type: 'expense',
        amount: 500000.0,
        categoryId: 'cat-exp-2',
        categoryName: 'Transportasi',
        transactionDate: now,
        userId: 'user-001',
      );

      final data = await repository.getDashboardData();

      expect(data.hasTransactions, isTrue);
      expect(data.totalIncome, 5000000.0);
      expect(data.totalExpense, 1000000.0);
      expect(data.netBalance, 4000000.0);
      expect(data.isNetPositive, isTrue);

      // Expense breakdown verification
      expect(data.expenseBreakdown.length, 2);
      // Both Makanan (500k) and Transportasi (500k) = 50% each
      expect(data.expenseBreakdown.first.percentage, 50.0);
      expect(data.expenseBreakdown.last.percentage, 50.0);
    });

    test('recentTransactions returns at most 5 items ordered by date descending', () async {
      final baseDate = DateTime(2026, 11, 1);

      for (int i = 1; i <= 7; i++) {
        await txLocal.insertTransaction(
          type: 'expense',
          amount: i * 10000.0,
          categoryId: 'cat-1',
          transactionDate: baseDate.add(Duration(days: i)),
          description: 'Tx $i',
          userId: 'user-001',
        );
      }

      final data = await repository.getDashboardData();

      expect(data.totalTransactionCount, 7);
      expect(data.recentTransactions.length, 5);
      // Most recent should be Tx 7 (Nov 8)
      expect(data.recentTransactions.first.description, 'Tx 7');
      expect(data.recentTransactions.last.description, 'Tx 3');
    });
  });
}
