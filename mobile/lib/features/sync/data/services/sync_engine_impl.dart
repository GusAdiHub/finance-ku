import 'dart:async';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import '../../../categories/data/datasources/category_local_datasource.dart';
import '../../../categories/data/datasources/category_remote_datasource.dart';
import '../../../transactions/data/datasources/transaction_local_datasource.dart';
import '../../../transactions/data/datasources/transaction_remote_datasource.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../domain/entities/sync_result.dart';
import '../../domain/entities/sync_state.dart';
import '../../domain/services/sync_engine.dart';

class SyncEngineImpl implements SyncEngine {
  final TransactionLocalDataSource _transactionLocal;
  final TransactionRemoteDataSource _transactionRemote;
  final CategoryLocalDataSource _categoryLocal;
  final CategoryRemoteDataSource _categoryRemote;
  final NetworkInfo _networkInfo;
  final AuthLocalDataSource _authLocal;

  final _stateController = StreamController<SyncState>.broadcast();
  SyncState _currentState = const SyncState();
  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _debounceTimer;
  bool _isSyncInProgress = false;

  SyncEngineImpl({
    required TransactionLocalDataSource transactionLocal,
    required TransactionRemoteDataSource transactionRemote,
    required CategoryLocalDataSource categoryLocal,
    required CategoryRemoteDataSource categoryRemote,
    required NetworkInfo networkInfo,
    required AuthLocalDataSource authLocal,
  })  : _transactionLocal = transactionLocal,
        _transactionRemote = transactionRemote,
        _categoryLocal = categoryLocal,
        _categoryRemote = categoryRemote,
        _networkInfo = networkInfo,
        _authLocal = authLocal {
    _init();
  }

  void _init() {
    _setupConnectivityListener();
    _refreshInitialState();
  }

