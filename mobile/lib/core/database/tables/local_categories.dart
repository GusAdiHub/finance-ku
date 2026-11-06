import 'package:drift/drift.dart';

/// Table representing financial categories cached locally in SQLite via Drift
class LocalCategories extends Table {
  /// Local client category UUID
  TextColumn get id => text()();

  /// PostgreSQL backend server category UUID
  TextColumn get remoteId => text().nullable()();

  /// Category name (e.g. 'Makanan & Minuman', 'Gaji')
  TextColumn get name => text()();

  /// Category type: 'income' or 'expense'
  TextColumn get type => text()();

  /// Icon identifier (e.g. 'utensils', 'briefcase', 'shopping-cart')
  TextColumn get icon => text().nullable()();

  /// Hex color code (e.g. '#EF4444', '#10B981')
  TextColumn get color => text().nullable()();

  /// Flag indicating whether category is a system default
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();

  /// Owning user ID (NULL for system categories)
  TextColumn get userId => text().nullable()();

  /// Synchronization status: 'synced' | 'pending_create' | 'pending_delete'
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();

  /// Timestamp when the category was last modified
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
