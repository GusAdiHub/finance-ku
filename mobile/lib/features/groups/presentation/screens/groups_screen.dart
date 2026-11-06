import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../sync/presentation/widgets/sync_status_indicator.dart';
import '../../domain/entities/group_entity.dart';
import '../controllers/groups_controller.dart';

class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  void _showCreateGroupModal(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              top: 16,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              color: AppColors.glassSurface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
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
                  const Text('Buat Kas Tim Baru',
                      style: AppTextStyles.headingSmall),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Grup / Kas Tim',
                      hintText: 'Misal: Kas Keluarga, Kas Panitia',
                      prefixIcon: Icon(Icons.group_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi Kas (Opsional)',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: const BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.borderDark,
                          offset: Offset(3, 3),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;
                        Navigator.pop(ctx);
                        final group = await ref
                            .read(groupsControllerProvider.notifier)
                            .createGroup(name, descController.text.trim());
                        if (group != null && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.income,
                              content: Text(
                                  'Kas tim "${group.name}" berhasil dibuat!'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(
                              color: AppColors.borderDark, width: 2),
                        ),
                      ),
                      child: const Text('Buat Kas Tim Sekarang'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showJoinGroupModal(BuildContext context) {
    final codeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              top: 16,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              color: AppColors.glassSurface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
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
                  const Text('Gabung Kas Tim',
                      style: AppTextStyles.headingSmall),
                  const SizedBox(height: 16),
                  TextField(
                    controller: codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Kode Undangan',
                      hintText: 'Misal: FAM-9X2K',
                      prefixIcon: Icon(Icons.key_rounded),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: const BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.borderDark,
                          offset: Offset(3, 3),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        final code = codeController.text.trim();
                        if (code.isEmpty) return;
                        Navigator.pop(ctx);
                        final group = await ref
                            .read(groupsControllerProvider.notifier)
                            .joinGroup(code);
                        if (group != null && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.income,
                              content: Text(
                                  'Berhasil bergabung ke kas tim "${group.name}"!'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(
                              color: AppColors.borderDark, width: 2),
                        ),
                      ),
                      child: const Text('Gabung Sekarang'),
                    ),
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
    final state = ref.watch(groupsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kas Tim & Keluarga'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: SyncStatusIndicator(compact: true),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(groupsControllerProvider.notifier).refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Info Banner (Neo-brutalist with Neo-glassmorphism accent)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderDark, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.borderDark,
                      offset: Offset(3.5, 3.5),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: AppColors.borderDark, width: 1.8),
                      ),
                      child: const Icon(
                        Icons.groups_rounded,
                        color: AppColors.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Shared Ledger Kas Bersama',
                            style: AppTextStyles.labelMedium,
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Kelola keuangan keluarga, panitia, atau tim secara transparan dan akuntabel.',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action buttons row (Chunky Neo-brutalist buttons)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.borderDark,
                            offset: Offset(2.5, 2.5),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => _showCreateGroupModal(context),
                        icon: const Icon(Icons.add_rounded, color: Colors.white),
                        label: const Text('Buat Kas Baru',
                            style: AppTextStyles.button),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                                color: AppColors.borderDark, width: 1.8),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.borderDark,
                            offset: Offset(2.5, 2.5),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: OutlinedButton.icon(
                        onPressed: () => _showJoinGroupModal(context),
                        icon: const Icon(Icons.key_rounded,
                            color: AppColors.textPrimary),
                        label: const Text('Gabung Kode',
                            style: AppTextStyles.button),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.surfaceVariant,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                                color: AppColors.borderDark, width: 1.8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Groups List Section
              const Text(
                'Daftar Kas Tim Anda',
                style: AppTextStyles.headingSmall,
              ),
              const SizedBox(height: 12),

              if (state.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (state.groups.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
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
                    children: const [
                      Icon(Icons.group_off_rounded,
                          size: 48, color: AppColors.textMuted),
                      SizedBox(height: 12),
                      Text(
                        'Belum Ada Kas Tim',
                        style: AppTextStyles.headingSmall,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Buat grup kas tim baru atau gabung menggunakan kode undangan dari kerabatmu.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                )
              else
                ...state.groups.map((group) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: AppColors.borderDark, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.borderDark,
                          offset: Offset(3, 3),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: () {
                        context.push('/app/groups/${group.id}', extra: group);
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: AppColors.borderDark, width: 1.6),
                            ),
                            child: const Icon(
                              Icons.folder_shared_rounded,
                              color: AppColors.primary,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  group.name,
                                  style: AppTextStyles.headingSmall,
                                ),
                                if (group.description != null &&
                                    group.description!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    group.description!,
                                    style: AppTextStyles.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceVariant,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                            color: AppColors.borderDark,
                                            width: 1),
                                      ),
                                      child: Text(
                                        group.userRole.toUpperCase(),
                                        style: AppTextStyles.labelSmall.copyWith(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${group.membersCount} Anggota',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.borderDark, width: 1.2),
                            ),
                            child: const Icon(Icons.arrow_forward_ios_rounded,
                                size: 12, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
