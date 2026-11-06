import '../entities/financial_report.dart';
import '../entities/period_filter.dart';

abstract class ReportRepository {
  /// Generate a comprehensive financial report for a specific period filter
  Future<FinancialReport> getReport(PeriodFilter period);

  /// Observe the financial report reactively for a specific period filter
  Stream<FinancialReport> watchReport(PeriodFilter period);
}
