/// Pure Domain Entity representing a Financial Transaction in SakuKu
class TransactionEntity {
  final String id; // Local UUID v4
  final String? remoteId; // PostgreSQL backend server UUID (null if un-synced)
  final String type; // 'income' or 'expense'
  final double amount; // Parsed numeric amount
  final String amountString; // Exact decimal string for database precision
  final String categoryId;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final DateTime transactionDate;
  final String? description;
  final String? notes;
  final String inputMethod; // 'manual', 'ocr', 'voice'
  final String userId;

  // --- Synchronization Metadata ---
  final String syncStatus; // 'pending_create' | 'pending_update' | 'pending_delete' | 'synced' | 'failed'
  final String? syncError;
  final int retryCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime clientUpdatedAt;
  final DateTime? lastSyncedAt;

  const TransactionEntity({
    required this.id,
    this.remoteId,
    required this.type,
    required this.amount,
    required this.amountString,
    required this.categoryId,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    required this.transactionDate,
    this.description,
    this.notes,
    this.inputMethod = 'manual',
    required this.userId,
    this.syncStatus = 'pending_create',
    this.syncError,
    this.retryCount = 0,
    required this.createdAt,
    required this.updatedAt,
    required this.clientUpdatedAt,
    this.lastSyncedAt,
  });

  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';
  bool get isSynced => syncStatus == 'synced';
  bool get isPending =>
      syncStatus == 'pending_create' ||
      syncStatus == 'pending_update' ||
      syncStatus == 'pending_delete';
  bool get isFailed => syncStatus == 'failed';

  TransactionEntity copyWith({
    String? id,
    String? remoteId,
    String? type,
    double? amount,
    String? amountString,
    String? categoryId,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
    DateTime? transactionDate,
    String? description,
    String? notes,
    String? inputMethod,
    String? userId,
    String? syncStatus,
    String? syncError,
    int? retryCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? clientUpdatedAt,
    DateTime? lastSyncedAt,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      amountString: amountString ?? this.amountString,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
      transactionDate: transactionDate ?? this.transactionDate,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      inputMethod: inputMethod ?? this.inputMethod,
      userId: userId ?? this.userId,
      syncStatus: syncStatus ?? this.syncStatus,
      syncError: syncError ?? this.syncError,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          syncStatus == other.syncStatus &&
          clientUpdatedAt == other.clientUpdatedAt;

  @override
  int get hashCode => id.hashCode ^ syncStatus.hashCode ^ clientUpdatedAt.hashCode;

  @override
  String toString() =>
      'TransactionEntity(id: $id, type: $type, amount: $amount, syncStatus: $syncStatus)';
}