  Future<void> _refreshInitialState() async {
    final connected = await _networkInfo.isConnected;
    final pending = await getPendingCount();
    _updateState(_currentState.copyWith(
      isConnected: connected,
      pendingCount: pending,
    ));
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = _networkInfo.onConnectivityChanged.listen((isConnected) {
      _updateState(_currentState.copyWith(isConnected: isConnected));

      if (isConnected) {
        // Auto-sync debounced by 1 second when device comes back online
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
          synchronize();
        });
      }
    });
  }

  void _updateState(SyncState newState) {
    _currentState = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  @override
  SyncState get currentState => _currentState;

  @override
  Stream<SyncState> get syncStateStream => _stateController.stream;

  @override
  Future<int> getPendingCount() async {
    final queue = await _transactionLocal.getPendingSyncQueue();
    return queue.length;
  }

  @override
  Future<SyncResult> synchronize({bool force = false}) async {
    // Avoid concurrent overlapping sync runs
    if (_isSyncInProgress && !force) {
      return SyncResult(
        success: false,
        errors: const ['Sinkronisasi sedang berjalan.'],
        timestamp: DateTime.now().toUtc(),
      );
    }

    final isConnected = await _networkInfo.isConnected;
    if (!isConnected) {
      final pending = await getPendingCount();
      _updateState(_currentState.copyWith(
        status: SyncStatus.idle,
        isConnected: false,
        pendingCount: pending,
        errorMessage: 'Tidak ada koneksi internet (Mode Offline).',
      ));
      return SyncResult(
        success: false,
        errors: const ['Perangkat sedang offline.'],
        timestamp: DateTime.now().toUtc(),
      );
    }

    final hasToken = await _authLocal.hasToken();
    if (!hasToken) {
      _updateState(_currentState.copyWith(
        status: SyncStatus.paused,
        errorMessage: 'Belum login atau sesi telah berakhir.',
      ));
      return SyncResult(
        success: false,
        errors: const ['Autentikasi diperlukan.'],
        timestamp: DateTime.now().toUtc(),
      );
    }

    _isSyncInProgress = true;
    _updateState(_currentState.copyWith(
      status: SyncStatus.syncing,
      clearError: true,
    ));

    final errors = <String>[];
    int totalPushed = 0;
    int totalPulled = 0;
    int totalFailed = 0;

    try {
      // Step 1: Push local queue to server
      final pushResult = await pushPendingQueue();
      totalPushed += pushResult.pushedCount;
      totalFailed += pushResult.failedCount;
      errors.addAll(pushResult.errors);

      // If token expired during push, stop further requests
      if (_currentState.status == SyncStatus.paused) {
        _isSyncInProgress = false;
        return pushResult;
      }

      // Step 2: Pull latest updates from server
      final pullResult = await pullRemoteUpdates();
      totalPulled += pullResult.pulledCount;
      totalFailed += pullResult.failedCount;
      errors.addAll(pullResult.errors);

      final finalPending = await getPendingCount();
      final finalResult = SyncResult(
        success: errors.isEmpty,
        pushedCount: totalPushed,
        pulledCount: totalPulled,
        failedCount: totalFailed,
        errors: errors,
        timestamp: DateTime.now().toUtc(),
      );

      _updateState(_currentState.copyWith(
        status: errors.isEmpty ? SyncStatus.success : SyncStatus.error,
        pendingCount: finalPending,
        lastSyncedAt: DateTime.now().toUtc(),
        lastResult: finalResult,
        errorMessage: errors.isNotEmpty ? errors.first : null,
      ));

      _isSyncInProgress = false;
      return finalResult;
    } catch (e) {
      _isSyncInProgress = false;
      final finalPending = await getPendingCount();
      final errResult = SyncResult.failure(e.toString());
      _updateState(_currentState.copyWith(
        status: SyncStatus.error,
        pendingCount: finalPending,
        errorMessage: e.toString(),
        lastResult: errResult,
      ));
      return errResult;
    }
  }

  @override
  Future<SyncResult> pushPendingQueue() async {
    final queue = await _transactionLocal.getPendingSyncQueue();
    if (queue.isEmpty) {
      return SyncResult.empty();
    }

    int pushedCount = 0;
    int failedCount = 0;
    final errors = <String>[];

    for (final item in queue) {
      try {
        if (item.syncStatus == 'pending_create') {
          // Push new transaction to FastAPI
          final model = TransactionModel.fromEntity(item);
          final response = await _transactionRemote.createTransaction(model);

          // Update local entity with server remote ID and mark synced
          await _transactionLocal.markAsSynced(
            localId: item.id,
            remoteId: response.id,
          );
          pushedCount++;
        } else if (item.syncStatus == 'pending_update') {
          // If remoteId is not assigned yet, skip until next cycle
          if (item.remoteId == null || item.remoteId!.isEmpty) {
            continue;
          }

          final delta = <String, dynamic>{
            'type': item.type,
            'amount': item.amountString,
            'category_id': item.categoryId,
            'transaction_date': item.transactionDate.toUtc().toIso8601String(),
          };
          if (item.description != null) delta['description'] = item.description;
          if (item.notes != null) delta['notes'] = item.notes;

          await _transactionRemote.updateTransaction(item.remoteId!, delta);
          await _transactionLocal.markAsSynced(
            localId: item.id,
            remoteId: item.remoteId!,
          );
          pushedCount++;
        } else if (item.syncStatus == 'pending_delete') {
          // Tombstone deletion
          if (item.remoteId == null || item.remoteId!.isEmpty) {
            // Never pushed to server: hard delete locally
            await _transactionLocal.markAsSynced(
              localId: item.id,
              remoteId: '',
            );
            pushedCount++;
          } else {
            try {
              await _transactionRemote.deleteTransaction(item.remoteId!);
            } on ServerException catch (e) {
              // If already 404 (deleted on server), treat as success
              if (!e.message.contains('404')) {
                rethrow;
              }
            }
            await _transactionLocal.markAsSynced(
              localId: item.id,
              remoteId: item.remoteId!,
            );
            pushedCount++;
          }
        }
      } on UnauthorizedException {
        // HTTP 401: Token expired or invalid
        // CRITICAL: NEVER wipe the local database!
        _updateState(_currentState.copyWith(
          status: SyncStatus.paused,
          errorMessage: 'Sesi berakhir. Masuk kembali untuk melanjutkan sinkronisasi.',
        ));
        errors.add('Sesi kedaluwarsa (401 Unauthorized).');
        break; // Stop further requests
      } on ValidationException catch (e) {
        // Business logic or validation error (e.g. invalid category)
        failedCount++;
        errors.add(e.message);
        await _transactionLocal.markAsFailed(
          localId: item.id,
          errorMessage: e.message,
        );
      } on ServerException catch (e) {
        failedCount++;
        errors.add(e.message);
        await _transactionLocal.markAsFailed(
          localId: item.id,
          errorMessage: e.message,
        );
      } catch (e) {
        // Unexpected network or transient error: break queue processing to preserve order
        failedCount++;
        errors.add(e.toString());
        break;
      }
    }

    return SyncResult(
      success: errors.isEmpty,
      pushedCount: pushedCount,
      failedCount: failedCount,
      errors: errors,
      timestamp: DateTime.now().toUtc(),
    );
  }

  @override
  Future<SyncResult> pullRemoteUpdates() async {
    int pulledCount = 0;
    final errors = <String>[];

    try {
      // 1. Pull Categories
      final remoteCategories = await _categoryRemote.getCategories();
      if (remoteCategories.isNotEmpty) {
        await _categoryLocal.saveCategories(remoteCategories);
        pulledCount += remoteCategories.length;
      }

      // 2. Pull Transactions
      final remoteTransactions = await _transactionRemote.getTransactions(
        page: 1,
        pageSize: 100,
      );

      if (remoteTransactions.isNotEmpty) {
        final domainEntities = remoteTransactions.map((model) {
          return model.toEntity(
            localId: model.id,
            syncStatus: 'synced',
          );
        }).toList();

        await _transactionLocal.upsertFromRemote(domainEntities);
        pulledCount += domainEntities.length;
      }

      return SyncResult(
        success: true,
        pulledCount: pulledCount,
        timestamp: DateTime.now().toUtc(),
      );
    } on UnauthorizedException {
      _updateState(_currentState.copyWith(
        status: SyncStatus.paused,
        errorMessage: 'Sesi berakhir saat menarik data dari server.',
      ));
      return SyncResult.failure('Sesi kedaluwarsa.');
    } catch (e) {
      errors.add(e.toString());
      return SyncResult(
        success: false,
        failedCount: 1,
        errors: errors,
        timestamp: DateTime.now().toUtc(),
      );
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _connectivitySubscription?.cancel();
    _stateController.close();
  }
}
