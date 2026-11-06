import 'package:dio/dio.dart';
import '../../errors/exceptions.dart';
import '../../storage/secure_storage_service.dart';

/// Intercepts Dio HTTP errors and transforms them into domain exceptions.
/// Special handling for HTTP 401: marks session expired without touching local SQLite data.
class ErrorInterceptor extends Interceptor {
  final SecureStorageService _storageService;

  ErrorInterceptor(this._storageService);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    final statusCode = response?.statusCode;

    // --- 1. Handle HTTP 401 Unauthorized (Expired / Invalid JWT) ---
    if (statusCode == 401) {
      await _storageService.setSessionExpired(true);
      return handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          type: err.type,
          error: const UnauthorizedException(
            'Sesi telah berakhir demi keamanan. Silakan login kembali.',
          ),
        ),
      );
    }

    // --- 2. Handle Network / Connection Errors ---
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          type: err.type,
          error: const NetworkException(
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
          ),
        ),
      );
    }

    // --- 3. Handle Backend Server Errors (Extract FastAPI detail) ---
    String errorMessage = 'Terjadi kesalahan pada server.';
    if (response?.data != null) {
      final data = response!.data;
      if (data is Map<String, dynamic> && data.containsKey('detail')) {
        final detail = data['detail'];
        if (detail is String) {
          errorMessage = detail;
        } else if (detail is List && detail.isNotEmpty) {
          final first = detail.first;
          if (first is Map && first.containsKey('msg')) {
            errorMessage = first['msg'].toString();
          } else {
            errorMessage = detail.toString();
          }
        }
      }
    }

    return handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: ServerException(errorMessage, statusCode: statusCode),
      ),
    );
  }
}
