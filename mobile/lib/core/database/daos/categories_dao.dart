import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/local_categories.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [LocalCategories])
class CategoriesDao extends DatabaseAccessor<AppDatabase> with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  /// Watch all categories, optionally filtered by type ('income' or 'expense')
  /// System categories are listed first, then ordered alphabetically by name
  Stream<List<LocalCategory>> watchAllCategories({String? type}) {
    final query = select(localCategories);
    if (type != null) {
      query.where((tbl) => tbl.type.equals(type));
    }
    query.orderBy([
      (tbl) => OrderingTerm(expression: tbl.isSystem, mode: OrderingMode.desc),
      (tbl) => OrderingTerm(expression: tbl.name, mode: OrderingMode.asc),
    ]);
    return query.watch();
  }

  /// Get all categories snapshot
  Future<List<LocalCategory>> getAllCategories({String? type}) {
    final query = select(localCategories);
    if (type != null) {
      query.where((tbl) => tbl.type.equals(type));
    }
    query.orderBy([
      (tbl) => OrderingTerm(expression: tbl.isSystem, mode: OrderingMode.desc),
      (tbl) => OrderingTerm(expression: tbl.name, mode: OrderingMode.asc),
    ]);
    return query.get();
  }

  /// Get category by its local ID
  Future<LocalCategory?> getCategoryById(String id) {
    return (select(localCategories)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Get category by its remote server UUID
  Future<LocalCategory?> getCategoryByRemoteId(String remoteId) {
    return (select(localCategories)..where((tbl) => tbl.remoteId.equals(remoteId)))
        .getSingleOrNull();
  }

  /// Upsert a single category into local SQLite
  Future<int> upsertCategory(LocalCategoriesCompanion category) {
    return into(localCategories).insertOnConflictUpdate(category);
  }

  /// Batch upsert multiple categories (used during initial sync pull from FastAPI)
  Future<void> upsertCategories(List<LocalCategoriesCompanion> categories) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(localCategories, categories);
    });
  }

  /// Delete category by ID
  Future<int> deleteCategory(String id) {
    return (delete(localCategories)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Clear all cached categories (e.g. on full reset)
  Future<int> clearCategories() {
    return delete(localCategories).go();
  }
}
