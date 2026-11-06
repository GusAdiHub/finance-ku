import 'package:drift/drift.dart';

/// Table representing transactions stored locally in SQLite via Drift
class LocalTransactions extends Table {
  /// Local client primary key (UUID v4 generated on mobile device upon creation)
  TextColumn get id => text()();

  /// PostgreSQL backend server primary key (NULL if transaction created offline and not yet pushed)
  TextColumn get remoteId => text().nullable()();

  /// Transaction type: 'income' or 'expense'
  TextColumn get type => text()();

  /// Transaction amount stored as exact Decimal string (e.g. "50000.00") to avoid floating-point loss
  TextColumn get amount => text()();

  /// Relational Category ID (points to LocalCategories.id or remote category UUID)
  TextColumn get categoryId => text()();

  /// Actual transaction timestamp (UTC)
  DateTimeColumn get transactionDate => dateTime()();

  /// Optional description and notes
  TextColumn get description => text().nullable()();
  TextColumn get notes => text().nullable()();

  /// Input method: 'manual', 'ocr', 'voice'
  TextColumn get inputMethod => text().withDefault(const Constant('manual'))();

  /// Owning user ID
  TextColumn get userId => text()();

  // --- Synchronization Metadata ---

  /// Lifecycle sync status: 'pending_create' | 'pending_update' | 'pending_delete' | 'synced' | 'failed'
  TextColumn get syncStatus => text().withDefault(const Constant('pending_create'))();

  /// Last error message if synchronization attempt failed
  TextColumn get syncError => text().nullable()();

  /// Count of retry attempts for exponential backoff
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  /// Timestamp audit tracking
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get clientUpdatedAt => dateTime()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
