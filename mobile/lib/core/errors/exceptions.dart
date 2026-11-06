/// Custom Exceptions thrown within Data Layer
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException(this.message, {this.statusCode});

  @override
  String toString() => 'ServerException(statusCode: $statusCode, message: $message)';
}

class UnauthorizedException implements Exception {
  final String message;

  const UnauthorizedException([this.message = 'Sesi telah berakhir atau kredensial tidak valid.']);

  @override
  String toString() => 'UnauthorizedException($message)';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException([this.message = 'Koneksi internet bermasalah. Periksa jaringan Anda.']);

  @override
  String toString() => 'NetworkException($message)';
}

class CacheException implements Exception {
  final String message;

  const CacheException(this.message);

  @override
  String toString() => 'CacheException($message)';
}

class SyncException implements Exception {
  final String message;

  const SyncException(this.message);

  @override
  String toString() => 'SyncException($message)';
}

class ValidationException implements Exception {
  final String message;

  const ValidationException(this.message);

  @override
  String toString() => 'ValidationException($message)';
}
