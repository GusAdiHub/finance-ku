import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../domain/entities/period_filter.dart';

class PeriodSelectorWidget extends StatelessWidget {
  final PeriodFilter period;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<PeriodFilter> onSelectPeriod;

  const PeriodSelectorWidget({
    super.key,
    required this.period,
    required this.onPrevious,
    required this.onNext,
    required this.onSelectPeriod,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main Navigation Bar with < and > buttons
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderDark, width: 2),
            boxShadow: const [
              BoxShadow(
                color: AppColors.borderDark,
                offset: Offset(2.5, 2.5),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                tooltip: 'Periode Sebelumnya',
                onPressed: onPrevious,
              ),
              Expanded(
                child: Text(
                  period.label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headingSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                tooltip: 'Periode Selanjutnya',
                onPressed: onNext,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Quick Preset Chips (Bulan Ini, Hari Ini, Kemarin)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _PresetChip(
                label: 'Bulan Ini',
                isSelected: period.type == PeriodType.month &&
                    period.startDate.month == DateTime.now().month &&
                    period.startDate.year == DateTime.now().year,
                onTap: () => onSelectPeriod(PeriodFilter.thisMonth()),
              ),
              const SizedBox(width: 8),
              _PresetChip(
                label: 'Hari Ini',
                isSelected: period.type == PeriodType.day &&
                    period.startDate.day == DateTime.now().day,
                onTap: () => onSelectPeriod(PeriodFilter.today()),
              ),
              const SizedBox(width: 8),
              _PresetChip(
                label: 'Kemarin',
                isSelected: period.type == PeriodType.day &&
                    period.startDate.day ==
                        DateTime.now().subtract(const Duration(days: 1)).day,
                onTap: () => onSelectPeriod(PeriodFilter.yesterday()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderDark,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: AppColors.borderDark,
                    offset: Offset(1.5, 1.5),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
