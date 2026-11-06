import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../categories/presentation/controllers/categories_controller.dart';
import '../../../transactions/data/repositories/transaction_repository_impl.dart';
import '../../../transactions/presentation/controllers/transaction_list_controller.dart';
import '../controllers/voice_controller.dart';

class VoiceInputModal extends ConsumerStatefulWidget {
  const VoiceInputModal({super.key});

  @override
  ConsumerState<VoiceInputModal> createState() => _VoiceInputModalState();
}

class _VoiceInputModalState extends ConsumerState<VoiceInputModal>
    with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  bool _isSaving = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<String> _presets = [
    'Makan siang di warteg 25 ribu',
    'Beli bensin pertalite 50000',
    'Beli kopi susu 18 ribu',
    'Gaji bulanan 7 juta',
    'Bayar tagihan listrik 150 ribu',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submitText(String text) async {
    if (text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    _textController.text = text;
    await ref.read(voiceControllerProvider.notifier).parseVoiceText(text);
  }

  Future<void> _saveParsedTransaction() async {
    final state = ref.read(voiceControllerProvider);
    final parsed = state.parsedResult;
    if (parsed == null || parsed.amount == null || parsed.amount! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.expense,
          content: Text('Nominal transaksi belum valid.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final categoriesState = ref.read(categoriesControllerProvider);
      final categories = categoriesState.categories;

      String categoryId = '';
      if (parsed.suggestedCategoryId != null) {
        categoryId = parsed.suggestedCategoryId!;
      } else {
        final matches = categories.where((c) =>
            c.type == parsed.type &&
            (parsed.suggestedCategoryName == null ||
                c.name.toLowerCase().contains(
                    parsed.suggestedCategoryName!.toLowerCase())));
        if (matches.isNotEmpty) {
          categoryId = matches.first.id;
        } else {
          final fallback =
              categories.where((c) => c.type == parsed.type).toList();
          if (fallback.isNotEmpty) categoryId = fallback.first.id;
        }
      }

      final repository = ref.read(transactionRepositoryProvider);
      await repository.createTransaction(
        type: parsed.type,
        amount: parsed.amount!,
        categoryId: categoryId,
        transactionDate: DateTime.now(),
        description: parsed.description ?? parsed.rawText,
        notes: 'Dicatat via Input Suara: "${parsed.rawText}"',
        inputMethod: 'voice',
      );

      ref.read(transactionListControllerProvider.notifier).refresh();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.income,
            content: Text(
                'Transaksi berhasil disimpan: ${CurrencyFormatter.formatRupiah(parsed.amount!)}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.expense,
            content: Text('Gagal menyimpan: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceControllerProvider);
    final parsed = voiceState.parsedResult;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 16,
            left: 20,
            right: 20,
          ),
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Neo-brutalist Handle
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

                  // Header with pulsing glass mic icon
                  Row(
                    children: [
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.incomeLight,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.borderDark, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.borderDark,
                                offset: Offset(2, 2),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.mic_rounded,
                            color: AppColors.income,
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.incomeLight,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: AppColors.borderDark, width: 1),
                              ),
                              child: Text(
                                'NLP BAHASA INDONESIA',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.income,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Input Transaksi Suara',
                              style: AppTextStyles.headingSmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Input Box (Neo-brutalist)
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
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            style: AppTextStyles.bodyMedium,
                            decoration: const InputDecoration(
                              hintText: 'Katakan atau ketik transaksi...',
                              prefixIcon:
                                  Icon(Icons.record_voice_over_rounded),
                              fillColor: AppColors.surface,
                            ),
                            onSubmitted: _submitText,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: voiceState.isProcessing
                              ? null
                              : () => _submitText(_textController.text),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(
                                  color: AppColors.borderDark, width: 1.8),
                            ),
                          ),
                          child: voiceState.isProcessing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick presets with tactile Neo-brutalist buttons
                  const Text(
                    'Contoh Cepat Kalimat Sehari-Hari:',
                    style: AppTextStyles.labelSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _presets.map((preset) {
                      return InkWell(
                        onTap: () => _submitText(preset),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.borderDark, width: 1.5),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.borderDark,
                                offset: Offset(1.5, 1.5),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Text(
                            preset,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Parsed result preview card (Neo-glassmorphism with Neo-brutalism)
                  if (parsed != null) ...[
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: parsed.type == 'income'
                            ? AppColors.incomeLight
                            : AppColors.expenseLight,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.borderDark,
                          width: 2,
                        ),
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
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: parsed.type == 'income'
                                      ? AppColors.income
                                      : AppColors.expense,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: AppColors.borderDark, width: 1.2),
                                ),
                                child: Text(
                                  parsed.type == 'income'
                                      ? 'PEMASUKAN'
                                      : 'PENGELUARAN',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              Text(
                                'Akurasi: ${(parsed.confidenceScore * 100).toInt()}%',
                                style: AppTextStyles.labelSmall.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            parsed.amount != null
                                ? CurrencyFormatter.formatRupiah(parsed.amount!)
                                : 'Rp 0',
                            style: AppTextStyles.headingLarge.copyWith(
                              color: parsed.type == 'income'
                                  ? const Color(0xFF047857)
                                  : const Color(0xFFB91C1C),
                              fontSize: 26,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            parsed.description ?? parsed.rawText,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (parsed.suggestedCategoryName != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.tag_rounded,
                                    size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  'Kategori: ${parsed.suggestedCategoryName}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
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
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveParsedTransaction,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle_rounded,
                                color: Colors.white),
                        label: Text(
                          _isSaving
                              ? 'Menyimpan...'
                              : 'Simpan ke Transaksi Sekarang',
                          style: AppTextStyles.button,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.income,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(
                                color: AppColors.borderDark, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
