import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/transaction_entity.dart';

class TransactionItemCard extends StatelessWidget {
  final TransactionEntity transaction;
  final VoidCallback? onTap;

  const TransactionItemCard({
    super.key,
    required this.transaction,
    this.onTap,
  });

  IconData _resolveCategoryIcon(String? iconName) {
    switch (iconName) {
      case 'utensils':
      case 'food':
        return Icons.restaurant_rounded;
      case 'car':
      case 'transport':
        return Icons.directions_car_rounded;
      case 'shopping-cart':
      case 'cart':
        return Icons.shopping_bag_rounded;
      case 'receipt':
      case 'bills':
        return Icons.receipt_long_rounded;
      case 'film':
      case 'entertainment':
        return Icons.movie_creation_rounded;
      case 'heart-pulse':
      case 'health':
        return Icons.favorite_rounded;
      case 'briefcase':
      case 'salary':
        return Icons.work_rounded;
      case 'gift':
      case 'bonus':
        return Icons.card_giftcard_rounded;
      case 'trending-up':
      case 'investment':
        return Icons.trending_up_rounded;
      case 'coffee':
        return Icons.coffee_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Color _resolveCategoryColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return AppColors.primary;
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  Widget _buildSyncBadge() {
    if (transaction.isSynced) {
      return const Tooltip(
        message: 'Tersinkronisasi dengan server',
        child: Icon(
          Icons.cloud_done_rounded,
          color: AppColors.income,
          size: 16,
        ),
      );
    }

    if (transaction.isFailed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.expenseLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.expense, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.expense, size: 12),
            const SizedBox(width: 4),
            Text(
              'Gagal Sync',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.expense,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    // Pending Sync (Created/Updated/Deleted offline)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.warning, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_upload_outlined,
              color: AppColors.warning, size: 12),
          const SizedBox(width: 4),
          Text(
            'Lokal (Pending)',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.isExpense;
    final color = _resolveCategoryColor(transaction.categoryColor);
    final iconData = _resolveCategoryIcon(transaction.categoryIcon);
    final formattedAmount =
        '${isExpense ? '-' : '+'} ${CurrencyFormatter.formatRupiah(transaction.amount)}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderDark, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: AppColors.borderDark,
              offset: Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            // Category Icon Avatar
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color, width: 1.5),
              ),
              child: Icon(iconData, color: color, size: 24),
            ),
            const SizedBox(width: 14),

            // Description / Category & Timestamp
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description?.isNotEmpty == true
                        ? transaction.description!
                        : (transaction.categoryName ?? 'Transaksi'),
                    style: AppTextStyles.headingSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        DateFormatter.formatDateTime(transaction.transactionDate),
                        style: AppTextStyles.bodySmall,
                      ),
                      if (transaction.categoryName != null &&
                          transaction.description?.isNotEmpty == true) ...[
                        const SizedBox(width: 6),
                        const Text('•', style: AppTextStyles.bodySmall),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            transaction.categoryName!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Amount & Sync Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formattedAmount,
                  style: AppTextStyles.amountSmall.copyWith(
                    color: isExpense ? AppColors.expense : AppColors.income,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                _buildSyncBadge(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
