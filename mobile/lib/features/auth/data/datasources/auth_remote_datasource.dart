import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/auth_token_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthTokenModel> login({
    required String username,
    required String password,
  });

  Future<AuthTokenModel> register({
    required String name,
    String? email,
    required String password,
  });

  Future<void> logout();

  Future<UserModel> getCurrentUser();

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSourceImpl(this._dio);

  @override
  Future<AuthTokenModel> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {
          'username': username,
          'password': password,
        },
      );
      return AuthTokenModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is Exception) {
        throw e.error!;
      }
      throw ServerException(e.message ?? 'Gagal masuk akun.');
    }
  }

  @override
  Future<AuthTokenModel> register({
    required String name,
    String? email,
    required String password,
  }) async {
    try {
      final payload = <String, dynamic>{
        'name': name,
        'password': password,
      };
      if (email != null && email.trim().isNotEmpty) {
        payload['email'] = email.trim();
      }

      final response = await _dio.post(
        ApiEndpoints.register,
        data: payload,
      );
      return AuthTokenModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is Exception) {
        throw e.error!;
      }
      throw ServerException(e.message ?? 'Gagal mendaftar akun.');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } on DioException {
      // Even if network fails during logout, local credentials will still be cleared
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _dio.get(ApiEndpoints.me);
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is Exception) {
        throw e.error!;
      }
      throw ServerException(e.message ?? 'Gagal mengambil data profil.');
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        ApiEndpoints.changePassword,
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      if (e.error is Exception) {
        throw e.error!;
      }
      throw ServerException(e.message ?? 'Gagal mengganti kata sandi.');
    }
  }
}
