import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/transactions/data/datasources/transaction_local_datasource.dart';

void main() {
  group('TransactionLocalDataSource Tests (Offline-First Engine)', () {
    late TransactionLocalDataSource dataSource;

    setUp(() {
      dataSource = TransactionLocalDataSourceImpl();
    });

    test('insertTransaction creates local UUID and sets syncStatus to pending_create', () async {
      final tx = await dataSource.insertTransaction(
        type: 'expense',
        amount: 35000.0,
        categoryId: 'cat-1',
        categoryName: 'Makanan & Minuman',
        transactionDate: DateTime.now(),
        description: 'Bakso Malang',
        userId: 'user-001',
      );

      expect(tx.id, isNotEmpty);
      expect(tx.remoteId, isNull);
      expect(tx.syncStatus, 'pending_create');
      expect(tx.amount, 35000.0);
      expect(tx.isPending, isTrue);

      final list = await dataSource.getTransactions();
      expect(list.length, 1);
      expect(list.first.id, tx.id);
    });

    test('updateTransaction sets syncStatus to pending_update if already synced', () async {
      final tx = await dataSource.insertTransaction(
        type: 'expense',
        amount: 35000.0,
        categoryId: 'cat-1',
        transactionDate: DateTime.now(),
        userId: 'user-001',
      );

      // Simulate it was synced with server
      await dataSource.markAsSynced(localId: tx.id, remoteId: 'srv-tx-999');
      final syncedTx = await dataSource.getTransactionById(tx.id);
      expect(syncedTx?.syncStatus, 'synced');
      expect(syncedTx?.remoteId, 'srv-tx-999');

      // Now edit offline
      final edited = syncedTx!.copyWith(amount: 40000.0, amountString: '40000.00');
      await dataSource.updateTransaction(edited);

      final afterEdit = await dataSource.getTransactionById(tx.id);
      expect(afterEdit?.amount, 40000.0);
      expect(afterEdit?.syncStatus, 'pending_update');
    });

    test('deleteTransaction hard deletes local-only records instantly', () async {
      final tx = await dataSource.insertTransaction(
        type: 'expense',
        amount: 25000.0,
        categoryId: 'cat-1',
        transactionDate: DateTime.now(),
        userId: 'user-001',
      );

      expect(tx.remoteId, isNull);
      await dataSource.deleteTransaction(tx.id);

      final queue = await dataSource.getPendingSyncQueue();
      expect(queue.any((t) => t.id == tx.id), isFalse);

      final list = await dataSource.getTransactions();
      expect(list.any((t) => t.id == tx.id), isFalse);
    });

    test('deleteTransaction sets pending_delete (Tombstone) for records existing on server', () async {
      final tx = await dataSource.insertTransaction(
        type: 'income',
        amount: 500000.0,
        categoryId: 'cat-inc-1',
        transactionDate: DateTime.now(),
        userId: 'user-001',
      );

      await dataSource.markAsSynced(localId: tx.id, remoteId: 'srv-tx-888');

      // User deletes offline
      await dataSource.deleteTransaction(tx.id);

      // 1. Transaction is hidden from regular transaction lists / UI
      final visibleList = await dataSource.getTransactions();
      expect(visibleList.any((t) => t.id == tx.id), isFalse);

      // 2. Transaction remains in pending sync queue as tombstone
      final queue = await dataSource.getPendingSyncQueue();
      final tombstone = queue.firstWhere((t) => t.id == tx.id);
      expect(tombstone.syncStatus, 'pending_delete');
      expect(tombstone.remoteId, 'srv-tx-888');

      // 3. When server confirms deletion, markAsSynced physically removes the tombstone
      await dataSource.markAsSynced(localId: tx.id, remoteId: 'srv-tx-888');
      final finalQueue = await dataSource.getPendingSyncQueue();
      expect(finalQueue.any((t) => t.id == tx.id), isFalse);
    });

    test('getTransactions filters properly by type and search query', () async {
      await dataSource.insertTransaction(
        type: 'expense',
        amount: 50000.0,
        categoryId: 'cat-1',
        description: 'Makan Siang Nasi Padang',
        transactionDate: DateTime.now(),
        userId: 'user-001',
      );
      await dataSource.insertTransaction(
        type: 'income',
        amount: 5000000.0,
        categoryId: 'cat-2',
        description: 'Gaji Pokok November',
        transactionDate: DateTime.now(),
        userId: 'user-001',
      );

      final expenseOnly = await dataSource.getTransactions(type: 'expense');
      expect(expenseOnly.length, 1);
      expect(expenseOnly.first.type, 'expense');

      final searchResult = await dataSource.getTransactions(search: 'padang');
      expect(searchResult.length, 1);
      expect(searchResult.first.description, 'Makan Siang Nasi Padang');
    });
  });
}
