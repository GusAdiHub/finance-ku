import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/categories/data/models/category_model.dart';
import 'package:mobile/features/categories/domain/entities/category_entity.dart';

void main() {
  group('CategoryModel Tests', () {
    test('fromJson parses JSON correctly from FastAPI response', () {
      final json = {
        'id': 'cat-123',
        'name': 'Makanan & Minuman',
        'type': 'expense',
        'icon': 'utensils',
        'color': '#EF4444',
        'is_system': true,
        'user_id': null,
        'group_id': null,
        'created_at': '2026-11-06T10:00:00Z',
        'updated_at': '2026-11-06T10:00:00Z',
      };

      final model = CategoryModel.fromJson(json);

      expect(model.id, 'cat-123');
      expect(model.name, 'Makanan & Minuman');
      expect(model.type, 'expense');
      expect(model.icon, 'utensils');
      expect(model.color, '#EF4444');
      expect(model.isSystem, true);
    });

    test('toEntity converts CategoryModel to CategoryEntity correctly', () {
      const model = CategoryModel(
        id: 'cat-456',
        name: 'Gaji Bulanan',
        type: 'income',
        icon: 'briefcase',
        color: '#10B981',
        isSystem: true,
      );

      final entity = model.toEntity();

      expect(entity, isA<CategoryEntity>());
      expect(entity.id, 'cat-456');
      expect(entity.name, 'Gaji Bulanan');
      expect(entity.type, 'income');
      expect(entity.isIncome, true);
      expect(entity.isExpense, false);
      expect(entity.isSystem, true);
    });

    test('fromEntity converts CategoryEntity back to CategoryModel', () {
      const entity = CategoryEntity(
        id: 'cat-789',
        name: 'Kopi & Camilan',
        type: 'expense',
        icon: 'coffee',
        color: '#F59E0B',
        isSystem: false,
        userId: 'user-001',
      );

      final model = CategoryModel.fromEntity(entity);

      expect(model.id, 'cat-789');
      expect(model.name, 'Kopi & Camilan');
      expect(model.isSystem, false);
      expect(model.userId, 'user-001');
    });

    test('toJson serializes CategoryModel properly', () {
      const model = CategoryModel(
        id: 'cat-789',
        name: 'Kopi & Camilan',
        type: 'expense',
        icon: 'coffee',
        color: '#F59E0B',
        isSystem: false,
      );

      final json = model.toJson();

      expect(json['id'], 'cat-789');
      expect(json['name'], 'Kopi & Camilan');
      expect(json['type'], 'expense');
      expect(json['icon'], 'coffee');
      expect(json['color'], '#F59E0B');
      expect(json['is_system'], false);
    });
  });
}
