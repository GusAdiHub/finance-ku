import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/local_transactions.dart';

part 'transactions_dao.g.dart';

@DriftAccessor(tables: [LocalTransactions])
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.db);

  /// Reactive stream of transactions matching optional filters.
  /// CRITICAL: Always excludes 'pending_delete' records so tombstoned items are hidden from UI.
  Stream<List<LocalTransaction>> watchTransactions({
    String? userId,
    String? type,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final query = select(localTransactions)
      ..where((tbl) => tbl.syncStatus.isNotValue('pending_delete'));

    if (userId != null) {
      query.where((tbl) => tbl.userId.equals(userId));
    }
    if (type != null) {
      query.where((tbl) => tbl.type.equals(type));
    }
    if (categoryId != null) {
      query.where((tbl) => tbl.categoryId.equals(categoryId));
    }
    if (startDate != null) {
      query.where((tbl) => tbl.transactionDate.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query.where((tbl) => tbl.transactionDate.isSmallerOrEqualValue(endDate));
    }

    query.orderBy([
      (tbl) => OrderingTerm(expression: tbl.transactionDate, mode: OrderingMode.desc),
      (tbl) => OrderingTerm(expression: tbl.clientUpdatedAt, mode: OrderingMode.desc),
    ]);

    return query.watch();
  }

  /// One-time fetch of filtered transactions (excluding tombstoned items)
  Future<List<LocalTransaction>> getTransactions({
    String? userId,
    String? type,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final query = select(localTransactions)
      ..where((tbl) => tbl.syncStatus.isNotValue('pending_delete'));

    if (userId != null) {
      query.where((tbl) => tbl.userId.equals(userId));
    }
    if (type != null) {
      query.where((tbl) => tbl.type.equals(type));
    }
    if (categoryId != null) {
      query.where((tbl) => tbl.categoryId.equals(categoryId));
    }
    if (startDate != null) {
      query.where((tbl) => tbl.transactionDate.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query.where((tbl) => tbl.transactionDate.isSmallerOrEqualValue(endDate));
    }

    query.orderBy([
      (tbl) => OrderingTerm(expression: tbl.transactionDate, mode: OrderingMode.desc),
      (tbl) => OrderingTerm(expression: tbl.clientUpdatedAt, mode: OrderingMode.desc),
    ]);

    return query.get();
  }

  /// Get single transaction by its local UUID
  Future<LocalTransaction?> getTransactionById(String id) {
    return (select(localTransactions)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Get single transaction by its remote server UUID
  Future<LocalTransaction?> getTransactionByRemoteId(String remoteId) {
    return (select(localTransactions)..where((tbl) => tbl.remoteId.equals(remoteId)))
        .getSingleOrNull();
  }

  /// Insert a newly created transaction (defaults to pending_create)
  Future<int> insertTransaction(LocalTransactionsCompanion entry) {
    return into(localTransactions).insert(entry);
  }

  /// Upsert transaction on conflict (used when pulling from server)
  Future<int> upsertTransaction(LocalTransactionsCompanion entry) {
    return into(localTransactions).insertOnConflictUpdate(entry);
  }

  /// Update an existing transaction locally.
  /// Automatically sets syncStatus to 'pending_update' if currently 'synced'.
  Future<bool> updateTransactionLocally(LocalTransactionsCompanion entry) async {
    return update(localTransactions).replace(entry);
  }

  /// Mark transaction as successfully synced with the server
  Future<int> markAsSynced(String localId, String serverRemoteId) {
    return (update(localTransactions)..where((tbl) => tbl.id.equals(localId))).write(
      LocalTransactionsCompanion(
        remoteId: Value(serverRemoteId),
        syncStatus: const Value('synced'),
        syncError: const Value(null),
        lastSyncedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  /// Mark transaction as failed with error description
  Future<int> markAsFailed(String localId, String errorMessage) async {
    final existing = await getTransactionById(localId);
    final nextRetry = (existing?.retryCount ?? 0) + 1;

    return (update(localTransactions)..where((tbl) => tbl.id.equals(localId))).write(
      LocalTransactionsCompanion(
        syncStatus: const Value('failed'),
        syncError: Value(errorMessage),
        retryCount: Value(nextRetry),
        clientUpdatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  /// Soft delete (Tombstone Pattern):
  /// - If the transaction was created offline and never pushed (remoteId == null), hard delete it immediately!
  /// - If it already exists on server (remoteId != null), mark as 'pending_delete' so SyncEngine can send HTTP DELETE.
  Future<void> softDeleteTransaction(String localId) async {
    final tx = await getTransactionById(localId);
    if (tx == null) return;

    if (tx.remoteId == null || tx.remoteId!.isEmpty) {
      // Never reached the server, delete permanently from SQLite
      await hardDeleteTransaction(localId);
    } else {
      // Mark as tombstone to push to server later
      await (update(localTransactions)..where((tbl) => tbl.id.equals(localId))).write(
        LocalTransactionsCompanion(
          syncStatus: const Value('pending_delete'),
          clientUpdatedAt: Value(DateTime.now().toUtc()),
        ),
      );
    }
  }

  /// Hard delete permanently removes the row from SQLite
  Future<int> hardDeleteTransaction(String localId) {
    return (delete(localTransactions)..where((tbl) => tbl.id.equals(localId))).go();
  }

  /// Fetch all transactions waiting to be synchronized to FastAPI server.
  /// Ordered chronologically by client modification time.
  Future<List<LocalTransaction>> getPendingSyncQueue({String? userId}) {
    final query = select(localTransactions)
      ..where((tbl) => tbl.syncStatus.isIn([
            'pending_create',
            'pending_update',
            'pending_delete',
          ]));

    if (userId != null) {
      query.where((tbl) => tbl.userId.equals(userId));
    }

    query.orderBy([
      (tbl) => OrderingTerm(expression: tbl.clientUpdatedAt, mode: OrderingMode.asc),
    ]);

    return query.get();
  }

  // =========================================================================
  // LOCAL AGGREGATIONS ENGINE (0ms Latency Dashboard & Reports)
  // =========================================================================

  /// Watch recent transactions for dashboard preview (default 5 items)
  Stream<List<LocalTransaction>> watchRecentTransactions({
    String? userId,
    int limit = 5,
  }) {
    final query = select(localTransactions)
      ..where((tbl) => tbl.syncStatus.isNotValue('pending_delete'));

    if (userId != null) {
      query.where((tbl) => tbl.userId.equals(userId));
    }

    query.orderBy([
      (tbl) => OrderingTerm(expression: tbl.transactionDate, mode: OrderingMode.desc),
      (tbl) => OrderingTerm(expression: tbl.clientUpdatedAt, mode: OrderingMode.desc),
    ]);
    query.limit(limit);

    return query.watch();
  }

  /// Local reactive calculation of total income
  Stream<double> watchTotalIncome({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return watchTransactions(
      userId: userId,
      type: 'income',
      startDate: startDate,
      endDate: endDate,
    ).map((transactions) {
      return transactions.fold<double>(
        0.0,
        (sum, tx) => sum + (double.tryParse(tx.amount) ?? 0.0),
      );
    });
  }

  /// Local reactive calculation of total expense
  Stream<double> watchTotalExpense({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return watchTransactions(
      userId: userId,
      type: 'expense',
      startDate: startDate,
      endDate: endDate,
    ).map((transactions) {
      return transactions.fold<double>(
        0.0,
        (sum, tx) => sum + (double.tryParse(tx.amount) ?? 0.0),
      );
    });
  }

  /// Local reactive calculation of net balance (Income - Expense)
  Stream<double> watchNetBalance({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return watchTransactions(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    ).map((transactions) {
      double totalIncome = 0.0;
      double totalExpense = 0.0;
      for (final tx in transactions) {
        final amount = double.tryParse(tx.amount) ?? 0.0;
        if (tx.type == 'income') {
          totalIncome += amount;
        } else if (tx.type == 'expense') {
          totalExpense += amount;
        }
      }
      return totalIncome - totalExpense;
    });
  }

  /// Calculate category breakdown (Total amount and count per category)
  Future<Map<String, double>> getCategoryBreakdown({
    String? userId,
    required String type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final transactions = await getTransactions(
      userId: userId,
      type: type,
      startDate: startDate,
      endDate: endDate,
    );

    final Map<String, double> breakdown = {};
    for (final tx in transactions) {
      final amount = double.tryParse(tx.amount) ?? 0.0;
      breakdown[tx.categoryId] = (breakdown[tx.categoryId] ?? 0.0) + amount;
    }

    return breakdown;
  }
}
