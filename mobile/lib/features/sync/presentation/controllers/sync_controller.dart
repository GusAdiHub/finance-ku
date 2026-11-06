import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/network_info.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../categories/data/repositories/category_repository_impl.dart';
import '../../../transactions/data/repositories/transaction_repository_impl.dart';
import '../../data/services/sync_engine_impl.dart';
import '../../domain/entities/sync_result.dart';
import '../../domain/entities/sync_state.dart';
import '../../domain/services/sync_engine.dart';

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final transactionLocal = ref.watch(transactionLocalDataSourceProvider);
  final transactionRemote = ref.watch(transactionRemoteDataSourceProvider);
  final categoryLocal = ref.watch(categoryLocalDataSourceProvider);
  final categoryRemote = ref.watch(categoryRemoteDataSourceProvider);
  final networkInfo = ref.watch(networkInfoProvider);
  final authLocal = ref.watch(authLocalDataSourceProvider);

  final engine = SyncEngineImpl(
    transactionLocal: transactionLocal,
    transactionRemote: transactionRemote,
    categoryLocal: categoryLocal,
    categoryRemote: categoryRemote,
    networkInfo: networkInfo,
    authLocal: authLocal,
  );

  ref.onDispose(() {
    engine.dispose();
  });

  return engine;
});

final syncControllerProvider =
    NotifierProvider<SyncController, SyncState>(
  SyncController.new,
);

class SyncController extends Notifier<SyncState> {
  late final SyncEngine _engine;
  StreamSubscription<SyncState>? _subscription;

  @override
  SyncState build() {
    _engine = ref.watch(syncEngineProvider);
    _subscription = _engine.syncStateStream.listen((newState) {
      state = newState;
    });
    ref.onDispose(() {
      _subscription?.cancel();
    });
    return _engine.currentState;
  }

  /// Trigger manual synchronization cycle
  Future<SyncResult> syncNow({bool force = false}) async {
    return await _engine.synchronize(force: force);
  }

  /// Refresh the count of pending un-synced items
  Future<void> refreshPendingCount() async {
    final count = await _engine.getPendingCount();
    state = state.copyWith(pendingCount: count);
  }
}
