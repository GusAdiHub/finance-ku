import '../entities/transaction_entity.dart';

/// Contract definition for Transaction management and Offline-First operations
abstract class TransactionRepository {
  /// Reactive stream of local transactions (instantly reflects offline adds/edits/deletes)
  Stream<List<TransactionEntity>> watchTransactions({
    String? type,
    String? categoryId,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Snapshot fetch of local transactions
  Future<List<TransactionEntity>> getTransactions({
    String? type,
    String? categoryId,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Get single transaction by its local ID
  Future<TransactionEntity?> getTransactionById(String id);

  /// Instantly saves a transaction to local SQLite with status 'pending_create'
  /// Generates a local UUID v4, returning immediately with zero UI latency
  Future<TransactionEntity> createTransaction({
    required String type,
    required double amount,
    required String categoryId,
    required DateTime transactionDate,
    String? description,
    String? notes,
    String inputMethod = 'manual',
  });

  /// Updates an existing transaction locally.
  /// If already synced, updates status to 'pending_update'.
  Future<TransactionEntity> updateTransaction(TransactionEntity transaction);

  /// Soft deletes transaction (Tombstone Pattern):
  /// - If local only (never reached server): deletes immediately.
  /// - If on server: marks as 'pending_delete' to push deletion when online.
  Future<void> deleteTransaction(String id);

  /// Fetches transactions queued for synchronization
  Future<List<TransactionEntity>> getPendingSyncQueue();

  /// Attempts background push of pending transactions to FastAPI server
  Future<void> syncPendingTransactions();
}
