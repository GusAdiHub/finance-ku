import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/category_model.dart';

abstract class CategoryRemoteDataSource {
  Future<List<CategoryModel>> getCategories({String? type});

  Future<CategoryModel> createCategory({
    required String name,
    required String type,
    String? icon,
    String? color,
  });

  Future<void> deleteCategory(String id);
}

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final Dio _dio;

  CategoryRemoteDataSourceImpl(this._dio);

  @override
  Future<List<CategoryModel>> getCategories({String? type}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (type != null && type.isNotEmpty) {
        queryParams['type'] = type;
      }

      final response = await _dio.get(
        ApiEndpoints.categories,
        queryParameters: queryParams,
      );

      final data = response.data as List<dynamic>;
      return data
          .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.error is Exception) {
        throw e.error!;
      }
      throw ServerException(e.message ?? 'Gagal memuat kategori.');
    }
  }

  @override
  Future<CategoryModel> createCategory({
    required String name,
    required String type,
    String? icon,
    String? color,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.categories,
        data: {
          'name': name.trim(),
          'type': type,
          if (icon != null && icon.isNotEmpty) 'icon': icon,
          if (color != null && color.isNotEmpty) 'color': color,
        },
      );

      return CategoryModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is Exception) {
        throw e.error!;
      }
      throw ServerException(e.message ?? 'Gagal menambahkan kategori.');
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      await _dio.delete(ApiEndpoints.categoryById(id));
    } on DioException catch (e) {
      if (e.error is Exception) {
        throw e.error!;
      }
      throw ServerException(e.message ?? 'Gagal menghapus kategori.');
    }
  }
}
