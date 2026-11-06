import 'sync_result.dart';

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
  paused,
}

class SyncState {
  final SyncStatus status;
  final bool isConnected;
  final int pendingCount;
  final DateTime? lastSyncedAt;
  final String? errorMessage;
  final SyncResult? lastResult;

  const SyncState({
    this.status = SyncStatus.idle,
    this.isConnected = true,
    this.pendingCount = 0,
    this.lastSyncedAt,
    this.errorMessage,
    this.lastResult,
  });

  bool get isSyncing => status == SyncStatus.syncing;
  bool get isOffline => !isConnected;
  bool get hasPending => pendingCount > 0;
  bool get isPaused => status == SyncStatus.paused;

  SyncState copyWith({
    SyncStatus? status,
    bool? isConnected,
    int? pendingCount,
    DateTime? lastSyncedAt,
    String? errorMessage,
    SyncResult? lastResult,
    bool clearError = false,
  }) {
    return SyncState(
      status: status ?? this.status,
      isConnected: isConnected ?? this.isConnected,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastResult: lastResult ?? this.lastResult,
    );
  }

  @override
  String toString() =>
      'SyncState(status: $status, connected: $isConnected, pending: $pendingCount, lastSync: $lastSyncedAt)';
}
