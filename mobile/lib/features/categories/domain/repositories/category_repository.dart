import '../entities/category_entity.dart';

/// Contract definition for Category management operations
abstract class CategoryRepository {
  /// Fetches categories, optionally filtered by type ('income' or 'expense')
  /// If forceRefresh is true, fetches latest from remote server and updates local cache
  Future<List<CategoryEntity>> getCategories({
    String? type,
    bool forceRefresh = false,
  });

  /// Streams categories re-actively from local database
  Stream<List<CategoryEntity>> watchCategories({String? type});

  /// Creates a new custom category on remote server and saves to local cache
  Future<CategoryEntity> createCategory({
    required String name,
    required String type,
    String? icon,
    String? color,
  });

  /// Deletes a custom category (system categories cannot be deleted)
  Future<void> deleteCategory(String id);

  /// Synchronizes all categories from FastAPI backend to local SQLite cache
  Future<void> syncCategories();
}
