import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/errors/exceptions.dart';
import 'package:mobile/core/network/network_info.dart';
import 'package:mobile/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:mobile/features/auth/data/models/user_model.dart';
import 'package:mobile/features/categories/data/datasources/category_local_datasource.dart';
import 'package:mobile/features/categories/data/datasources/category_remote_datasource.dart';
import 'package:mobile/features/categories/data/models/category_model.dart';
import 'package:mobile/features/sync/data/services/sync_engine_impl.dart';
import 'package:mobile/features/sync/domain/entities/sync_state.dart';
import 'package:mobile/features/transactions/data/datasources/transaction_local_datasource.dart';
import 'package:mobile/features/transactions/data/datasources/transaction_remote_datasource.dart';
import 'package:mobile/features/transactions/data/models/transaction_model.dart';

class FakeNetworkInfo implements NetworkInfo {
  bool connected = true;
  final _controller = StreamController<bool>.broadcast();

  @override
  Future<bool> get isConnected async => connected;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  void setConnected(bool value) {
    connected = value;
    _controller.add(value);
  }
}

class FakeAuthLocalDataSource implements AuthLocalDataSource {
  String? token = 'jwt-fake-secret';

  @override
  Future<bool> hasToken() async => token != null;

  @override
  Future<String?> getAccessToken() async => token;

  @override
  Future<void> clearAuthData() async {
    token = null;
  }

  @override
  Future<void> clearRememberedUsername() async {}

  @override
  Future<UserModel?> getCachedUser() async => null;

  @override
  Future<String?> getRememberedUsername() async => null;

  @override
  Future<void> saveAuthData({required String token, required UserModel user}) async {
    this.token = token;
  }

  @override
  Future<void> saveRememberedUsername(String username) async {}
}

class FakeTransactionRemoteDataSource implements TransactionRemoteDataSource {
  final List<TransactionModel> serverStore = [];
  bool shouldThrowUnauthorized = false;
  int createCallCount = 0;
  int updateCallCount = 0;
  int deleteCallCount = 0;

  @override
  Future<TransactionModel> createTransaction(TransactionModel model) async {
    if (shouldThrowUnauthorized) {
      throw const UnauthorizedException('Invalid or expired token.');
    }
    createCallCount++;
    final created = TransactionModel(
      id: 'srv-${model.id}',
      type: model.type,
      amount: model.amount,
      categoryId: model.categoryId,
      transactionDate: model.transactionDate,
      description: model.description,
      notes: model.notes,
      ownerUserId: 'user-001',
      inputMethod: model.inputMethod,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );
    serverStore.add(created);
    return created;
  }

  @override
  Future<TransactionModel> updateTransaction(
    String remoteId,
    Map<String, dynamic> delta,
  ) async {
    if (shouldThrowUnauthorized) {
      throw const UnauthorizedException('Invalid or expired token.');
    }
    updateCallCount++;
    final index = serverStore.indexWhere((t) => t.id == remoteId);
    if (index >= 0) {
      final existing = serverStore[index];
      final updated = TransactionModel(
        id: existing.id,
        type: (delta['type'] as String?) ?? existing.type,
        amount: (delta['amount'] as String?) ?? existing.amount,
        categoryId: (delta['category_id'] as String?) ?? existing.categoryId,
        transactionDate: delta['transaction_date'] != null
            ? DateTime.parse(delta['transaction_date'] as String)
            : existing.transactionDate,
        description: (delta['description'] as String?) ?? existing.description,
        notes: (delta['notes'] as String?) ?? existing.notes,
        ownerUserId: existing.ownerUserId,
        inputMethod: existing.inputMethod,
      );
      serverStore[index] = updated;
      return updated;
    }
    throw const ServerException('404 Transaction Not Found');
  }

  @override
  Future<void> deleteTransaction(String remoteId) async {
    if (shouldThrowUnauthorized) {
      throw const UnauthorizedException('Invalid or expired token.');
    }
    deleteCallCount++;
    serverStore.removeWhere((t) => t.id == remoteId);
  }

