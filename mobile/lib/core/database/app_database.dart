import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import 'connection/connection.dart';
import 'daos/categories_dao.dart';
import 'daos/transactions_dao.dart';
import 'tables/local_categories.dart';
import 'tables/local_transactions.dart';
import 'tables/sync_metadata.dart';

part 'app_database.g.dart';

/// Central Drift SQLite Database for SakuKu Mobile (Offline-First)
@DriftDatabase(
  tables: [LocalTransactions, LocalCategories, SyncMetadata],
  daos: [TransactionsDao, CategoriesDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  AppDatabase.forTesting(DatabaseConnection super.connection);

  @override
  int get schemaVersion => AppConstants.databaseSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Future database migrations will be handled here incrementally
        },
      );
}

/// Riverpod Provider for the AppDatabase singleton instance
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Riverpod Provider for TransactionsDao
final transactionsDaoProvider = Provider<TransactionsDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.transactionsDao;
});

/// Riverpod Provider for CategoriesDao
final categoriesDaoProvider = Provider<CategoriesDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.categoriesDao;
});
