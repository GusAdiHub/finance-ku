import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/reports/data/repositories/report_repository_impl.dart';
import 'package:mobile/features/reports/domain/entities/period_filter.dart';
import 'package:mobile/features/transactions/data/datasources/transaction_local_datasource.dart';

void main() {
  group('ReportRepository Tests', () {
    late TransactionLocalDataSource txLocal;
    late ReportRepositoryImpl repository;

    setUp(() {
      txLocal = TransactionLocalDataSourceImpl();
      repository = ReportRepositoryImpl(transactionLocal: txLocal);
    });

    test('getReport returns empty report when no transactions match period', () async {
      final period = PeriodFilter.forMonth(2026, 11);
      final report = await repository.getReport(period);

      expect(report.hasTransactions, isFalse);
      expect(report.totalIncome, 0.0);
      expect(report.totalExpense, 0.0);
      expect(report.netBalance, 0.0);
      expect(report.savingsRate, 0.0);
      expect(report.transactions, isEmpty);
    });

    test('getReport filters transactions strictly within the selected month', () async {
      final novPeriod = PeriodFilter.forMonth(2026, 11);

      // November Tx
      await txLocal.insertTransaction(
        type: 'income',
        amount: 10000000.0,
        categoryId: 'cat-inc',
        transactionDate: DateTime(2026, 11, 5),
        description: 'Gaji November',
        userId: 'user-001',
      );
      await txLocal.insertTransaction(
        type: 'expense',
        amount: 3000000.0,
        categoryId: 'cat-exp',
        transactionDate: DateTime(2026, 11, 10),
        description: 'Belanja November',
        userId: 'user-001',
      );

      // October Tx (out of range)
      await txLocal.insertTransaction(
        type: 'income',
        amount: 8000000.0,
        categoryId: 'cat-inc',
        transactionDate: DateTime(2026, 10, 25),
        description: 'Gaji Oktober',
        userId: 'user-001',
      );

      final report = await repository.getReport(novPeriod);

      expect(report.transactions.length, 2);
      expect(report.totalIncome, 10000000.0);
      expect(report.totalExpense, 3000000.0);
      expect(report.netBalance, 7000000.0);
      expect(report.isSurplus, isTrue);

      // Savings Rate: (10M - 3M) / 10M * 100 = 70.0%
      expect(report.savingsRate, 70.0);
    });

    test('monthlyTrends computes last 6 months aggregated data', () async {
      final novPeriod = PeriodFilter.forMonth(2026, 11);

      await txLocal.insertTransaction(
        type: 'income',
        amount: 10000000.0,
        categoryId: 'cat-inc',
        transactionDate: DateTime(2026, 11, 1),
        userId: 'user-001',
      );
      await txLocal.insertTransaction(
        type: 'expense',
        amount: 4000000.0,
        categoryId: 'cat-exp',
        transactionDate: DateTime(2026, 10, 15),
        userId: 'user-001',
      );

      final report = await repository.getReport(novPeriod);

      expect(report.monthlyTrends.length, 6);
      final novTrend = report.monthlyTrends.last;
      expect(novTrend.month, 11);
      expect(novTrend.income, 10000000.0);
      expect(novTrend.expense, 0.0);

      final octTrend = report.monthlyTrends[4];
      expect(octTrend.month, 10);
      expect(octTrend.income, 0.0);
      expect(octTrend.expense, 4000000.0);
    });
  });
}
