import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../domain/entities/group_entity.dart';
import '../controllers/groups_controller.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final GroupEntity group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  List<GroupMemberEntity> _members = [];
  bool _isLoadingMembers = true;
  String? _inviteCode;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final members = await ref
          .read(groupRemoteDataSourceProvider)
          .getGroupMembers(widget.group.id);
      if (mounted) {
        setState(() {
          _members = members;
          _isLoadingMembers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMembers = false);
      }
    }
  }

  Future<void> _generateInviteCode() async {
    final code = await ref
        .read(groupsControllerProvider.notifier)
        .generateInviteCode(widget.group.id);
    if (code != null && mounted) {
      setState(() => _inviteCode = code);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.borderDark, width: 2.5),
          ),
          title: const Text('Kode Undangan Kas Tim', style: AppTextStyles.headingSmall),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Bagikan kode undangan ini kepada keluarga atau anggota tim kamu:',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderDark, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.borderDark,
                      offset: Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Text(
                  code,
                  style: AppTextStyles.headingLarge.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Berlaku selama 7 hari (maks. 5 anggota baru)',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.income,
                    content: Text('Kode undangan berhasil disalin!'),
                  ),
                );
              },
              child: const Text('Salin Kode'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.group.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Group Header Card
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.group.name,
                          style: AppTextStyles.headingMedium,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.borderDark, width: 1.5),
                        ),
                        child: Text(
                          widget.group.userRole.toUpperCase(),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.group.description != null &&
                      widget.group.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.group.description!,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (widget.group.isAdminOrOwner)
                    ElevatedButton.icon(
                      onPressed: _generateInviteCode,
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Buat Kode Undangan Anggota'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Members Section
            const Text(
              'Daftar Anggota Kas Tim',
              style: AppTextStyles.headingSmall,
            ),
            const SizedBox(height: 12),

            if (_isLoadingMembers)
              const Center(child: CircularProgressIndicator())
            else if (_members.isEmpty)
              const Text('Belum ada data anggota.',
                  style: AppTextStyles.bodySmall)
            else
              ..._members.map((member) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderDark, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primaryLight,
                            child: Text(
                              member.userName.isNotEmpty
                                  ? member.userName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(member.userName,
                              style: AppTextStyles.bodyMedium),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.borderDark, width: 1),
                        ),
                        child: Text(
                          member.role.toUpperCase(),
                          style: AppTextStyles.labelSmall.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
