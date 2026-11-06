/// Failure representations for Domain and Presentation Layers
abstract class Failure {
  final String message;

  const Failure(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure(super.message, {this.statusCode});
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Sesi telah berakhir. Silakan login kembali.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Tidak ada koneksi internet. Data tersimpan secara lokal.']);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class SyncFailure extends Failure {
  const SyncFailure(super.message);
}
