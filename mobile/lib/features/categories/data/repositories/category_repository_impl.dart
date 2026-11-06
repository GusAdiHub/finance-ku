import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_local_datasource.dart';
import '../datasources/category_remote_datasource.dart';
import '../models/category_model.dart';

final categoryRemoteDataSourceProvider = Provider<CategoryRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return CategoryRemoteDataSourceImpl(dio);
});

final categoryLocalDataSourceProvider = Provider<CategoryLocalDataSource>((ref) {
  return CategoryLocalDataSourceImpl();
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final remoteDataSource = ref.watch(categoryRemoteDataSourceProvider);
  final localDataSource = ref.watch(categoryLocalDataSourceProvider);
  return CategoryRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
  );
});

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource _remoteDataSource;
  final CategoryLocalDataSource _localDataSource;

  CategoryRepositoryImpl({
    required CategoryRemoteDataSource remoteDataSource,
    required CategoryLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<List<CategoryEntity>> getCategories({
    String? type,
    bool forceRefresh = false,
  }) async {
    // 1. If forceRefresh is requested, fetch from remote and cache
    if (forceRefresh) {
      try {
        final remoteCategories = await _remoteDataSource.getCategories(type: type);
        await _localDataSource.saveCategories(remoteCategories);
      } catch (_) {
        // If remote fails, fallback to local cache
      }
    }

    // 2. Return from local cache
    final localCategories = await _localDataSource.getCategories(type: type);
    if (localCategories.isNotEmpty) {
      return localCategories.map((c) => c.toEntity()).toList();
    }

    // 3. If local cache was empty, try fetching from remote
    try {
      final remoteCategories = await _remoteDataSource.getCategories(type: type);
      await _localDataSource.saveCategories(remoteCategories);
      return remoteCategories.map((c) => c.toEntity()).toList();
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Gagal memuat kategori: $e');
    }
  }

  @override
  Stream<List<CategoryEntity>> watchCategories({String? type}) {
    return _localDataSource
        .watchCategories(type: type)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Future<CategoryEntity> createCategory({
    required String name,
    required String type,
    String? icon,
    String? color,
  }) async {
    try {
      final createdModel = await _remoteDataSource.createCategory(
        name: name,
        type: type,
        icon: icon,
        color: color,
      );

      // Save to local cache immediately
      await _localDataSource.saveCategory(createdModel);

      return createdModel.toEntity();
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } catch (e) {
      throw ServerFailure('Gagal membuat kategori: $e');
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      await _remoteDataSource.deleteCategory(id);
      await _localDataSource.deleteCategory(id);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } catch (e) {
      throw ServerFailure('Gagal menghapus kategori: $e');
    }
  }

  @override
  Future<void> syncCategories() async {
    try {
      final remoteCategories = await _remoteDataSource.getCategories();
      await _localDataSource.saveCategories(remoteCategories);
    } catch (e) {
      // Sync failure is non-blocking for UI
    }
  }
}
