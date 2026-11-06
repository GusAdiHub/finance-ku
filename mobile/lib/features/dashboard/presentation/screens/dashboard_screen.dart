import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../receipts/presentation/screens/scan_receipt_screen.dart';
import '../../../sync/presentation/widgets/sync_banner.dart';
import '../../../sync/presentation/widgets/sync_status_indicator.dart';
import '../../../transactions/presentation/widgets/transaction_form_modal.dart';
import '../../../transactions/presentation/widgets/transaction_item_card.dart';
import '../../../voice/presentation/screens/voice_input_modal.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/category_distribution_bar.dart';
import '../widgets/summary_cards_row.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _showAddTransactionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TransactionFormModal(initialType: 'expense'),
    );
  }

  void _showVoiceModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const VoiceInputModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final dashboardState = ref.watch(dashboardControllerProvider);
    final data = dashboardState.data;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SakuKu'),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: SyncStatusIndicator(compact: true),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Profil Pengguna',
            onPressed: () => context.push('/app/profile'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(dashboardControllerProvider.notifier).refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sync status banner (Mode Offline, pending items)
                const SyncBanner(),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 90),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Greeting Card
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
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.borderDark,
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.wallet_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Halo, ${user?.name ?? 'Pengguna'}!',
                                    style: AppTextStyles.headingSmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    data.hasTransactions
                                        ? '${data.totalTransactionCount} transaksi tercatat di perangkat ini'
                                        : 'Mulai catat transaksi pertamamu',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Financial Summary Cards (Hero Net Balance, Total Income, Total Expense)
                      SummaryCardsRow(data: data),
                      const SizedBox(height: 16),

                      // Smart Quick Navigation Grid
                      Row(
                        children: [
                          Expanded(
                            child: _QuickNavCard(
                              icon: Icons.document_scanner_rounded,
                              label: 'Scan Nota',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const ScanReceiptScreen()),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _QuickNavCard(
                              icon: Icons.mic_rounded,
                              label: 'Suara NLP',
                              onTap: () => _showVoiceModal(context),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _QuickNavCard(
                              icon: Icons.category_outlined,
                              label: 'Kategori',
                              onTap: () => context.push('/app/categories'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Category Distribution Bar
                      CategoryDistributionBar(breakdown: data.expenseBreakdown),
                      const SizedBox(height: 20),

                      // Recent Transactions Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Transaksi Terbaru',
                            style: AppTextStyles.headingSmall,
                          ),
                          if (data.recentTransactions.isNotEmpty)
                            TextButton(
                              onPressed: () => context.push('/app/transactions'),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    'Lihat Semua',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Icon(Icons.chevron_right_rounded,
                                      size: 16, color: AppColors.primary),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (data.recentTransactions.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: AppColors.borderDark, width: 2),
                          ),
                          child: Column(
                            children: const [
                              Icon(Icons.receipt_outlined,
                                  size: 40, color: AppColors.textSecondary),
                              SizedBox(height: 8),
                              Text(
                                'Belum ada transaksi',
                                style: AppTextStyles.headingSmall,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Klik tombol "Catat Cepat" di bawah untuk mulai mencatat keuanganmu.',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        )
                      else
                        ...data.recentTransactions.map((tx) {
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickNavCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickNavCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderDark, width: 1.8),
          boxShadow: const [
            BoxShadow(
              color: AppColors.borderDark,
              offset: Offset(2.5, 2.5),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderDark, width: 1.2),
              ),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
