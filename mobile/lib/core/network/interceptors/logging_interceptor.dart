import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Debug Logging Interceptor with strict sanitization of Auth credentials
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      final sanitizedHeaders = Map<String, dynamic>.from(options.headers);
      if (sanitizedHeaders.containsKey('Authorization')) {
        sanitizedHeaders['Authorization'] = 'Bearer [REDACTED]';
      }

      debugPrint('--> ${options.method} ${options.uri}');
      debugPrint('Headers: $sanitizedHeaders');
      if (options.data != null) {
        debugPrint('Body: ${options.data}');
      }
    }
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('<-- ${response.statusCode} ${response.requestOptions.uri}');
      debugPrint('Response: ${response.data}');
    }
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('<-- ERROR ${err.response?.statusCode} ${err.requestOptions.uri}');
      debugPrint('Error Message: ${err.message}');
      if (err.response?.data != null) {
        debugPrint('Error Data: ${err.response?.data}');
      }
    }
    return handler.next(err);
  }
}
