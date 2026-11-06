import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/transaction_entity.dart';
import '../controllers/transaction_list_controller.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final TransactionEntity transaction;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
  });

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderDark, width: 2),
        ),
        title: const Text('Hapus Transaksi', style: AppTextStyles.headingMedium),
        content: const Text(
          'Apakah Anda yakin ingin menghapus transaksi ini? Jika offline, transaksi akan ditandai untuk dihapus saat kembali online.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: AppColors.textOnPrimary,
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final success = await ref
                  .read(transactionListControllerProvider.notifier)
                  .deleteTransaction(transaction.id);
              if (success && context.mounted) {
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transaksi berhasil dihapus.'),
                    backgroundColor: AppColors.income,
                  ),
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpense = transaction.isExpense;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rincian Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expense),
            tooltip: 'Hapus Transaksi',
            onPressed: () => _showDeleteConfirmation(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Amount Banner Card
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  color: isExpense ? AppColors.expenseLight : AppColors.incomeLight,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isExpense ? AppColors.expense : AppColors.income,
                    width: 2,
                  ),
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
                    Text(
                      isExpense ? 'Total Pengeluaran' : 'Total Pemasukan',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: isExpense ? AppColors.expense : AppColors.income,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${isExpense ? '-' : '+'} ${CurrencyFormatter.formatRupiah(transaction.amount)}',
                      style: AppTextStyles.amountLarge.copyWith(
                        color: isExpense ? AppColors.expense : AppColors.income,
                        fontSize: 30,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Transaction Details Section Card
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderDark, width: 2),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.category_rounded),
                      title: const Text('Kategori', style: AppTextStyles.labelSmall),
                      subtitle: Text(
                        transaction.categoryName ?? 'Kategori',
                        style: AppTextStyles.headingSmall,
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.calendar_today_rounded),
                      title: const Text('Tanggal & Waktu', style: AppTextStyles.labelSmall),
                      subtitle: Text(
                        DateFormatter.formatDateTime(transaction.transactionDate),
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    if (transaction.description?.isNotEmpty == true) ...[
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.edit_note_rounded),
                        title: const Text('Deskripsi', style: AppTextStyles.labelSmall),
                        subtitle: Text(
                          transaction.description!,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                    ],
                    if (transaction.notes?.isNotEmpty == true) ...[
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.notes_rounded),
                        title: const Text('Catatan', style: AppTextStyles.labelSmall),
                        subtitle: Text(
                          transaction.notes!,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                    ],
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.input_rounded),
                      title: const Text('Metode Input', style: AppTextStyles.labelSmall),
                      subtitle: Text(
                        transaction.inputMethod.toUpperCase(),
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Offline Sync Status Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderDark, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Status Sinkronisasi', style: AppTextStyles.labelMedium),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          transaction.isSynced
                              ? Icons.cloud_done_rounded
                              : (transaction.isFailed
                                  ? Icons.error_outline_rounded
                                  : Icons.cloud_upload_outlined),
                          color: transaction.isSynced
                              ? AppColors.income
                              : (transaction.isFailed
                                  ? AppColors.expense
                                  : AppColors.warning),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          transaction.isSynced
                              ? 'Tersinkronisasi ke PostgreSQL'
                              : (transaction.isFailed
                                  ? 'Gagal sinkronisasi'
                                  : 'Tersimpan lokal di SQLite (Pending)'),
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Local ID: ${transaction.id}',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                    if (transaction.remoteId != null)
                      Text(
                        'Remote ID: ${transaction.remoteId}',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
