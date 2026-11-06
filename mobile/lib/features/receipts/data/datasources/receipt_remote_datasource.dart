import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/receipt_model.dart';

abstract class ReceiptRemoteDataSource {
  Future<ReceiptModel> uploadReceipt(File imageFile, {String? merchantName});
  Future<void> confirmReceipt({
    required String receiptId,
    required String categoryId,
    required double totalAmount,
    String? merchantName,
    DateTime? transactionDate,
    String? description,
    String? notes,
    List<ReceiptItemModel>? items,
  });
}

class ReceiptRemoteDataSourceImpl implements ReceiptRemoteDataSource {
  final Dio _dio;

  ReceiptRemoteDataSourceImpl(this._dio);

  @override
  Future<ReceiptModel> uploadReceipt(File imageFile, {String? merchantName}) async {
    try {
      final fileName = imageFile.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
        if (merchantName != null && merchantName.isNotEmpty)
          'merchant_name': merchantName,
      });

      final response = await _dio.post(
        ApiEndpoints.receipts,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ReceiptModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException(
          response.data['detail'] ?? 'Gagal memproses struk OCR.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      final detail = e.response?.data is Map
          ? (e.response?.data['detail'] ?? e.message)
          : e.message;
      throw ServerException(
        detail?.toString() ?? 'Gagal mengunggah foto struk.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error upload receipt: ${e.toString()}');
    }
  }

  @override
  Future<void> confirmReceipt({
    required String receiptId,
    required String categoryId,
    required double totalAmount,
    String? merchantName,
    DateTime? transactionDate,
    String? description,
    String? notes,
    List<ReceiptItemModel>? items,
  }) async {
    try {
      final payload = <String, dynamic>{
        'category_id': categoryId,
        'total_amount': totalAmount,
        'target_scope': 'personal',
        if (merchantName != null) 'merchant_name': merchantName,
        if (transactionDate != null)
          'transaction_date': transactionDate.toUtc().toIso8601String(),
        if (description != null) 'description': description,
        if (notes != null) 'notes': notes,
        if (items != null) 'items': items.map((i) => i.toJson()).toList(),
      };

      final response = await _dio.post(
        ApiEndpoints.receiptConfirm(receiptId),
        data: payload,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(
          response.data['detail'] ?? 'Gagal mengonfirmasi transaksi struk.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      final detail = e.response?.data is Map
          ? (e.response?.data['detail'] ?? e.message)
          : e.message;
      throw ServerException(
        detail?.toString() ?? 'Gagal konfirmasi transaksi struk.',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
