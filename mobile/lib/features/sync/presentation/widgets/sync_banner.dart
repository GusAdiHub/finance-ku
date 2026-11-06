import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../controllers/sync_controller.dart';

class SyncBanner extends ConsumerWidget {
  const SyncBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncControllerProvider);

    // If online, fully synced, and no error, do not show banner
    if (syncState.isConnected &&
        !syncState.hasPending &&
        !syncState.isPaused &&
        syncState.errorMessage == null) {
      return const SizedBox.shrink();
    }

    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData icon;
    String message;

    if (syncState.isPaused) {
      bgColor = AppColors.warningLight;
      borderColor = AppColors.warning;
      textColor = AppColors.warning;
      icon = Icons.lock_clock_rounded;
      message = 'Sesi Anda telah berakhir. Masuk kembali untuk menyinkronkan data.';
    } else if (syncState.isOffline) {
      bgColor = AppColors.surfaceVariant;
      borderColor = AppColors.borderDark;
      textColor = AppColors.textPrimary;
      icon = Icons.cloud_off_rounded;
      message = syncState.hasPending
          ? 'Mode Offline: ${syncState.pendingCount} transaksi tersimpan di SQLite lokal. Akan otomatis disinkronkan saat online.'
          : 'Mode Offline: Anda tetap dapat mencatat pengeluaran & pemasukan tanpa internet.';
    } else if (syncState.hasPending) {
      bgColor = AppColors.warningLight;
      borderColor = AppColors.warning;
      textColor = AppColors.textPrimary;
      icon = Icons.cloud_upload_outlined;
      message = '${syncState.pendingCount} transaksi menunggu sinkronisasi.';
    } else if (syncState.errorMessage != null) {
      bgColor = AppColors.expenseLight;
      borderColor = AppColors.expense;
      textColor = AppColors.expense;
      icon = Icons.error_outline_rounded;
      message = syncState.errorMessage!;
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
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
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          if (syncState.isConnected && !syncState.isSyncing && syncState.hasPending) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                ref.read(syncControllerProvider.notifier).syncNow();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Sync',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
