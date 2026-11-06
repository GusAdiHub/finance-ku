import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/sync/domain/entities/sync_result.dart';
import 'package:mobile/features/sync/domain/entities/sync_state.dart';

void main() {
  group('SyncResult Tests', () {
    test('empty creates successful result with 0 processed items', () {
      final res = SyncResult.empty();
      expect(res.success, isTrue);
      expect(res.pushedCount, 0);
      expect(res.pulledCount, 0);
      expect(res.failedCount, 0);
      expect(res.hasErrors, isFalse);
      expect(res.totalProcessed, 0);
    });

    test('failure creates unsuccessful result with error message', () {
      final res = SyncResult.failure('Koneksi timeout');
      expect(res.success, isFalse);
      expect(res.failedCount, 1);
      expect(res.hasErrors, isTrue);
      expect(res.errors, contains('Koneksi timeout'));
    });

    test('totalProcessed sums pushed and pulled counts', () {
      final res = SyncResult(
        success: true,
        pushedCount: 5,
        pulledCount: 12,
        timestamp: DateTime.now(),
      );
      expect(res.totalProcessed, 17);
      expect(res.hasErrors, isFalse);
    });
  });

  group('SyncState Tests', () {
    test('initial state defaults to idle and connected', () {
      const state = SyncState();
      expect(state.status, SyncStatus.idle);
      expect(state.isConnected, isTrue);
      expect(state.isOffline, isFalse);
      expect(state.isSyncing, isFalse);
      expect(state.hasPending, isFalse);
      expect(state.pendingCount, 0);
    });

    test('status getters reflect state accurately', () {
      const syncing = SyncState(status: SyncStatus.syncing);
      expect(syncing.isSyncing, isTrue);

      const offline = SyncState(isConnected: false);
      expect(offline.isOffline, isTrue);

      const pending = SyncState(pendingCount: 4);
      expect(pending.hasPending, isTrue);

      const paused = SyncState(status: SyncStatus.paused);
      expect(paused.isPaused, isTrue);
    });

    test('copyWith updates fields and clearError works', () {
      const state = SyncState(
        status: SyncStatus.error,
        errorMessage: 'Something went wrong',
      );

      final updated = state.copyWith(
        status: SyncStatus.success,
        clearError: true,
      );

      expect(updated.status, SyncStatus.success);
      expect(updated.errorMessage, isNull);
    });
  });
}
