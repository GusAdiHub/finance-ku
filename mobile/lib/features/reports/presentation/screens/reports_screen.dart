import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../dashboard/presentation/widgets/category_distribution_bar.dart';
import '../../../sync/presentation/widgets/sync_status_indicator.dart';
import '../../../transactions/presentation/widgets/transaction_item_card.dart';
import '../controllers/reports_controller.dart';
import '../widgets/monthly_trend_chart.dart';
import '../widgets/period_selector_widget.dart';
import '../widgets/savings_rate_card.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportsControllerProvider);
    final report = state.report;
    final selectedTab = state.selectedTab;

    // Filter transactions by tab
    final transactions = report.transactions.where((t) {
      if (selectedTab == 'expense') return t.type == 'expense';
      if (selectedTab == 'income') return t.type == 'income';
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Laporan Finansial'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: SyncStatusIndicator(compact: true),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(reportsControllerProvider.notifier).refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Period Selector & Preset Chips
                PeriodSelectorWidget(
                  period: state.period,
                  onPrevious: () =>
                      ref.read(reportsControllerProvider.notifier).previousPeriod(),
                  onNext: () =>
                      ref.read(reportsControllerProvider.notifier).nextPeriod(),
                  onSelectPeriod: (p) =>
                      ref.read(reportsControllerProvider.notifier).setPeriod(p),
                ),
                const SizedBox(height: 16),

                if (state.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.expenseLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.expense, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.expense, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.errorMessage!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.expense,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Financial Overview Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderDark, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.borderDark,
                        offset: Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Net Balance Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Sisa Bersih Periode Ini',
                              style: AppTextStyles.labelMedium),
                          Text(
                            CurrencyFormatter.formatRupiah(report.netBalance),
                            style: AppTextStyles.headingMedium.copyWith(
                              color: report.isSurplus
                                  ? AppColors.income
                                  : AppColors.expense,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),

                      // Income & Expense details
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _MetricMini(
                            label: 'Total Pemasukan',
                            amount: report.totalIncome,
                            color: AppColors.income,
                            isIncome: true,
                          ),
                          _MetricMini(
                            label: 'Total Pengeluaran',
                            amount: report.totalExpense,
                            color: AppColors.expense,
                            isIncome: false,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Savings Rate Card
                SavingsRateCard(
                  savingsRate: report.savingsRate,
                  totalIncome: report.totalIncome,
                  totalExpense: report.totalExpense,
                ),
                const SizedBox(height: 16),

                // Category Breakdown
                CategoryDistributionBar(breakdown: report.categoryBreakdown),
                const SizedBox(height: 16),

                // 6-Month Trend Chart
                MonthlyTrendChart(trends: report.monthlyTrends),
                const SizedBox(height: 20),

                // Transactions List Section Header & Tabs
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Rincian Transaksi',
                        style: AppTextStyles.headingSmall),
                    Text(
                      '${transactions.length} Transaksi',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Tab Filter Chips (Semua, Pengeluaran, Pemasukan)
                Row(
                  children: [
                    _FilterTab(
                      label: 'Semua',
                      isSelected: selectedTab == 'all',
                      onTap: () => ref
                          .read(reportsControllerProvider.notifier)
                          .setSelectedTab('all'),
                    ),
                    const SizedBox(width: 8),
                    _FilterTab(
                      label: 'Pengeluaran',
                      isSelected: selectedTab == 'expense',
                      color: AppColors.expense,
                      onTap: () => ref
                          .read(reportsControllerProvider.notifier)
                          .setSelectedTab('expense'),
                    ),
                    const SizedBox(width: 8),
                    _FilterTab(
                      label: 'Pemasukan',
                      isSelected: selectedTab == 'income',
                      color: AppColors.income,
                      onTap: () => ref
                          .read(reportsControllerProvider.notifier)
                          .setSelectedTab('income'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (transactions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderDark, width: 1.5),
                    ),
                    child: Column(
                      children: const [
                        Icon(Icons.inbox_rounded,
                            size: 32, color: AppColors.textSecondary),
                        SizedBox(height: 8),
                        Text(
                          'Tidak ada transaksi pada periode ini',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  )
                else
                  ...transactions.map((tx) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: TransactionItemCard(
                        transaction: tx,
                        onTap: () => context.push(
                          '/app/transactions/detail',
                          extra: tx,
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricMini extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool isIncome;

  const _MetricMini({
    required this.label,
    required this.amount,
    required this.color,
    required this.isIncome,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          isIncome ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        const SizedBox(height: 2),
        Text(
          '${isIncome ? '+' : '-'} ${CurrencyFormatter.formatRupiah(amount)}',
          style: AppTextStyles.labelMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.isSelected,
    this.color = AppColors.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceVariant : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : AppColors.borderDark,
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
