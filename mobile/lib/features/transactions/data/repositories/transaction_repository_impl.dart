import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../categories/data/datasources/category_local_datasource.dart';
import '../../../categories/data/repositories/category_repository_impl.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_local_datasource.dart';
import '../datasources/transaction_remote_datasource.dart';
import '../models/transaction_model.dart';

final transactionRemoteDataSourceProvider =
    Provider<TransactionRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return TransactionRemoteDataSourceImpl(dio);
});

final transactionLocalDataSourceProvider =
    Provider<TransactionLocalDataSource>((ref) {
  return TransactionLocalDataSourceImpl();
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final remoteDataSource = ref.watch(transactionRemoteDataSourceProvider);
  final localDataSource = ref.watch(transactionLocalDataSourceProvider);
  final categoryLocalDataSource = ref.watch(categoryLocalDataSourceProvider);
  final storageService = ref.watch(secureStorageServiceProvider);
  final networkInfo = ref.watch(networkInfoProvider);

  return TransactionRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
    categoryLocalDataSource: categoryLocalDataSource,
    storageService: storageService,
    networkInfo: networkInfo,
  );
});

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteDataSource _remoteDataSource;
  final TransactionLocalDataSource _localDataSource;
  final CategoryLocalDataSource _categoryLocalDataSource;
  final SecureStorageService _storageService;
  final NetworkInfo _networkInfo;

  TransactionRepositoryImpl({
    required TransactionRemoteDataSource remoteDataSource,
    required TransactionLocalDataSource localDataSource,
    required CategoryLocalDataSource categoryLocalDataSource,
    required SecureStorageService storageService,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _categoryLocalDataSource = categoryLocalDataSource,
        _storageService = storageService,
        _networkInfo = networkInfo;

  @override
  Stream<List<TransactionEntity>> watchTransactions({
    String? type,
    String? categoryId,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _localDataSource.watchTransactions(
      type: type,
      categoryId: categoryId,
      search: search,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<List<TransactionEntity>> getTransactions({
    String? type,
    String? categoryId,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _localDataSource.getTransactions(
      type: type,
      categoryId: categoryId,
      search: search,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<TransactionEntity?> getTransactionById(String id) {
    return _localDataSource.getTransactionById(id);
  }

  @override
  Future<TransactionEntity> createTransaction({
    required String type,
    required double amount,
    required String categoryId,
    required DateTime transactionDate,
    String? description,
    String? notes,
    String inputMethod = 'manual',
  }) async {
    final userId = (await _storageService.getUserId()) ?? '';

    // Enrich with category name, icon, and color from local cache
    final categories = await _categoryLocalDataSource.getCategories();
    final matchingCat = categories.where((c) => c.id == categoryId);
    final category = matchingCat.isNotEmpty ? matchingCat.first : null;

    // 1. Instant local persistence (Zero UI Latency)
    final localTx = await _localDataSource.insertTransaction(
      type: type,
      amount: amount,
      categoryId: categoryId,
      categoryName: category?.name,
      categoryIcon: category?.icon,
      categoryColor: category?.color,
      transactionDate: transactionDate,
      description: description,
      notes: notes,
      inputMethod: inputMethod,
      userId: userId,
    );

    // 2. Opportunistic background push if connected
    _triggerBackgroundSync();

    return localTx;
  }

  @override
  Future<TransactionEntity> updateTransaction(TransactionEntity transaction) async {
    final updated = await _localDataSource.updateTransaction(transaction);
    _triggerBackgroundSync();
    return updated;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _localDataSource.deleteTransaction(id);
    _triggerBackgroundSync();
  }

  @override
  Future<List<TransactionEntity>> getPendingSyncQueue() {
    return _localDataSource.getPendingSyncQueue();
  }

  @override
  Future<void> syncPendingTransactions() async {
    final isOnline = await _networkInfo.isConnected;
    if (!isOnline) return;

    final queue = await _localDataSource.getPendingSyncQueue();
    if (queue.isEmpty) return;

    for (final item in queue) {
      try {
        if (item.syncStatus == 'pending_create') {
          final model = TransactionModel.fromEntity(item);
          final serverResponse = await _remoteDataSource.createTransaction(model);
          await _localDataSource.markAsSynced(
            localId: item.id,
            remoteId: serverResponse.id,
          );
        } else if (item.syncStatus == 'pending_update') {
          if (item.remoteId != null && item.remoteId!.isNotEmpty) {
            await _remoteDataSource.updateTransaction(
              item.remoteId!,
              {
                'type': item.type,
                'amount': item.amountString,
                'category_id': item.categoryId,
                'transaction_date': item.transactionDate.toUtc().toIso8601String(),
                'description': item.description,
                'notes': item.notes,
              },
            );
            await _localDataSource.markAsSynced(
              localId: item.id,
              remoteId: item.remoteId!,
            );
          }
        } else if (item.syncStatus == 'pending_delete') {
          if (item.remoteId != null && item.remoteId!.isNotEmpty) {
            await _remoteDataSource.deleteTransaction(item.remoteId!);
            await _localDataSource.markAsSynced(
              localId: item.id,
              remoteId: item.remoteId!,
            );
          }
        }
      } catch (e) {
        await _localDataSource.markAsFailed(
          localId: item.id,
          errorMessage: e.toString(),
        );
      }
    }
  }

  void _triggerBackgroundSync() {
    // Non-blocking fire and forget sync
    Future.microtask(() async {
      try {
        await syncPendingTransactions();
      } catch (_) {}
    });
  }
}
