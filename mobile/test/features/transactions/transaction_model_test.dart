import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/transactions/data/models/transaction_model.dart';
import 'package:mobile/features/transactions/domain/entities/transaction_entity.dart';

void main() {
  group('TransactionModel Tests', () {
    final now = DateTime.utc(2026, 11, 6, 12, 30, 0);

    test('fromJson parses FastAPI transaction response correctly', () {
      final json = {
        'id': 'srv-tx-123',
        'type': 'expense',
        'amount': '45000.00',
        'category_id': 'cat-123',
        'transaction_date': now.toIso8601String(),
        'description': 'Makan Siang Nasi Padang',
        'notes': 'Bersama rekan kerja',
        'owner_user_id': 'user-123',
        'input_method': 'manual',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'category': {
          'id': 'cat-123',
          'name': 'Makanan & Minuman',
          'type': 'expense',
          'icon': 'utensils',
          'color': '#EF4444',
          'is_system': true,
        },
      };

      final model = TransactionModel.fromJson(json);

      expect(model.id, 'srv-tx-123');
      expect(model.type, 'expense');
      expect(model.amount, '45000.00');
      expect(model.categoryId, 'cat-123');
      expect(model.description, 'Makan Siang Nasi Padang');
      expect(model.category?.name, 'Makanan & Minuman');
    });

    test('toEntity converts model to domain entity with category metadata', () {
      final model = TransactionModel(
        id: 'srv-tx-123',
        type: 'expense',
        amount: '45000.00',
        categoryId: 'cat-123',
        transactionDate: now,
        description: 'Makan Siang',
      );

      final entity = model.toEntity(localId: 'local-uuid-1', syncStatus: 'synced');

      expect(entity, isA<TransactionEntity>());
      expect(entity.id, 'local-uuid-1');
      expect(entity.remoteId, 'srv-tx-123');
      expect(entity.amount, 45000.0);
      expect(entity.amountString, '45000.00');
      expect(entity.isSynced, isTrue);
      expect(entity.isPending, isFalse);
    });

    test('fromEntity converts TransactionEntity back to TransactionModel', () {
      final entity = TransactionEntity(
        id: 'local-uuid-2',
        remoteId: 'srv-tx-456',
        type: 'income',
        amount: 5000000.0,
        amountString: '5000000.00',
        categoryId: 'cat-inc-1',
        transactionDate: now,
        userId: 'user-123',
        createdAt: now,
        updatedAt: now,
        clientUpdatedAt: now,
      );

      final model = TransactionModel.fromEntity(entity);

      expect(model.id, 'srv-tx-456');
      expect(model.type, 'income');
      expect(model.amount, '5000000.00');
    });
  });
}
