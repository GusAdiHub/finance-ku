import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/report_repository_impl.dart';
import '../../domain/entities/financial_report.dart';
import '../../domain/entities/period_filter.dart';
import '../../domain/repositories/report_repository.dart';

class ReportsState {
  final FinancialReport report;
  final PeriodFilter period;
  final String selectedTab; // 'all' | 'expense' | 'income'
  final bool isLoading;
  final String? errorMessage;

  const ReportsState({
    required this.report,
    required this.period,
    this.selectedTab = 'all',
    this.isLoading = false,
    this.errorMessage,
  });

  ReportsState copyWith({
    FinancialReport? report,
    PeriodFilter? period,
    String? selectedTab,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ReportsState(
      report: report ?? this.report,
      period: period ?? this.period,
      selectedTab: selectedTab ?? this.selectedTab,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final reportsControllerProvider =
    NotifierProvider<ReportsController, ReportsState>(
  ReportsController.new,
);

class ReportsController extends Notifier<ReportsState> {
  late final ReportRepository _repository;
  StreamSubscription<FinancialReport>? _subscription;

  @override
  ReportsState build() {
    _repository = ref.watch(reportRepositoryProvider);
    final initialPeriod = PeriodFilter.thisMonth();
    ref.onDispose(() {
      _subscription?.cancel();
    });
    _subscribeToPeriod(initialPeriod);
    return ReportsState(
      report: FinancialReport.empty(initialPeriod),
      period: initialPeriod,
      isLoading: true,
    );
  }

  void _subscribeToPeriod(PeriodFilter period) {
    _subscription?.cancel();
    _subscription = _repository.watchReport(period).listen(
      (report) {
        state = state.copyWith(
          report: report,
          period: period,
          isLoading: false,
        );
      },
      onError: (err) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: err.toString(),
        );
      },
    );
  }

  void setPeriod(PeriodFilter period) {
    state = state.copyWith(period: period, isLoading: true);
    _subscribeToPeriod(period);
  }

  void nextPeriod() {
    setPeriod(state.period.next());
  }

  void previousPeriod() {
    setPeriod(state.period.previous());
  }

  void setSelectedTab(String tab) {
    state = state.copyWith(selectedTab: tab);
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    try {
      final fresh = await _repository.getReport(state.period);
      state = state.copyWith(report: fresh, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}
