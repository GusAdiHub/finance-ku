import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../controllers/auth_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  void _showChangePasswordDialog() {
    final formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isSubmitting = false;
    String? localError;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.borderDark, width: 2),
              ),
              title: const Text('Ganti Kata Sandi', style: AppTextStyles.headingMedium),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (localError != null) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.expenseLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.expense, width: 1),
                          ),
                          child: Text(
                            localError!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.expense,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: currentPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Kata Sandi Saat Ini',
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Kata Sandi Baru (Min 8 Karakter)',
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Wajib diisi';
                          if (v.length < 8) return 'Minimal 8 karakter';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Ulangi Kata Sandi Baru',
                        ),
                        validator: (v) {
                          if (v != newPasswordController.text) {
                            return 'Kata sandi tidak cocok';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() {
                            isSubmitting = true;
                            localError = null;
                          });

                          final success = await ref
                              .read(authControllerProvider.notifier)
                              .changePassword(
                                currentPassword:
                                    currentPasswordController.text,
                                newPassword: newPasswordController.text,
                              );

                          if (success && mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Kata sandi berhasil diperbarui!'),
                                backgroundColor: AppColors.income,
                              ),
                            );
                          } else {
                            setDialogState(() {
                              isSubmitting = false;
                              localError = ref
                                  .read(authControllerProvider)
                                  .errorMessage;
                            });
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.borderDark, width: 2),
          ),
          title: const Text('Keluar dari Akun', style: AppTextStyles.headingMedium),
          content: const Text(
            'Apakah Anda yakin ingin keluar? Data transaksi lokal Anda di perangkat ini tetap aman dan tidak akan terhapus.',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.expense,
                foregroundColor: AppColors.textOnPrimary,
              ),
              onPressed: () async {
                Navigator.pop(context);
                await ref.read(authControllerProvider.notifier).logout();
                if (mounted) {
                  context.go('/login');
                }
              },
              child: const Text('Ya, Keluar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final initialLetter =
        (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Header Card
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
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        initialLetter,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Pengguna SakuKu',
                            style: AppTextStyles.headingMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email.isNotEmpty == true
                                ? user!.email
                                : 'Akun Lokal Terverifikasi',
                            style: AppTextStyles.bodySmall,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.incomeLight,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.income,
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              'Aktif',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.income,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Security & Storage Settings Card
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderDark, width: 2),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.lock_reset_rounded),
                      title: const Text('Ganti Kata Sandi', style: AppTextStyles.headingSmall),
                      subtitle: const Text('Perbarui kata sandi akun Anda', style: AppTextStyles.bodySmall),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _showChangePasswordDialog,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.storage_rounded),
                      title: const Text('Database Lokal', style: AppTextStyles.headingSmall),
                      subtitle: const Text('SQLite via Drift (Offline-First)', style: AppTextStyles.bodySmall),
                      trailing: const Icon(Icons.check_circle_rounded, color: AppColors.income, size: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Logout Button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.expense,
                  side: const BorderSide(color: AppColors.expense, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.logout_rounded, color: AppColors.expense),
                label: const Text('Keluar dari Akun', style: AppTextStyles.button),
                onPressed: _showLogoutConfirmation,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
