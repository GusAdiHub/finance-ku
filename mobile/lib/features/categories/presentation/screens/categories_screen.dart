import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../domain/entities/category_entity.dart';
import '../controllers/categories_controller.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

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

  void _showAddCategoryModal(BuildContext context, WidgetRef ref, String defaultType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddCategorySheet(defaultType: defaultType),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, CategoryEntity category) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderDark, width: 2),
        ),
        title: const Text('Hapus Kategori', style: AppTextStyles.headingMedium),
        content: Text(
          'Hapus kategori "${category.name}"? Kategori yang sedang digunakan oleh transaksi tidak dapat dihapus.',
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
                  .read(categoriesControllerProvider.notifier)
                  .deleteCategory(category.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kategori berhasil dihapus.'),
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
    final state = ref.watch(categoriesControllerProvider);
    final categories = state.filteredCategories;
    final isExpense = state.selectedTab == 'expense';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kategori Keuangan'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Kategori', style: AppTextStyles.button),
        onPressed: () => _showAddCategoryModal(context, ref, state.selectedTab),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tab Selector (Pengeluaran vs Pemasukan)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderDark, width: 1.5),
                ),
                child: Row(
                  children: [
                    // Tab Pengeluaran
                    Expanded(
                      child: GestureDetector(
                        onTap: () => ref
                            .read(categoriesControllerProvider.notifier)
                            .changeTab('expense'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isExpense ? AppColors.surface : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: isExpense
                                ? Border.all(color: AppColors.borderDark, width: 1.5)
                                : null,
                            boxShadow: isExpense
                                ? const [
                                    BoxShadow(
                                      color: AppColors.borderDark,
                                      offset: Offset(2, 2),
                                      blurRadius: 0,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_upward_rounded,
                                size: 18,
                                color: isExpense ? AppColors.expense : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Pengeluaran',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: isExpense
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                  fontWeight:
                                      isExpense ? FontWeight.w800 : FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Tab Pemasukan
                    Expanded(
                      child: GestureDetector(
                        onTap: () => ref
                            .read(categoriesControllerProvider.notifier)
                            .changeTab('income'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !isExpense ? AppColors.surface : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: !isExpense
                                ? Border.all(color: AppColors.borderDark, width: 1.5)
                                : null,
                            boxShadow: !isExpense
                                ? const [
                                    BoxShadow(
                                      color: AppColors.borderDark,
                                      offset: Offset(2, 2),
                                      blurRadius: 0,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_downward_rounded,
                                size: 18,
                                color: !isExpense ? AppColors.income : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Pemasukan',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: !isExpense
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                  fontWeight:
                                      !isExpense ? FontWeight.w800 : FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Error Banner if present
            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

            // Categories List View with Pull-To-Refresh
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => ref
                    .read(categoriesControllerProvider.notifier)
                    .loadCategories(forceRefresh: true),
                child: categories.isEmpty
                    ? Center(
                        child: Text(
                          'Belum ada kategori ${isExpense ? 'pengeluaran' : 'pemasukan'}.',
                          style: AppTextStyles.bodyMedium,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
                        itemCount: categories.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final iconData = _resolveCategoryIcon(category.icon);
                          final color = _resolveCategoryColor(category.color);

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.borderDark,
                                width: 1.5,
                              ),
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
                                // Category Icon & Color Avatar
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: color,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Icon(iconData, color: color, size: 22),
                                ),
                                const SizedBox(width: 14),

                                // Category Name & Badge
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        category.name,
                                        style: AppTextStyles.headingSmall,
                                      ),
                                      const SizedBox(height: 4),
                                      if (category.isSystem)
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.lock_rounded,
                                              size: 13,
                                              color: AppColors.textMuted,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Kategori Sistem',
                                              style: AppTextStyles.labelSmall.copyWith(
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryLight,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: AppColors.primary,
                                              width: 1,
                                            ),
                                          ),
                                          child: const Text(
                                            'Kustom',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                // Action: Delete button only for Custom Categories
                                if (!category.isSystem)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: AppColors.expense,
                                    ),
                                    tooltip: 'Hapus Kategori',
                                    onPressed: () => _showDeleteConfirmation(
                                      context,
                                      ref,
                                      category,
                                    ),
                                  ),
                              ],
                            ),
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

/// Bottom Sheet modal for creating a new custom category
class _AddCategorySheet extends ConsumerStatefulWidget {
  final String defaultType;

  const _AddCategorySheet({required this.defaultType});

  @override
  ConsumerState<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends ConsumerState<_AddCategorySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _selectedType;
  String _selectedColor = '#2563EB';
  String _selectedIcon = 'utensils';
  bool _isSubmitting = false;

  static const List<String> _colorOptions = [
    '#EF4444', // Red
    '#F59E0B', // Amber
    '#10B981', // Green
    '#3B82F6', // Blue
    '#8B5CF6', // Purple
    '#EC4899', // Pink
    '#14B8A6', // Teal
    '#0F172A', // Slate Dark
  ];

  static const List<Map<String, dynamic>> _iconOptions = [
    {'name': 'utensils', 'icon': Icons.restaurant_rounded},
    {'name': 'coffee', 'icon': Icons.coffee_rounded},
    {'name': 'shopping-cart', 'icon': Icons.shopping_bag_rounded},
    {'name': 'car', 'icon': Icons.directions_car_rounded},
    {'name': 'receipt', 'icon': Icons.receipt_long_rounded},
    {'name': 'film', 'icon': Icons.movie_creation_rounded},
    {'name': 'heart-pulse', 'icon': Icons.favorite_rounded},
    {'name': 'briefcase', 'icon': Icons.work_rounded},
    {'name': 'gift', 'icon': Icons.card_giftcard_rounded},
    {'name': 'trending-up', 'icon': Icons.trending_up_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _selectedType = widget.defaultType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color _hexToColor(String hex) {
    return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final success = await ref
        .read(categoriesControllerProvider.notifier)
        .createCategory(
          name: _nameController.text.trim(),
          type: _selectedType,
          color: _selectedColor,
          icon: _selectedIcon,
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kategori berhasil ditambahkan.'),
            backgroundColor: AppColors.income,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.borderDark, width: 2),
          left: BorderSide(color: AppColors.borderDark, width: 2),
          right: BorderSide(color: AppColors.borderDark, width: 2),
        ),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sheet Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Kategori Baru', style: AppTextStyles.headingMedium),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Category Type Selector
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _selectedType == 'expense'
                            ? AppColors.expenseLight
                            : AppColors.surface,
                        side: BorderSide(
                          color: _selectedType == 'expense'
                              ? AppColors.expense
                              : AppColors.borderDark,
                          width: _selectedType == 'expense' ? 2 : 1,
                        ),
                      ),
                      onPressed: () => setState(() => _selectedType = 'expense'),
                      child: const Text('Pengeluaran'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _selectedType == 'income'
                            ? AppColors.incomeLight
                            : AppColors.surface,
                        side: BorderSide(
                          color: _selectedType == 'income'
                              ? AppColors.income
                              : AppColors.borderDark,
                          width: _selectedType == 'income' ? 2 : 1,
                        ),
                      ),
                      onPressed: () => setState(() => _selectedType = 'income'),
                      child: const Text('Pemasukan'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Category Name Input
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Kategori',
                  hintText: 'Contoh: Kopi & Camilan',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama kategori wajib diisi.';
                  }
                  if (value.trim().length < 2) {
                    return 'Nama kategori minimal 2 karakter.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Color Selection Chips
              const Text('Pilih Warna', style: AppTextStyles.labelMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _colorOptions.map((hex) {
                  final isSelected = _selectedColor == hex;
                  final color = _hexToColor(hex);
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = hex),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.borderDark
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: AppColors.textOnPrimary,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Icon Selection Chips
              const Text('Pilih Ikon', style: AppTextStyles.labelMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _iconOptions.map((item) {
                  final isSelected = _selectedIcon == item['name'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = item['name']),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryLight
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.borderSubtle,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 22,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textOnPrimary,
                        ),
                      )
                    : const Text('Simpan Kategori'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
