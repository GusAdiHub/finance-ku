import 'dart:async';
import '../entities/sync_result.dart';
import '../entities/sync_state.dart';

abstract class SyncEngine {
  /// Execute complete two-way synchronization: Push local queue, then Pull server updates.
  Future<SyncResult> synchronize({bool force = false});

  /// Push locally queued operations (pending_create, pending_update, pending_delete) to FastAPI.
  Future<SyncResult> pushPendingQueue();

  /// Pull remote updates (categories and transactions) from FastAPI and reconcile with local SQLite.
  Future<SyncResult> pullRemoteUpdates();

  /// Get the current total count of items pending sync in local storage.
  Future<int> getPendingCount();

  /// Reactive stream of sync status changes.
  Stream<SyncState> get syncStateStream;

  /// Current synchronous state snapshot.
  SyncState get currentState;

  /// Clean up streams and listeners.
  void dispose();
}
