import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/categories/data/datasources/category_local_datasource.dart';
import 'package:mobile/features/categories/data/models/category_model.dart';

void main() {
  group('CategoryLocalDataSource Tests', () {
    late CategoryLocalDataSource dataSource;

    setUp(() {
      dataSource = CategoryLocalDataSourceImpl();
    });

    test('Initial cache contains default system categories', () async {
      final allCategories = await dataSource.getCategories();
      expect(allCategories.isNotEmpty, isTrue);

      final systemExpense = allCategories.where((c) => c.isSystem && c.type == 'expense');
      final systemIncome = allCategories.where((c) => c.isSystem && c.type == 'income');

      expect(systemExpense.isNotEmpty, isTrue);
      expect(systemIncome.isNotEmpty, isTrue);
    });

    test('getCategories filters by type properly', () async {
      final expenseList = await dataSource.getCategories(type: 'expense');
      final incomeList = await dataSource.getCategories(type: 'income');

      expect(expenseList.every((c) => c.type == 'expense'), isTrue);
      expect(incomeList.every((c) => c.type == 'income'), isTrue);
    });

    test('saveCategory adds custom category to cache and stream', () async {
      const customCat = CategoryModel(
        id: 'cust-1',
        name: 'Hobi & Mainan',
        type: 'expense',
        icon: 'gift',
        color: '#EC4899',
        isSystem: false,
      );

      await dataSource.saveCategory(customCat);

      final categories = await dataSource.getCategories(type: 'expense');
      expect(categories.any((c) => c.id == 'cust-1' && c.name == 'Hobi & Mainan'), isTrue);
    });

    test('deleteCategory deletes custom category but protects system categories', () async {
      const customCat = CategoryModel(
        id: 'cust-2',
        name: 'Langganan Streaming',
        type: 'expense',
        isSystem: false,
      );

      await dataSource.saveCategory(customCat);
      expect((await dataSource.getCategories()).any((c) => c.id == 'cust-2'), isTrue);

      // Deleting custom category succeeds
      await dataSource.deleteCategory('cust-2');
      expect((await dataSource.getCategories()).any((c) => c.id == 'cust-2'), isFalse);

      // Deleting system category is ignored/protected
      await dataSource.deleteCategory('sys-exp-1');
      expect((await dataSource.getCategories()).any((c) => c.id == 'sys-exp-1'), isTrue);
    });
  });
}
