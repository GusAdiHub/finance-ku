import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../categories/presentation/controllers/categories_controller.dart';
import '../controllers/transaction_list_controller.dart';

class TransactionFormModal extends ConsumerStatefulWidget {
  final String initialType;

  const TransactionFormModal({
    super.key,
    this.initialType = 'expense',
  });

  @override
  ConsumerState<TransactionFormModal> createState() => _TransactionFormModalState();
}

class _TransactionFormModalState extends ConsumerState<TransactionFormModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _notesController;

  late String _selectedType;
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
    _notesController = TextEditingController();
    _selectedType = widget.initialType;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.textOnPrimary,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih kategori transaksi.'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    final rawAmountText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(rawAmountText) ?? 0.0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nominal transaksi harus lebih dari 0.'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final success = await ref
        .read(transactionListControllerProvider.notifier)
        .createTransaction(
          type: _selectedType,
          amount: amount,
          categoryId: _selectedCategoryId!,
          transactionDate: _selectedDate,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedType == 'expense' ? 'Pengeluaran' : 'Pemasukan'} ${CurrencyFormatter.formatRupiah(amount)} tersimpan instan!',
            ),
            backgroundColor: AppColors.income,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesControllerProvider);
    final availableCategories = categoriesState.categories
        .where((c) => c.type == _selectedType)
        .toList();

    // Auto-select first category if current selection is invalid for selected type
    if (_selectedCategoryId == null && availableCategories.isNotEmpty) {
      _selectedCategoryId = availableCategories.first.id;
    } else if (_selectedCategoryId != null &&
        !availableCategories.any((c) => c.id == _selectedCategoryId)) {
      _selectedCategoryId =
          availableCategories.isNotEmpty ? availableCategories.first.id : null;
    }

    final isExpense = _selectedType == 'expense';

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
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Catat Transaksi', style: AppTextStyles.headingMedium),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Type Switcher (Pengeluaran vs Pemasukan)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isExpense
                            ? AppColors.expenseLight
                            : AppColors.surface,
                        side: BorderSide(
                          color: isExpense
                              ? AppColors.expense
                              : AppColors.borderDark,
                          width: isExpense ? 2 : 1,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedType = 'expense';
                          _selectedCategoryId = null;
                        });
                      },
                      child: Text(
                        'Pengeluaran',
                        style: TextStyle(
                          color: isExpense
                              ? AppColors.expense
                              : AppColors.textPrimary,
                          fontWeight:
                              isExpense ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: !isExpense
                            ? AppColors.incomeLight
                            : AppColors.surface,
                        side: BorderSide(
                          color: !isExpense
                              ? AppColors.income
                              : AppColors.borderDark,
                          width: !isExpense ? 2 : 1,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedType = 'income';
                          _selectedCategoryId = null;
                        });
                      },
                      child: Text(
                        'Pemasukan',
                        style: TextStyle(
                          color: !isExpense
                              ? AppColors.income
                              : AppColors.textPrimary,
                          fontWeight:
                              !isExpense ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Amount Input Field
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppTextStyles.amountLarge.copyWith(
                  color: isExpense ? AppColors.expense : AppColors.income,
                ),
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  prefixStyle: AppTextStyles.amountLarge.copyWith(
                    color: isExpense ? AppColors.expense : AppColors.income,
                  ),
                  hintText: '0',
                  labelText: 'Nominal Transaksi',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nominal wajib diisi.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Selector Dropdown
              const Text('Kategori', style: AppTextStyles.labelMedium),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_rounded),
                  hintText: 'Pilih Kategori',
                ),
                items: availableCategories.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat.id,
                    child: Row(
                      children: [
                        Text(cat.name, style: AppTextStyles.bodyMedium),
                        if (cat.isSystem) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.lock_outline_rounded,
                              size: 14, color: AppColors.textMuted),
                        ],
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedCategoryId = val);
                },
              ),
              const SizedBox(height: 16),

              // Date Picker Button
              const Text('Tanggal Transaksi', style: AppTextStyles.labelMedium),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderDark, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        DateFormatter.formatFullDate(_selectedDate),
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description Input Field
              TextFormField(
                controller: _descriptionController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi / Tempat Belanja',
                  hintText: 'Contoh: Makan Siang Nasi Padang',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
              ),
              const SizedBox(height: 14),

              // Notes Input Field
              TextFormField(
                controller: _notesController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Catatan Tambahan (Opsional)',
                  hintText: 'Contoh: Bersama rekan kantor',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 22),

              // Submit Button
              ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textOnPrimary,
                        ),
                      )
                    : const Text('Simpan Transaksi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
