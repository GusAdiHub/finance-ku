import 'package:dio/dio.dart';
import '../../constants/api_endpoints.dart';
import '../../storage/secure_storage_service.dart';

/// Injects Bearer token from SecureStorageService into authorized requests
class AuthInterceptor extends Interceptor {
  final SecureStorageService _storageService;

  AuthInterceptor(this._storageService);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip token injection for public authentication routes
    final isPublicAuthRoute = options.path.contains(ApiEndpoints.login) ||
        options.path.contains(ApiEndpoints.register);

    if (!isPublicAuthRoute && !options.headers.containsKey('Authorization')) {
      final token = await _storageService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    return handler.next(options);
  }
}
