import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/category_repository.dart';

class CategoriesState {
  final List<CategoryEntity> categories;
  final String selectedTab; // 'expense' or 'income'
  final bool isLoading;
  final String? errorMessage;

  const CategoriesState({
    required this.categories,
    this.selectedTab = 'expense',
    this.isLoading = false,
    this.errorMessage,
  });

  List<CategoryEntity> get filteredCategories {
    return categories.where((c) => c.type == selectedTab).toList();
  }

  CategoriesState copyWith({
    List<CategoryEntity>? categories,
    String? selectedTab,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CategoriesState(
      categories: categories ?? this.categories,
      selectedTab: selectedTab ?? this.selectedTab,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final categoriesControllerProvider =
    NotifierProvider<CategoriesController, CategoriesState>(
  CategoriesController.new,
);

class CategoriesController extends Notifier<CategoriesState> {
  late final CategoryRepository _repository;

  @override
  CategoriesState build() {
    _repository = ref.watch(categoryRepositoryProvider);
    _initCategories();
    return const CategoriesState(categories: [], isLoading: true);
  }

  Future<void> _initCategories() async {
    // 1. Listen to reactive stream from local database
    _repository.watchCategories().listen((list) {
      state = state.copyWith(
        categories: list,
        isLoading: false,
      );
    });

    // 2. Refresh from remote FastAPI in background
    await loadCategories(forceRefresh: true);
  }

  Future<void> loadCategories({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repository.getCategories(forceRefresh: forceRefresh);
      state = state.copyWith(categories: list, isLoading: false);
    } on Failure catch (f) {
      state = state.copyWith(isLoading: false, errorMessage: f.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void changeTab(String type) {
    if (state.selectedTab != type) {
      state = state.copyWith(selectedTab: type, clearError: true);
    }
  }

  Future<bool> createCategory({
    required String name,
    required String type,
    String? icon,
    String? color,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.createCategory(
        name: name,
        type: type,
        icon: icon,
        color: color,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } on Failure catch (f) {
      state = state.copyWith(isLoading: false, errorMessage: f.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.deleteCategory(id);
      state = state.copyWith(isLoading: false);
      return true;
    } on Failure catch (f) {
      state = state.copyWith(isLoading: false, errorMessage: f.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
