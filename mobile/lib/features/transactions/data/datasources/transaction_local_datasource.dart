import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../domain/entities/transaction_entity.dart';

abstract class TransactionLocalDataSource {
  Future<TransactionEntity> insertTransaction({
    required String type,
    required double amount,
    required String categoryId,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
    required DateTime transactionDate,
    String? description,
    String? notes,
    String inputMethod = 'manual',
    required String userId,
  });

  Future<TransactionEntity> updateTransaction(TransactionEntity transaction);

  Future<void> deleteTransaction(String id);

  Future<TransactionEntity?> getTransactionById(String id);

  Future<List<TransactionEntity>> getTransactions({
    String? type,
    String? categoryId,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
  });

  Stream<List<TransactionEntity>> watchTransactions({
    String? type,
    String? categoryId,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<List<TransactionEntity>> getPendingSyncQueue();

  Future<void> markAsSynced({
    required String localId,
    required String remoteId,
  });

  Future<void> markAsFailed({
    required String localId,
    required String errorMessage,
  });

  Future<void> upsertFromRemote(List<TransactionEntity> remoteTransactions);

  Future<void> clearTransactions();
}

class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  final List<TransactionEntity> _storage = [];
  final _streamController = StreamController<List<TransactionEntity>>.broadcast();
  static const _uuid = Uuid();

  @override
  Future<TransactionEntity> insertTransaction({
    required String type,
    required double amount,
    required String categoryId,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
    required DateTime transactionDate,
    String? description,
    String? notes,
    String inputMethod = 'manual',
    required String userId,
  }) async {
    final now = DateTime.now().toUtc();
    final localId = _uuid.v4();

    final entry = TransactionEntity(
      id: localId,
      remoteId: null, // Null indicates local-only creation pending server sync
      type: type,
      amount: amount,
      amountString: amount.toStringAsFixed(2),
      categoryId: categoryId,
      categoryName: categoryName,
      categoryIcon: categoryIcon,
      categoryColor: categoryColor,
      transactionDate: transactionDate.toUtc(),
      description: description,
      notes: notes,
      inputMethod: inputMethod,
      userId: userId,
      syncStatus: 'pending_create',
      createdAt: now,
      updatedAt: now,
      clientUpdatedAt: now,
    );

    _storage.add(entry);
    _emitUpdate();
    return entry;
  }

  @override
  Future<TransactionEntity> updateTransaction(TransactionEntity transaction) async {
    final now = DateTime.now().toUtc();
    final index = _storage.indexWhere((t) => t.id == transaction.id);

    if (index >= 0) {
      final existing = _storage[index];
      // Keep 'pending_create' if it was never pushed to remote server
      final newSyncStatus =
          existing.syncStatus == 'pending_create' ? 'pending_create' : 'pending_update';

      final updated = transaction.copyWith(
        syncStatus: newSyncStatus,
        clientUpdatedAt: now,
        updatedAt: now,
      );

      _storage[index] = updated;
      _emitUpdate();
      return updated;
    }

    _storage.add(transaction);
    _emitUpdate();
    return transaction;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final index = _storage.indexWhere((t) => t.id == id);
    if (index < 0) return;

    final existing = _storage[index];

    if (existing.remoteId == null || existing.remoteId!.isEmpty) {
      // Transaction created offline and never pushed to server: delete physically
      _storage.removeAt(index);
    } else {
      // Transaction already exists on server: mark as tombstone (pending_delete)
      _storage[index] = existing.copyWith(
        syncStatus: 'pending_delete',
        clientUpdatedAt: DateTime.now().toUtc(),
      );
    }

    _emitUpdate();
  }

  @override
  Future<TransactionEntity?> getTransactionById(String id) async {
    final list = _storage.where((t) => t.id == id && t.syncStatus != 'pending_delete');
    return list.isNotEmpty ? list.first : null;
  }

  @override
  Future<List<TransactionEntity>> getTransactions({
    String? type,
    String? categoryId,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _applyFilters(
      _storage,
      type: type,
      categoryId: categoryId,
      search: search,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Stream<List<TransactionEntity>> watchTransactions({
    String? type,
    String? categoryId,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
  }) async* {
    yield await getTransactions(
      type: type,
      categoryId: categoryId,
      search: search,
      startDate: startDate,
      endDate: endDate,
    );

    yield* _streamController.stream.map((list) {
      return _applyFilters(
        list,
        type: type,
        categoryId: categoryId,
        search: search,
        startDate: startDate,
        endDate: endDate,
      );
    });
  }

  @override
  Future<List<TransactionEntity>> getPendingSyncQueue() async {
    return _storage
        .where((t) =>
            t.syncStatus == 'pending_create' ||
            t.syncStatus == 'pending_update' ||
            t.syncStatus == 'pending_delete')
        .toList()
      ..sort((a, b) => a.clientUpdatedAt.compareTo(b.clientUpdatedAt));
  }

  @override
  Future<void> markAsSynced({
    required String localId,
    required String remoteId,
  }) async {
    final index = _storage.indexWhere((t) => t.id == localId);
    if (index >= 0) {
      final item = _storage[index];
      if (item.syncStatus == 'pending_delete') {
        // Successfully deleted from remote server, remove row permanently
        _storage.removeAt(index);
      } else {
        _storage[index] = item.copyWith(
          remoteId: remoteId,
          syncStatus: 'synced',
          syncError: null,
          lastSyncedAt: DateTime.now().toUtc(),
        );
      }
      _emitUpdate();
    }
  }

  @override
  Future<void> markAsFailed({
    required String localId,
    required String errorMessage,
  }) async {
    final index = _storage.indexWhere((t) => t.id == localId);
    if (index >= 0) {
      final item = _storage[index];
      _storage[index] = item.copyWith(
        syncStatus: 'failed',
        syncError: errorMessage,
        retryCount: item.retryCount + 1,
        clientUpdatedAt: DateTime.now().toUtc(),
      );
      _emitUpdate();
    }
  }

  @override
  Future<void> upsertFromRemote(List<TransactionEntity> remoteTransactions) async {
    for (final remote in remoteTransactions) {
      final index = _storage.indexWhere((t) => t.remoteId == remote.remoteId);
      if (index >= 0) {
        final local = _storage[index];
        // Only overwrite with server data if there are no pending local edits
        if (local.syncStatus == 'synced') {
          _storage[index] = remote.copyWith(id: local.id);
        }
      } else {
        _storage.add(remote);
      }
    }
    _emitUpdate();
  }

  @override
  Future<void> clearTransactions() async {
    _storage.clear();
    _emitUpdate();
  }

  List<TransactionEntity> _applyFilters(
    List<TransactionEntity> list, {
    String? type,
    String? categoryId,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    // Exclude tombstoned items
    var result = list.where((t) => t.syncStatus != 'pending_delete').toList();

    if (type != null && type.isNotEmpty) {
      result = result.where((t) => t.type == type).toList();
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      result = result.where((t) => t.categoryId == categoryId).toList();
    }
    if (startDate != null) {
      result = result.where((t) => !t.transactionDate.isBefore(startDate)).toList();
    }
    if (endDate != null) {
      result = result.where((t) => !t.transactionDate.isAfter(endDate)).toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      final query = search.trim().toLowerCase();
      result = result.where((t) {
        final desc = t.description?.toLowerCase() ?? '';
        final cat = t.categoryName?.toLowerCase() ?? '';
        final notes = t.notes?.toLowerCase() ?? '';
        return desc.contains(query) || cat.contains(query) || notes.contains(query);
      }).toList();
    }

    // Sort descending by transactionDate then clientUpdatedAt
    result.sort((a, b) {
      final comp = b.transactionDate.compareTo(a.transactionDate);
      if (comp != 0) return comp;
      return b.clientUpdatedAt.compareTo(a.clientUpdatedAt);
    });

    return result;
  }

  void _emitUpdate() {
    _streamController.add(List.unmodifiable(_storage));
  }
}
