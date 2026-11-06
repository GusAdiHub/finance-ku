import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/monthly_trend_item.dart';

class MonthlyTrendChart extends StatefulWidget {
  final List<MonthlyTrendItem> trends;

  const MonthlyTrendChart({
    super.key,
    required this.trends,
  });

  @override
  State<MonthlyTrendChart> createState() => _MonthlyTrendChartState();
}

class _MonthlyTrendChartState extends State<MonthlyTrendChart> {
  int? _selectedMonthIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.trends.isEmpty) {
      return const SizedBox.shrink();
    }

    // Determine max value for Y-scale normalization
    double maxVal = 0.0;
    for (final item in widget.trends) {
      maxVal = max(maxVal, max(item.income, item.expense));
    }
    if (maxVal <= 0 || maxVal.isNaN || maxVal.isInfinite) maxVal = 1.0;

    final selected = _selectedMonthIndex != null &&
            _selectedMonthIndex! < widget.trends.length
        ? widget.trends[_selectedMonthIndex!]
        : null;

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
                'Tren Keuangan 6 Bulan',
                style: AppTextStyles.headingSmall,
              ),
              // Legend (Income: Emerald, Expense: Coral)
              Row(
                children: [
                  _LegendIndicator(
                    color: AppColors.income,
                    label: 'Masuk',
                  ),
                  const SizedBox(width: 10),
                  _LegendIndicator(
                    color: AppColors.expense,
                    label: 'Keluar',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bar Chart Canvas Area (Height 150)
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(widget.trends.length, (index) {
                final item = widget.trends[index];
                final incomeHeight = ((item.income / maxVal) * 110).clamp(4.0, 110.0);
                final expenseHeight =
                    ((item.expense / maxVal) * 110).clamp(4.0, 110.0);
                final isFocused = _selectedMonthIndex == index;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMonthIndex = isFocused ? null : index;
                      });
                    },
                    child: Container(
                      color: Colors.transparent, // expand hit-box
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Income Bar
                              Container(
                                width: 10,
                                height: item.income > 0 ? incomeHeight : 4,
                                decoration: BoxDecoration(
                                  color: AppColors.income,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(3),
                                  ),
                                  border: Border.all(
                                    color: AppColors.borderDark,
                                    width: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 2),
                              // Expense Bar
                              Container(
                                width: 10,
                                height: item.expense > 0 ? expenseHeight : 4,
                                decoration: BoxDecoration(
                                  color: AppColors.expense,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(3),
                                  ),
                                  border: Border.all(
                                    color: AppColors.borderDark,
                                    width: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Month Label
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: isFocused
                                ? BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: AppColors.primary,
                                      width: 1,
                                    ),
                                  )
                                : null,
                            child: Text(
                              item.monthLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight:
                                    isFocused ? FontWeight.w900 : FontWeight.w600,
                                color: isFocused
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Interactive Tooltip on Tap
          if (selected != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderDark, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    '${selected.monthLabel} ${selected.year}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                  Text(
                    '+ ${CurrencyFormatter.formatRupiah(selected.income)}',
                    style: const TextStyle(
                      color: AppColors.income,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '- ${CurrencyFormatter.formatRupiah(selected.expense)}',
                    style: const TextStyle(
                      color: AppColors.expense,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendIndicator extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendIndicator({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: AppColors.borderDark, width: 1),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
