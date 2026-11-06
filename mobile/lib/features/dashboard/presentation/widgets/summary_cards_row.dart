import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/dashboard_data.dart';

class SummaryCardsRow extends StatelessWidget {
  final DashboardData data;

  const SummaryCardsRow({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final isNetPositive = data.isNetPositive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hero Net Balance Tile
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDark, width: 2),
            boxShadow: const [
              BoxShadow(
                color: AppColors.borderDark,
                offset: Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Saldo Bersih Saat Ini',
                    style: AppTextStyles.labelMedium,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isNetPositive
                          ? AppColors.incomeLight
                          : AppColors.expenseLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isNetPositive
                            ? AppColors.income
                            : AppColors.expense,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isNetPositive
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          size: 14,
                          color: isNetPositive
                              ? AppColors.income
                              : AppColors.expense,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isNetPositive ? 'Surplus' : 'Defisit',
                          style: TextStyle(
                            color: isNetPositive
                                ? AppColors.income
                                : AppColors.expense,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${data.netBalance < 0 ? '-' : ''}${CurrencyFormatter.formatRupiah(data.netBalance.abs())}',
                style: AppTextStyles.amountLarge.copyWith(
                  color: isNetPositive ? AppColors.textPrimary : AppColors.expense,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 2-Column Income & Expense Row
        Row(
          children: [
            // Total Pemasukan Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.incomeLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.income, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.borderDark,
                      offset: Offset(2.5, 2.5),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.arrow_downward_rounded,
                          size: 16,
                          color: AppColors.income,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Pemasukan',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.income,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      CurrencyFormatter.formatRupiah(data.totalIncome),
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Total Pengeluaran Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.expenseLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.expense, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.borderDark,
                      offset: Offset(2.5, 2.5),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.arrow_upward_rounded,
                          size: 16,
                          color: AppColors.expense,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Pengeluaran',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.expense,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      CurrencyFormatter.formatRupiah(data.totalExpense),
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
