import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/models/user_model.dart';
import 'package:mobile/features/auth/domain/entities/user_entity.dart';

void main() {
  group('UserModel Tests', () {
    final now = DateTime.utc(2026, 11, 6, 12, 0, 0);

    test('fromJson parses JSON correctly', () {
      final json = {
        'id': 'user-123',
        'name': 'Budi Santoso',
        'email': 'budi@example.com',
        'is_active': true,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final model = UserModel.fromJson(json);

      expect(model.id, 'user-123');
      expect(model.name, 'Budi Santoso');
      expect(model.email, 'budi@example.com');
      expect(model.isActive, true);
    });

    test('toEntity converts to UserEntity correctly', () {
      final model = UserModel(
        id: 'user-123',
        name: 'Budi Santoso',
        email: 'budi@example.com',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final entity = model.toEntity();

      expect(entity, isA<UserEntity>());
      expect(entity.id, 'user-123');
      expect(entity.name, 'Budi Santoso');
    });

    test('fromEntity converts back to UserModel', () {
      final entity = UserEntity(
        id: 'user-456',
        name: 'Dewi Lestari',
        email: 'dewi@example.com',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final model = UserModel.fromEntity(entity);

      expect(model.id, 'user-456');
      expect(model.name, 'Dewi Lestari');
    });
  });
}
