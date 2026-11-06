import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../sync/presentation/widgets/sync_banner.dart';
import '../../../sync/presentation/widgets/sync_status_indicator.dart';
import '../controllers/transaction_list_controller.dart';
import '../widgets/transaction_form_modal.dart';
import '../widgets/transaction_item_card.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddTransactionModal(BuildContext context, String defaultType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionFormModal(initialType: defaultType),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionListControllerProvider);
    final transactions = state.filteredTransactions;
    final selectedType = state.selectedType;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: SyncStatusIndicator(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Sync status banner when offline, pending, or error
            const SyncBanner(),

            // Search Bar Field
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  ref
                      .read(transactionListControllerProvider.notifier)
                      .setSearchQuery(val);
                },
                decoration: InputDecoration(
                  hintText: 'Cari transaksi atau catatan...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(transactionListControllerProvider.notifier)
                                .setSearchQuery('');
                          },
                        )
                      : null,
                ),
              ),
            ),

            // Type Filter Chips (Semua, Pengeluaran, Pemasukan)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Semua',
                    isSelected: selectedType == 'all',
                    onTap: () => ref
                        .read(transactionListControllerProvider.notifier)
                        .setTypeFilter('all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Pengeluaran',
                    isSelected: selectedType == 'expense',
                    activeColor: AppColors.expense,
                    activeBackgroundColor: AppColors.expenseLight,
                    onTap: () => ref
                        .read(transactionListControllerProvider.notifier)
                        .setTypeFilter('expense'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Pemasukan',
                    isSelected: selectedType == 'income',
                    activeColor: AppColors.income,
                    activeBackgroundColor: AppColors.incomeLight,
                    onTap: () => ref
                        .read(transactionListControllerProvider.notifier)
                        .setTypeFilter('income'),
                  ),
                ],
              ),
            ),

            // Error Banner if present
            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.expenseLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.expense, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.expense, size: 20),
                      const SizedBox(width: 10),
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
              ),

            // Reactive Transaction List
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () =>
                    ref.read(transactionListControllerProvider.notifier).refresh(),
                child: transactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.borderSubtle,
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.receipt_long_rounded,
                                size: 32,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Belum ada transaksi.',
                              style: AppTextStyles.headingSmall,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Catat pengeluaran atau pemasukan pertamamu.',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
                        itemCount: transactions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final tx = transactions[index];
                          return TransactionItemCard(
                            transaction: tx,
                            onTap: () {
                              context.push(
                                '/app/transactions/detail',
                                extra: tx,
                              );
                            },
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color activeColor;
  final Color activeBackgroundColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.activeColor = AppColors.primary,
    this.activeBackgroundColor = AppColors.primaryLight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBackgroundColor : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.borderDark,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: AppColors.borderDark,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: isSelected ? activeColor : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
