/// Result of a synchronization cycle
class SyncResult {
  final bool success;
  final int pushedCount;
  final int pulledCount;
  final int failedCount;
  final List<String> errors;
  final DateTime timestamp;

  const SyncResult({
    required this.success,
    this.pushedCount = 0,
    this.pulledCount = 0,
    this.failedCount = 0,
    this.errors = const [],
    required this.timestamp,
  });

  factory SyncResult.empty() => SyncResult(
        success: true,
        timestamp: DateTime.now().toUtc(),
      );

  factory SyncResult.failure(String error) => SyncResult(
        success: false,
        failedCount: 1,
        errors: [error],
        timestamp: DateTime.now().toUtc(),
      );

  bool get hasErrors => errors.isNotEmpty || failedCount > 0;
  int get totalProcessed => pushedCount + pulledCount;

  @override
  String toString() =>
      'SyncResult(success: $success, pushed: $pushedCount, pulled: $pulledCount, failed: $failedCount, errors: ${errors.length})';
}
