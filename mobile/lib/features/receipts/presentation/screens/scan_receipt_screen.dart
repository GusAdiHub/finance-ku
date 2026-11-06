import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../categories/presentation/controllers/categories_controller.dart';
import '../../../transactions/presentation/controllers/transaction_list_controller.dart';
import '../../data/models/receipt_model.dart';
import '../controllers/receipt_controller.dart';

class ScanReceiptScreen extends ConsumerStatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  ConsumerState<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends ConsumerState<ScanReceiptScreen>
    with SingleTickerProviderStateMixin {
  File? _selectedImage;
  final _picker = ImagePicker();
  final _merchantController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedCategoryId;
  late AnimationController _scanAnimController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scanAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _scanAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanAnimController.dispose();
    _merchantController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
        });
        _processOcr();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.expense,
          content: Text('Gagal memilih gambar: $e'),
        ),
      );
    }
  }

  Future<void> _processOcr() async {
    if (_selectedImage == null) return;
    final receipt = await ref
        .read(receiptControllerProvider.notifier)
        .scanReceipt(_selectedImage!);

    if (receipt != null && mounted) {
      setState(() {
        if (receipt.merchantName != null) {
          _merchantController.text = receipt.merchantName!;
        }
        if (receipt.totalAmount > 0) {
          _amountController.text = receipt.totalAmount.toInt().toString();
        }
      });
    }
  }

  Future<void> _confirmSave() async {
    final state = ref.read(receiptControllerProvider);
    final receipt = state.scannedReceipt;
    if (receipt == null) return;

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.expense,
          content: Text('Silakan pilih kategori pengeluaran terlebih dahulu.'),
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.replaceAll('.', '')) ??
        receipt.totalAmount;

    final success =
        await ref.read(receiptControllerProvider.notifier).confirmReceipt(
              receiptId: receipt.id,
              categoryId: _selectedCategoryId!,
              totalAmount: amount,
              merchantName: _merchantController.text.trim(),
              transactionDate: receipt.receiptDate ?? DateTime.now(),
              description: _merchantController.text.trim().isNotEmpty
                  ? 'Belanja di ${_merchantController.text.trim()}'
                  : 'Belanja via Scan Nota',
              notes: _notesController.text.trim(),
              items: receipt.items
                  .map((i) => ReceiptItemModel(
                        itemName: i.itemName,
                        quantity: i.quantity,
                        pricePerUnit: i.pricePerUnit,
                        totalPrice: i.totalPrice,
                      ))
                  .toList(),
            );

    if (success && mounted) {
      ref.read(transactionListControllerProvider.notifier).refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.income,
          content: Text('Struk berhasil dicatat ke transaksi!'),
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(receiptControllerProvider);
    final categoriesState = ref.watch(categoriesControllerProvider);
    final expenseCategories = categoriesState.categories
        .where((c) => c.type == 'expense')
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Scan Nota & Struk (OCR)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Neo-Glassmorphism Viewfinder Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderDark, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.borderDark,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  children: [
                    // Viewfinder area
                    Container(
                      height: 240,
                      width: double.infinity,
                      color: const Color(0xFF0F172A),
                      child: Stack(
                        children: [
                          if (_selectedImage != null)
                            Positioned.fill(
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.3),
                                          width: 1.5),
                                    ),
                                    child: const Icon(
                                      Icons.receipt_long_rounded,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Arahkan kamera ke struk belanja',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Scanner laser line when scanning
                          if (state.isScanning)
                            AnimatedBuilder(
                              animation: _scanAnimation,
                              builder: (context, child) {
                                return Positioned(
                                  top: 240 * _scanAnimation.value,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.8),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                          // Corner reticles for viewfinder aesthetic
                          Positioned(
                            top: 14,
                            left: 14,
                            child: _CornerBorder(top: true, left: true),
                          ),
                          Positioned(
                            top: 14,
                            right: 14,
                            child: _CornerBorder(top: true, left: false),
                          ),
                          Positioned(
                            bottom: 14,
                            left: 14,
                            child: _CornerBorder(top: false, left: true),
                          ),
                          Positioned(
                            bottom: 14,
                            right: 14,
                            child: _CornerBorder(top: false, left: false),
                          ),

                          // Frosted glass top badge
                          Positioned(
                            top: 12,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.45),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.3),
                                          width: 1),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.auto_awesome_rounded,
                                            size: 14, color: AppColors.income),
                                        SizedBox(width: 6),
                                        Text(
                                          'OCR Tesseract Otomatis',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tactile action buttons bottom bar
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        border: Border(
                          top: BorderSide(color: AppColors.borderDark, width: 2),
                        ),
                      ),
                      child: Row(
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
                                onPressed: state.isScanning
                                    ? null
                                    : () => _pickImage(ImageSource.camera),
                                icon: const Icon(Icons.camera_alt_rounded,
                                    color: Colors.white),
                                label: const Text('Buka Kamera',
                                    style: AppTextStyles.button),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
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
                                onPressed: state.isScanning
                                    ? null
                                    : () => _pickImage(ImageSource.gallery),
                                icon: const Icon(Icons.photo_library_rounded,
                                    color: AppColors.textPrimary),
                                label: const Text('Pilih Galeri',
                                    style: AppTextStyles.button),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: AppColors.surfaceVariant,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
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
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Scanning Status Banner
            if (state.isScanning)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
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
                  children: const [
                    CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Memindai struk dengan OCR Tesseract...',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),

            // Extracted OCR Data Section
            if (state.scannedReceipt != null) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.incomeLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderDark, width: 1.5),
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: AppColors.income, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Hasil Ekstraksi Nota',
                    style: AppTextStyles.headingSmall,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Merchant Field
              TextField(
                controller: _merchantController,
                style: AppTextStyles.bodyMedium,
                decoration: const InputDecoration(
                  labelText: 'Nama Toko / Merchant',
                  prefixIcon: Icon(Icons.storefront_rounded),
                ),
              ),
              const SizedBox(height: 12),

              // Total Amount Field
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: AppTextStyles.headingSmall,
                decoration: const InputDecoration(
                  labelText: 'Total Pembayaran (Rp)',
                  prefixIcon: Icon(Icons.payments_rounded),
                ),
              ),
              const SizedBox(height: 12),

              // Category Selector
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Kategori Pengeluaran',
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                items: expenseCategories.map((cat) {
                  return DropdownMenuItem(
                    value: cat.id,
                    child: Text(cat.name, style: AppTextStyles.bodyMedium),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCategoryId = val;
                  });
                },
              ),
              const SizedBox(height: 14),

              // Line Items list if available (Neo-brutalist cards)
              if (state.scannedReceipt!.items.isNotEmpty) ...[
                const Text(
                  'Daftar Belanjaan Terbaca:',
                  style: AppTextStyles.labelSmall,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderDark, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.borderDark,
                        offset: Offset(2.5, 2.5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    children: state.scannedReceipt!.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: AppColors.borderDark, width: 1),
                              ),
                              child: Text(
                                '${item.quantity.toInt()}x',
                                style: AppTextStyles.labelSmall.copyWith(
                                    fontWeight: FontWeight.w800, fontSize: 10),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.itemName,
                                style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              CurrencyFormatter.formatRupiah(item.totalPrice),
                              style: AppTextStyles.labelSmall.copyWith(
                                  fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Notes Field
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Catatan Tambahan (Opsional)',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 24),

              // Confirm and Save Button
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
                child: ElevatedButton.icon(
                  onPressed: state.isConfirming ? null : _confirmSave,
                  icon: state.isConfirming
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_rounded, color: Colors.white),
                  label: Text(
                    state.isConfirming
                        ? 'Menyimpan...'
                        : 'Konfirmasi & Simpan Transaksi',
                    style: AppTextStyles.button,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.income,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppColors.borderDark, width: 2),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CornerBorder extends StatelessWidget {
  final bool top;
  final bool left;

  const _CornerBorder({required this.top, required this.left});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border(
          top: top
              ? const BorderSide(color: Colors.white, width: 3)
              : BorderSide.none,
          bottom: !top
              ? const BorderSide(color: Colors.white, width: 3)
              : BorderSide.none,
          left: left
              ? const BorderSide(color: Colors.white, width: 3)
              : BorderSide.none,
          right: !left
              ? const BorderSide(color: Colors.white, width: 3)
              : BorderSide.none,
        ),
      ),
    );
  }
}
