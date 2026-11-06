import 'dart:async';
import '../models/category_model.dart';

abstract class CategoryLocalDataSource {
  Future<List<CategoryModel>> getCategories({String? type});

  Stream<List<CategoryModel>> watchCategories({String? type});

  Future<void> saveCategories(List<CategoryModel> categories);

  Future<void> saveCategory(CategoryModel category);

  Future<void> deleteCategory(String id);

  Future<void> clearCategories();
}

class CategoryLocalDataSourceImpl implements CategoryLocalDataSource {
  final List<CategoryModel> _cache = [];
  final _streamController = StreamController<List<CategoryModel>>.broadcast();

  CategoryLocalDataSourceImpl() {
    // Seed standard fallback categories if cache is initially empty
    if (_cache.isEmpty) {
      _cache.addAll(_defaultSystemCategories);
    }
  }

  @override
  Future<List<CategoryModel>> getCategories({String? type}) async {
    if (type == null) {
      return List.unmodifiable(_cache);
    }
    return _cache.where((c) => c.type == type).toList();
  }

  @override
  Stream<List<CategoryModel>> watchCategories({String? type}) async* {
    yield await getCategories(type: type);
    yield* _streamController.stream.map((list) {
      if (type == null) return list;
      return list.where((c) => c.type == type).toList();
    });
  }

  @override
  Future<void> saveCategories(List<CategoryModel> categories) async {
    for (final newCat in categories) {
      final index = _cache.indexWhere((c) => c.id == newCat.id);
      if (index >= 0) {
        _cache[index] = newCat;
      } else {
        _cache.add(newCat);
      }
    }
    _emitUpdate();
  }

  @override
  Future<void> saveCategory(CategoryModel category) async {
    final index = _cache.indexWhere((c) => c.id == category.id);
    if (index >= 0) {
      _cache[index] = category;
    } else {
      _cache.add(category);
    }
    _emitUpdate();
  }

  @override
  Future<void> deleteCategory(String id) async {
    _cache.removeWhere((c) => c.id == id && !c.isSystem);
    _emitUpdate();
  }

  @override
  Future<void> clearCategories() async {
    _cache.clear();
    _cache.addAll(_defaultSystemCategories);
    _emitUpdate();
  }

  void _emitUpdate() {
    // Sort: system categories first, then alphabetical by name
    _cache.sort((a, b) {
      if (a.isSystem != b.isSystem) {
        return a.isSystem ? -1 : 1;
      }
      return a.name.compareTo(b.name);
    });
    _streamController.add(List.unmodifiable(_cache));
  }

  // Built-in standard fallback system categories matching backend seed
  static final List<CategoryModel> _defaultSystemCategories = [
    // Expense
    const CategoryModel(
      id: 'sys-exp-1',
      name: 'Makanan & Minuman',
      type: 'expense',
      icon: 'utensils',
      color: '#EF4444',
      isSystem: true,
    ),
    const CategoryModel(
      id: 'sys-exp-2',
      name: 'Transportasi',
      type: 'expense',
      icon: 'car',
      color: '#F59E0B',
      isSystem: true,
    ),
    const CategoryModel(
      id: 'sys-exp-3',
      name: 'Belanja Harian',
      type: 'expense',
      icon: 'shopping-cart',
      color: '#8B5CF6',
      isSystem: true,
    ),
    const CategoryModel(
      id: 'sys-exp-4',
      name: 'Tagihan & Utilitas',
      type: 'expense',
      icon: 'receipt',
      color: '#3B82F6',
      isSystem: true,
    ),
    const CategoryModel(
      id: 'sys-exp-5',
      name: 'Hiburan',
      type: 'expense',
      icon: 'film',
      color: '#EC4899',
      isSystem: true,
    ),
    const CategoryModel(
      id: 'sys-exp-6',
      name: 'Kesehatan',
      type: 'expense',
      icon: 'heart-pulse',
      color: '#14B8A6',
      isSystem: true,
    ),
    // Income
    const CategoryModel(
      id: 'sys-inc-1',
      name: 'Gaji Pokok',
      type: 'income',
      icon: 'briefcase',
      color: '#10B981',
      isSystem: true,
    ),
    const CategoryModel(
      id: 'sys-inc-2',
      name: 'Bonus & THR',
      type: 'income',
      icon: 'gift',
      color: '#059669',
      isSystem: true,
    ),
    const CategoryModel(
      id: 'sys-inc-3',
      name: 'Investasi',
      type: 'income',
      icon: 'trending-up',
      color: '#0D9488',
      isSystem: true,
    ),
    const CategoryModel(
      id: 'sys-inc-4',
      name: 'Lain-lain',
      type: 'income',
      icon: 'plus-circle',
      color: '#6366F1',
      isSystem: true,
    ),
  ];
}
