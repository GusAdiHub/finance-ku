import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/text_styles.dart';

class SavingsRateCard extends StatelessWidget {
  final double savingsRate;
  final double totalIncome;
  final double totalExpense;

  const SavingsRateCard({
    super.key,
    required this.savingsRate,
    required this.totalIncome,
    required this.totalExpense,
  });

  @override
  Widget build(BuildContext context) {
    final safeRate = (savingsRate.isNaN || savingsRate.isInfinite) ? 0.0 : savingsRate;
    final clampedRate = safeRate.clamp(0.0, 100.0);
    final isSurplus = totalIncome >= totalExpense;

    String advice;
    Color statusColor;
    if (totalIncome == 0) {
      advice = 'Belum ada data pemasukan pada periode ini.';
      statusColor = AppColors.textSecondary;
    } else if (!isSurplus) {
      advice = 'Defisit: Pengeluaran melebihi total pemasukan periode ini.';
      statusColor = AppColors.expense;
    } else if (savingsRate >= 30) {
      advice = 'Luar biasa! Rasio tabungan Anda sangat sehat (di atas 30%).';
      statusColor = AppColors.income;
    } else if (savingsRate >= 15) {
      advice = 'Bagus! Pertahankan disiplin anggaran untuk mencapai target tabungan.';
      statusColor = AppColors.primary;
    } else {
      advice = 'Tabungan masih tipis. Cek pengeluaran yang bisa dihemat.';
      statusColor = AppColors.warning;
    }

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Rasio Tabungan (Savings Rate)',
                style: AppTextStyles.headingSmall,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isSurplus ? AppColors.incomeLight : AppColors.expenseLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSurplus ? AppColors.income : AppColors.expense,
                    width: 1,
                  ),
                ),
                child: Text(
                  '${safeRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: isSurplus ? AppColors.income : AppColors.expense,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar track
          Container(
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: AppColors.borderDark, width: 1.5),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (clampedRate / 100.0).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isSurplus ? AppColors.warning : AppColors.expense,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Advice / Feedback text
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isSurplus ? Icons.insights_rounded : Icons.warning_amber_rounded,
                size: 16,
                color: statusColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  advice,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
