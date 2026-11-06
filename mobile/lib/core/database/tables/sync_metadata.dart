import 'package:drift/drift.dart';

/// Table storing sync metadata and timestamps in SQLite
class SyncMetadata extends Table {
  /// Unique metadata key (e.g. 'last_synced_transactions', 'last_synced_categories')
  TextColumn get key => text()();

  /// Metadata string value
  TextColumn get value => text()();

  /// Timestamp when the metadata record was updated
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}
