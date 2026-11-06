import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/receipts/presentation/screens/scan_receipt_screen.dart';
import '../../features/transactions/presentation/widgets/transaction_form_modal.dart';
import '../../features/voice/presentation/screens/voice_input_modal.dart';
import '../constants/app_colors.dart';
import '../theme/text_styles.dart';

class MainScaffold extends StatefulWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/app/dashboard')) return 0;
    if (location.startsWith('/app/transactions')) return 1;
    if (location.startsWith('/app/groups')) return 2;
    if (location.startsWith('/app/reports')) return 3;
    if (location.startsWith('/app/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/app/dashboard');
        break;
      case 1:
        context.go('/app/transactions');
        break;
      case 2:
        context.go('/app/groups');
        break;
      case 3:
        context.go('/app/reports');
        break;
      case 4:
        context.go('/app/profile');
        break;
    }
  }

  void _showSmartActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: BoxDecoration(
              color: AppColors.glassSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: const Border(
                top: BorderSide(color: AppColors.borderDark, width: 2.5),
                left: BorderSide(color: AppColors.borderDark, width: 2.5),
                right: BorderSide(color: AppColors.borderDark, width: 2.5),
              ),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.borderDark,
                  offset: Offset(0, -3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Neo-brutalist Handle bar
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.borderDark,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

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
                          Icons.bolt_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Catat Transaksi Instan',
                          style: AppTextStyles.headingSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Option 1: Scan Nota OCR (Neo-Glassmorphism + Neo-brutalism)
                  _NeoActionTile(
                    icon: Icons.document_scanner_rounded,
                    accentColor: AppColors.primary,
                    tintBg: AppColors.primaryLight,
                    badgeText: 'OCR KAMERA',
                    title: 'Scan Nota / Struk',
                    subtitle: 'Foto nota fisik, nominal & rincian item terbaca otomatis',
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ScanReceiptScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Option 2: Voice Input NLP
                  _NeoActionTile(
                    icon: Icons.mic_rounded,
                    accentColor: AppColors.income,
                    tintBg: AppColors.incomeLight,
                    badgeText: 'SUARA BAHASA INDONESIA',
                    title: 'Input Suara (NLP)',
                    subtitle: 'Ucapkan kalimat transaksi sehari-hari secara natural',
                    onTap: () {
                      Navigator.pop(ctx);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const VoiceInputModal(),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Option 3: Manual Input
                  _NeoActionTile(
                    icon: Icons.edit_note_rounded,
                    accentColor: AppColors.warning,
                    tintBg: AppColors.warningLight,
                    badgeText: 'FORM CEPAT',
                    title: 'Catat Manual Biasa',
                    subtitle: 'Ketik nominal rupiah, pilih kategori, dan simpan instan',
                    onTap: () {
                      Navigator.pop(ctx);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) =>
                            const TransactionFormModal(initialType: 'expense'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _calculateSelectedIndex(context);

    return Scaffold(
      extendBody: false,
      body: widget.child,
      floatingActionButton: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.borderDark,
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: AppColors.primary,
          elevation: 0,
          highlightElevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.borderDark, width: 2),
          ),
          onPressed: () => _showSmartActionMenu(context),
          child: const Icon(Icons.add_rounded, size: 30, color: Colors.white),
        ),
      ),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.glassSurface,
              border: Border(
                top: BorderSide(color: AppColors.borderDark, width: 2),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: (index) => _onItemTapped(index, context),
              backgroundColor: Colors.transparent,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textSecondary,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              selectedLabelStyle: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
              unselectedLabelStyle: AppTextStyles.labelSmall.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_rounded),
                  activeIcon: _NavActiveIcon(icon: Icons.dashboard_rounded),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_rounded),
                  activeIcon: _NavActiveIcon(icon: Icons.receipt_long_rounded),
                  label: 'Riwayat',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.groups_rounded),
                  activeIcon: _NavActiveIcon(icon: Icons.groups_rounded),
                  label: 'Kas Tim',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart_rounded),
                  activeIcon: _NavActiveIcon(icon: Icons.bar_chart_rounded),
                  label: 'Laporan',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_rounded),
                  activeIcon: _NavActiveIcon(icon: Icons.person_rounded),
                  label: 'Profil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavActiveIcon extends StatelessWidget {
  final IconData icon;

  const _NavActiveIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderDark, width: 1.5),
      ),
      child: Icon(icon, color: AppColors.primary, size: 22),
    );
  }
}

class _NeoActionTile extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final Color tintBg;
  final String badgeText;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NeoActionTile({
    required this.icon,
    required this.accentColor,
    required this.tintBg,
    required this.badgeText,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
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
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: tintBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderDark, width: 1.5),
              ),
              child: Icon(icon, color: accentColor, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tintBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.borderDark, width: 1),
                        ),
                        child: Text(
                          badgeText,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(title, style: AppTextStyles.headingSmall.copyWith(fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderDark, width: 1.2),
              ),
              child: const Icon(Icons.arrow_forward_rounded,
                  size: 14, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
