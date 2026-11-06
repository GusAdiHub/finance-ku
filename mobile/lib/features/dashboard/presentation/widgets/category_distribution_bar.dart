import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/category_breakdown_item.dart';

class CategoryDistributionBar extends StatelessWidget {
  final List<CategoryBreakdownItem> breakdown;

  const CategoryDistributionBar({
    super.key,
    required this.breakdown,
  });

  Color _parseColor(String? hexString, int index) {
    if (hexString != null && hexString.isNotEmpty) {
      final clean = hexString.replaceAll('#', '');
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      }
    }
    // High-contrast validated fallback categorical hues
    const fallbackPalette = [
      Color(0xFF2563EB), // Blue
      Color(0xFFEF4444), // Coral Red
      Color(0xFF10B981), // Emerald
      Color(0xFFF59E0B), // Amber
      Color(0xFF8B5CF6), // Purple
      Color(0xFF06B6D4), // Cyan
    ];
    return fallbackPalette[index % fallbackPalette.length];
  }

  @override
  Widget build(BuildContext context) {
    if (breakdown.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderDark, width: 2),
        ),
        child: Column(
          children: const [
            Icon(Icons.pie_chart_outline_rounded,
                size: 36, color: AppColors.textSecondary),
            SizedBox(height: 8),
            Text(
              'Belum ada data pengeluaran',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      );
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
                'Distribusi Pengeluaran',
                style: AppTextStyles.headingSmall,
              ),
              Text(
                '${breakdown.length} Kategori',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Proportional Segmented Bar (2px gap between segments, 8px border radius)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 18,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderDark, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: List.generate(breakdown.length, (index) {
                  final item = breakdown[index];
                  final flex = (item.percentage * 10).round().clamp(1, 1000);
                  final color = _parseColor(item.categoryColor, index);

                  return Expanded(
                    flex: flex,
                    child: Container(
                      margin: EdgeInsets.only(
                        right: index < breakdown.length - 1 ? 2.0 : 0.0,
                      ),
                      color: color,
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Legend list with amounts and percentage
          ...List.generate(breakdown.take(5).length, (index) {
            final item = breakdown[index];
            final color = _parseColor(item.categoryColor, index);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: AppColors.borderDark, width: 1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.categoryName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${item.percentage.toStringAsFixed(1)}%',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    CurrencyFormatter.formatRupiah(item.totalAmount),
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
