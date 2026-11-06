import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';

class TransactionListState {
  final List<TransactionEntity> transactions;
  final String selectedType; // 'all' | 'expense' | 'income'
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;

  const TransactionListState({
    required this.transactions,
    this.selectedType = 'all',
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
  });

  List<TransactionEntity> get filteredTransactions {
    var result = transactions;
    if (selectedType != 'all') {
      result = result.where((t) => t.type == selectedType).toList();
    }
    if (searchQuery.trim().isNotEmpty) {
      final query = searchQuery.trim().toLowerCase();
      result = result.where((t) {
        final desc = t.description?.toLowerCase() ?? '';
        final cat = t.categoryName?.toLowerCase() ?? '';
        final notes = t.notes?.toLowerCase() ?? '';
        return desc.contains(query) || cat.contains(query) || notes.contains(query);
      }).toList();
    }
    return result;
  }

  TransactionListState copyWith({
    List<TransactionEntity>? transactions,
    String? selectedType,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TransactionListState(
      transactions: transactions ?? this.transactions,
      selectedType: selectedType ?? this.selectedType,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final transactionListControllerProvider =
    NotifierProvider<TransactionListController, TransactionListState>(
  TransactionListController.new,
);

class TransactionListController extends Notifier<TransactionListState> {
  late final TransactionRepository _repository;

  @override
  TransactionListState build() {
    _repository = ref.watch(transactionRepositoryProvider);
    _initListener();
    return const TransactionListState(transactions: [], isLoading: true);
  }

  void _initListener() {
    _repository.watchTransactions().listen((list) {
      state = state.copyWith(
        transactions: list,
        isLoading: false,
      );
    });
  }

  void setTypeFilter(String type) {
    if (state.selectedType != type) {
      state = state.copyWith(selectedType: type);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<bool> createTransaction({
    required String type,
    required double amount,
    required String categoryId,
    required DateTime transactionDate,
    String? description,
    String? notes,
    String inputMethod = 'manual',
  }) async {
    try {
      await _repository.createTransaction(
        type: type,
        amount: amount,
        categoryId: categoryId,
        transactionDate: transactionDate,
        description: description,
        notes: notes,
        inputMethod: inputMethod,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Gagal mencatat transaksi: $e');
      return false;
    }
  }

  Future<bool> deleteTransaction(String id) async {
    try {
      await _repository.deleteTransaction(id);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Gagal menghapus transaksi: $e');
      return false;
    }
  }

  Future<void> refresh() async {
    await _repository.syncPendingTransactions();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
