import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/sync_state.dart';
import '../controllers/sync_controller.dart';

class SyncStatusIndicator extends ConsumerWidget {
  final bool compact;

  const SyncStatusIndicator({
    super.key,
    this.compact = false,
  });

  void _showSyncDetailsModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _SyncDetailsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncControllerProvider);

    Color borderColor;
    Color backgroundColor;
    Color contentColor;
    IconData icon;
    String label;

    if (syncState.isSyncing) {
      borderColor = AppColors.primary;
      backgroundColor = AppColors.primaryLight;
      contentColor = AppColors.primary;
      icon = Icons.sync_rounded;
      label = compact ? 'Sync...' : 'Menyinkronkan...';
    } else if (syncState.isOffline) {
      borderColor = AppColors.borderDark;
      backgroundColor = AppColors.surfaceVariant;
      contentColor = AppColors.textSecondary;
      icon = Icons.cloud_off_rounded;
      label = 'Offline';
    } else if (syncState.isPaused) {
      borderColor = AppColors.warning;
      backgroundColor = AppColors.warningLight;
      contentColor = AppColors.warning;
      icon = Icons.lock_clock_rounded;
      label = compact ? 'Sesi Exp' : 'Sesi Kedaluwarsa';
    } else if (syncState.hasPending) {
      borderColor = AppColors.warning;
      backgroundColor = AppColors.warningLight;
      contentColor = AppColors.warning;
      icon = Icons.cloud_upload_outlined;
      label = compact ? '${syncState.pendingCount}' : '${syncState.pendingCount} Belum Sync';
    } else {
      borderColor = AppColors.income;
      backgroundColor = AppColors.incomeLight;
      contentColor = AppColors.income;
      icon = Icons.cloud_done_rounded;
      label = compact ? 'Sync' : 'Tersinkron';
    }

    return GestureDetector(
      onTap: () => _showSyncDetailsModal(context, ref),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: AppColors.borderDark,
              offset: Offset(1.5, 1.5),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (syncState.isSyncing)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(contentColor),
                ),
              )
            else
              Icon(icon, size: 16, color: contentColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: contentColor,
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

class _SyncDetailsSheet extends ConsumerWidget {
  const _SyncDetailsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncControllerProvider);
    final lastSyncText = syncState.lastSyncedAt != null
        ? DateFormatter.formatDateTime(syncState.lastSyncedAt!)
        : 'Belum pernah';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.borderDark, width: 2),
          left: BorderSide(color: AppColors.borderDark, width: 2),
          right: BorderSide(color: AppColors.borderDark, width: 2),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderDark, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.sync_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Status Sinkronisasi SakuKu',
                    style: AppTextStyles.headingSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Status metrics
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderDark, width: 1.5),
              ),
              child: Column(
                children: [
                  _MetricRow(
                    label: 'Status Jaringan',
                    value: syncState.isConnected ? 'Online' : 'Offline',
                    valueColor: syncState.isConnected
                        ? AppColors.income
                        : AppColors.expense,
                    icon: syncState.isConnected
                        ? Icons.wifi_rounded
                        : Icons.wifi_off_rounded,
                  ),
                  const Divider(height: 16),
                  _MetricRow(
                    label: 'Data Menunggu Sinkron',
                    value: '${syncState.pendingCount} transaksi',
                    valueColor: syncState.hasPending
                        ? AppColors.warning
                        : AppColors.income,
                    icon: Icons.hourglass_top_rounded,
                  ),
                  const Divider(height: 16),
                  _MetricRow(
                    label: 'Terakhir Sinkron',
                    value: lastSyncText,
                    icon: Icons.access_time_rounded,
                  ),
                ],
              ),
            ),

            if (syncState.errorMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.expenseLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.expense, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.expense, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        syncState.errorMessage!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.expense,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Action button
            ElevatedButton.icon(
              icon: syncState.isSyncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.cloud_sync_rounded),
              label: Text(
                syncState.isSyncing
                    ? 'Sedang Menyinkronkan...'
                    : 'Sinkronkan Sekarang',
              ),
              onPressed: syncState.isSyncing
                  ? null
                  : () async {
                      Navigator.pop(context);
                      final result = await ref
                          .read(syncControllerProvider.notifier)
                          .syncNow(force: true);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: result.success
                                ? AppColors.income
                                : AppColors.expense,
                            content: Text(
                              result.success
                                  ? 'Sinkronisasi berhasil: ${result.pushedCount} dikirim, ${result.pulledCount} diunduh.'
                                  : 'Sinkronisasi gagal: ${result.errors.isNotEmpty ? result.errors.first : 'Error'}',
                            ),
                          ),
                        );
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final IconData icon;

  const _MetricRow({
    required this.label,
    required this.value,
    this.valueColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: AppTextStyles.bodyMedium),
        ),
        Text(
          value,
          style: AppTextStyles.labelMedium.copyWith(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
