import '../../../categories/data/models/category_model.dart';
import '../../domain/entities/transaction_entity.dart';

/// Data Transfer Object for Transaction API requests and responses
class TransactionModel {
  final String id;
  final String type;
  final String amount; // Exact string representation from backend Numeric(15,2)
  final String categoryId;
  final DateTime transactionDate;
  final String? description;
  final String? notes;
  final String? ownerUserId;
  final String? inputMethod;
  final String? receiptId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final CategoryModel? category;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.transactionDate,
    this.description,
    this.notes,
    this.ownerUserId,
    this.inputMethod = 'manual',
    this.receiptId,
    this.createdAt,
    this.updatedAt,
    this.category,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      type: json['type'] as String,
      amount: json['amount'].toString(),
      categoryId: json['category_id'] as String,
      transactionDate: DateTime.parse(json['transaction_date'] as String).toUtc(),
      description: json['description'] as String?,
      notes: json['notes'] as String?,
      ownerUserId: json['owner_user_id'] as String?,
      inputMethod: json['input_method'] as String? ?? 'manual',
      receiptId: json['receipt_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)?.toUtc()
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)?.toUtc()
          : null,
      category: json['category'] != null
          ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'amount': amount,
      'category_id': categoryId,
      'transaction_date': transactionDate.toUtc().toIso8601String(),
      if (description != null) 'description': description,
      if (notes != null) 'notes': notes,
      'input_method': inputMethod,
    };
  }

  TransactionEntity toEntity({String? localId, String? syncStatus}) {
    final parsedAmount = double.tryParse(amount) ?? 0.0;
    return TransactionEntity(
      id: localId ?? id,
      remoteId: id,
      type: type,
      amount: parsedAmount,
      amountString: amount,
      categoryId: categoryId,
      categoryName: category?.name,
      categoryIcon: category?.icon,
      categoryColor: category?.color,
      transactionDate: transactionDate,
      description: description,
      notes: notes,
      inputMethod: inputMethod ?? 'manual',
      userId: ownerUserId ?? '',
      syncStatus: syncStatus ?? 'synced',
      createdAt: createdAt ?? DateTime.now().toUtc(),
      updatedAt: updatedAt ?? DateTime.now().toUtc(),
      clientUpdatedAt: updatedAt ?? DateTime.now().toUtc(),
      lastSyncedAt: DateTime.now().toUtc(),
    );
  }

  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.remoteId ?? entity.id,
      type: entity.type,
      amount: entity.amountString,
      categoryId: entity.categoryId,
      transactionDate: entity.transactionDate,
      description: entity.description,
      notes: entity.notes,
      ownerUserId: entity.userId,
      inputMethod: entity.inputMethod,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
