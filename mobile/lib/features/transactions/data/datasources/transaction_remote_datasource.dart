import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/transaction_model.dart';

abstract class TransactionRemoteDataSource {
  Future<TransactionModel> createTransaction(TransactionModel model);

  Future<TransactionModel> updateTransaction(
    String remoteId,
    Map<String, dynamic> delta,
  );

  Future<void> deleteTransaction(String remoteId);

  Future<List<TransactionModel>> getTransactions({
    int page = 1,
    int pageSize = 50,
    String? type,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  });
}

class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  final Dio _dio;

  TransactionRemoteDataSourceImpl(this._dio);

  @override
  Future<TransactionModel> createTransaction(TransactionModel model) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.transactions,
        data: model.toJson(),
      );
      return TransactionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is Exception) {
        throw e.error!;
      }
      throw ServerException(e.message ?? 'Gagal membuat transaksi di server.');
    }
  }

  @override
  Future<TransactionModel> updateTransaction(
    String remoteId,
    Map<String, dynamic> delta,
  ) async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.transactionById(remoteId),
        data: delta,
      );
      return TransactionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is Exception) {
        throw e.error!;
      }
      throw ServerException(e.message ?? 'Gagal memperbarui transaksi.');
    }
  }

  @override
  Future<void> deleteTransaction(String remoteId) async {
    try {
      await _dio.delete(ApiEndpoints.transactionById(remoteId));
    } on DioException catch (e) {
      if (e.error is Exception) {
        throw e.error!;
      }
      throw ServerException(e.message ?? 'Gagal menghapus transaksi di server.');
    }
  }

  @override
  Future<List<TransactionModel>> getTransactions({
    int page = 1,
    int pageSize = 50,
    String? type,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (type != null) queryParams['type'] = type;
      if (categoryId != null) queryParams['category_id'] = categoryId;
      if (startDate != null) {
        queryParams['start_date'] = startDate.toUtc().toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toUtc().toIso8601String();
      }

      final response = await _dio.get(
        ApiEndpoints.transactions,
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('items')) {
        final items = data['items'] as List<dynamic>;
        return items
            .map((item) => TransactionModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.error is Exception) {
        throw e.error!;
      }
      throw ServerException(e.message ?? 'Gagal memuat transaksi dari server.');
    }
  }
}
