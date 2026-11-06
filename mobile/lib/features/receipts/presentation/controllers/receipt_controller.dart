import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/receipt_remote_datasource.dart';
import '../../data/models/receipt_model.dart';
import '../../domain/entities/receipt_entity.dart';

final receiptRemoteDataSourceProvider =
    Provider<ReceiptRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return ReceiptRemoteDataSourceImpl(dio);
});

class ReceiptState {
  final bool isScanning;
  final bool isConfirming;
  final ReceiptEntity? scannedReceipt;
  final String? errorMessage;
  final String? successMessage;

  const ReceiptState({
    this.isScanning = false,
    this.isConfirming = false,
    this.scannedReceipt,
    this.errorMessage,
    this.successMessage,
  });

  ReceiptState copyWith({
    bool? isScanning,
    bool? isConfirming,
    ReceiptEntity? scannedReceipt,
    String? errorMessage,
    String? successMessage,
    bool clearReceipt = false,
    bool clearError = false,
  }) {
    return ReceiptState(
      isScanning: isScanning ?? this.isScanning,
      isConfirming: isConfirming ?? this.isConfirming,
      scannedReceipt:
          clearReceipt ? null : (scannedReceipt ?? this.scannedReceipt),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: successMessage ?? this.successMessage,
    );
  }
}

final receiptControllerProvider =
    NotifierProvider<ReceiptController, ReceiptState>(ReceiptController.new);

class ReceiptController extends Notifier<ReceiptState> {
  late final ReceiptRemoteDataSource _remoteDataSource;

  @override
  ReceiptState build() {
    _remoteDataSource = ref.watch(receiptRemoteDataSourceProvider);
    return const ReceiptState();
  }

  Future<ReceiptModel?> scanReceipt(File imageFile, {String? merchantName}) async {
    state = state.copyWith(isScanning: true, clearError: true);
    try {
      final receipt = await _remoteDataSource.uploadReceipt(
        imageFile,
        merchantName: merchantName,
      );
      state = state.copyWith(
        isScanning: false,
        scannedReceipt: receipt,
      );
      return receipt;
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  Future<bool> confirmReceipt({
    required String receiptId,
    required String categoryId,
    required double totalAmount,
    String? merchantName,
    DateTime? transactionDate,
    String? description,
    String? notes,
    List<ReceiptItemModel>? items,
  }) async {
    state = state.copyWith(isConfirming: true, clearError: true);
    try {
      await _remoteDataSource.confirmReceipt(
        receiptId: receiptId,
        categoryId: categoryId,
        totalAmount: totalAmount,
        merchantName: merchantName,
        transactionDate: transactionDate,
        description: description,
        notes: notes,
        items: items,
      );
      state = state.copyWith(
        isConfirming: false,
        clearReceipt: true,
        successMessage: 'Transaksi struk berhasil dicatat!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isConfirming: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void reset() {
    state = const ReceiptState();
  }
}