  @override
  Future<List<TransactionModel>> getTransactions({
    int page = 1,
    int pageSize = 50,
    String? type,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (shouldThrowUnauthorized) {
      throw const UnauthorizedException('Invalid or expired token.');
    }
    return List.unmodifiable(serverStore);
  }
}

class FakeCategoryRemoteDataSource implements CategoryRemoteDataSource {
  final List<CategoryModel> categories = [
    const CategoryModel(
      id: 'cat-srv-1',
      name: 'Makanan & Minuman',
      type: 'expense',
      isSystem: true,
    ),
  ];

  @override
  Future<List<CategoryModel>> getCategories({String? type}) async => categories;

  @override
  Future<CategoryModel> createCategory({
    required String name,
    required String type,
    String? icon,
    String? color,
  }) async {
    final cat = CategoryModel(id: 'cat-new-1', name: name, type: type);
    categories.add(cat);
    return cat;
  }

  @override
  Future<void> deleteCategory(String id) async {
    categories.removeWhere((c) => c.id == id);
  }
}

void main() {
  group('Two-Way Synchronization Engine Tests', () {
    late TransactionLocalDataSource localTx;
    late FakeTransactionRemoteDataSource remoteTx;
    late CategoryLocalDataSource localCat;
    late FakeCategoryRemoteDataSource remoteCat;
    late FakeNetworkInfo networkInfo;
    late FakeAuthLocalDataSource authLocal;
    late SyncEngineImpl syncEngine;

    setUp(() {
      localTx = TransactionLocalDataSourceImpl();
      remoteTx = FakeTransactionRemoteDataSource();
      localCat = CategoryLocalDataSourceImpl();
      remoteCat = FakeCategoryRemoteDataSource();
      networkInfo = FakeNetworkInfo();
      authLocal = FakeAuthLocalDataSource();

      syncEngine = SyncEngineImpl(
        transactionLocal: localTx,
        transactionRemote: remoteTx,
        categoryLocal: localCat,
        categoryRemote: remoteCat,
        networkInfo: networkInfo,
        authLocal: authLocal,
      );
    });

    tearDown(() {
      syncEngine.dispose();
    });

    test('Push pending_create: pushes local transaction and updates to synced with remoteId', () async {
      // 1. User records transaction offline
      final tx = await localTx.insertTransaction(
        type: 'expense',
        amount: 75000.0,
        categoryId: 'cat-srv-1',
        transactionDate: DateTime.now(),
        description: 'Makan Siang',
        userId: 'user-001',
      );

      expect(tx.syncStatus, 'pending_create');
      expect(await syncEngine.getPendingCount(), 1);

      // 2. Synchronize
      final result = await syncEngine.synchronize();

      expect(result.success, isTrue);
      expect(result.pushedCount, 1);
      expect(remoteTx.createCallCount, 1);

      // 3. Verify local state after sync
      final afterSync = await localTx.getTransactionById(tx.id);
      expect(afterSync?.syncStatus, 'synced');
      expect(afterSync?.remoteId, startsWith('srv-'));
      expect(await syncEngine.getPendingCount(), 0);
    });

    test('Push pending_update: pushes modifications to existing server transaction', () async {
      // 1. Insert & sync initial transaction
      final tx = await localTx.insertTransaction(
        type: 'expense',
        amount: 50000.0,
        categoryId: 'cat-srv-1',
        transactionDate: DateTime.now(),
        userId: 'user-001',
      );
      await syncEngine.synchronize();

      final syncedTx = await localTx.getTransactionById(tx.id);
      expect(syncedTx?.syncStatus, 'synced');

      // 2. User edits offline
      final edited = syncedTx!.copyWith(amount: 65000.0, amountString: '65000.00');
      await localTx.updateTransaction(edited);

      expect(await syncEngine.getPendingCount(), 1);

      // 3. Reconnect & sync
      final result = await syncEngine.synchronize();
      expect(result.success, isTrue);
      expect(result.pushedCount, 1);
      expect(remoteTx.updateCallCount, 1);

      // 4. Verify local state
      final afterUpdateSync = await localTx.getTransactionById(tx.id);
      expect(afterUpdateSync?.syncStatus, 'synced');
      expect(afterUpdateSync?.amount, 65000.0);
    });

    test('Push pending_delete: pushes tombstone deletion to server and purges local row', () async {
      // 1. Insert & sync initial transaction
      final tx = await localTx.insertTransaction(
        type: 'income',
        amount: 2000000.0,
        categoryId: 'cat-srv-1',
        transactionDate: DateTime.now(),
        userId: 'user-001',
      );
      await syncEngine.synchronize();

      // 2. User deletes transaction offline
      await localTx.deleteTransaction(tx.id);

      // Hidden from regular UI queries, but preserved in sync queue
      final visibleList = await localTx.getTransactions();
      expect(visibleList.any((t) => t.id == tx.id), isFalse);
      expect(await syncEngine.getPendingCount(), 1);

      // 3. Reconnect & sync
      final result = await syncEngine.synchronize();
      expect(result.success, isTrue);
      expect(result.pushedCount, 1);
      expect(remoteTx.deleteCallCount, 1);

      // 4. Tombstone is physically removed from storage
      expect(await syncEngine.getPendingCount(), 0);
    });

    test('Pull Remote Updates: reconciles transactions created on other devices into local storage', () async {
      // 1. Simulate transaction created via Web / other device in remote backend
      final remoteItem = TransactionModel(
        id: 'srv-web-999',
        type: 'income',
        amount: '15000000.00',
        categoryId: 'cat-srv-1',
        transactionDate: DateTime.now().toUtc(),
        description: 'Bonus Kinerja Web',
        ownerUserId: 'user-001',
      );
      remoteTx.serverStore.add(remoteItem);

      // 2. Sync pull
      final result = await syncEngine.synchronize();
      expect(result.success, isTrue);
      expect(result.pulledCount, greaterThanOrEqualTo(1));

      // 3. Check local storage
      final localList = await localTx.getTransactions();
      final pulled = localList.firstWhere((t) => t.remoteId == 'srv-web-999');
      expect(pulled.amount, 15000000.0);
      expect(pulled.description, 'Bonus Kinerja Web');
      expect(pulled.syncStatus, 'synced');
    });

    test('Offline Mode: skips network push/pull and maintains pending queue safely', () async {
      // 1. Switch device to offline
      networkInfo.setConnected(false);

      await localTx.insertTransaction(
        type: 'expense',
        amount: 30000.0,
        categoryId: 'cat-srv-1',
        transactionDate: DateTime.now(),
        userId: 'user-001',
      );

      final result = await syncEngine.synchronize();

      expect(result.success, isFalse);
      expect(result.errors.first, contains('offline'));
      expect(syncEngine.currentState.isConnected, isFalse);
      expect(await syncEngine.getPendingCount(), 1);
      expect(remoteTx.createCallCount, 0); // No network calls executed
    });

    test('HTTP 401 Session Expiry: pauses sync engine WITHOUT dropping local database', () async {
      // 1. Add pending offline transactions
      await localTx.insertTransaction(
        type: 'expense',
        amount: 45000.0,
        categoryId: 'cat-srv-1',
        transactionDate: DateTime.now(),
        description: 'Penting jangan dihapus',
        userId: 'user-001',
      );

      // 2. Simulate token expired on server
      remoteTx.shouldThrowUnauthorized = true;

      final result = await syncEngine.synchronize();

      expect(result.success, isFalse);
      expect(syncEngine.currentState.status, SyncStatus.paused);

      // 3. CRITICAL VERIFICATION: Local database transactions are NOT wiped!
      final localList = await localTx.getTransactions();
      expect(localList.length, 1);
      expect(localList.first.description, 'Penting jangan dihapus');
      expect(await syncEngine.getPendingCount(), 1);
    });
  });
}
