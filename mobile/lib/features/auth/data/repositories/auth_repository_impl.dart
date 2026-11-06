import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRemoteDataSourceImpl(dio);
});

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  final storageService = ref.watch(secureStorageServiceProvider);
  return AuthLocalDataSourceImpl(storageService);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final localDataSource = ref.watch(authLocalDataSourceProvider);
  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
  );
});

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<UserEntity> login({
    required String username,
    required String password,
    bool rememberUsername = false,
  }) async {
    try {
      final tokenModel = await _remoteDataSource.login(
        username: username,
        password: password,
      );

      // Save token and user data locally in encrypted storage
      await _localDataSource.saveAuthData(
        token: tokenModel.accessToken,
        user: tokenModel.user,
      );

      // Handle "Ingat username di perangkat ini"
      if (rememberUsername) {
        await _localDataSource.saveRememberedUsername(username);
      } else {
        await _localDataSource.clearRememberedUsername();
      }

      return tokenModel.user.toEntity();
    } on UnauthorizedException catch (e) {
      throw UnauthorizedFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } catch (e) {
      throw ServerFailure('Terjadi kesalahan saat masuk: $e');
    }
  }

  @override
  Future<UserEntity> register({
    required String name,
    String? email,
    required String password,
  }) async {
    try {
      final tokenModel = await _remoteDataSource.register(
        name: name,
        email: email,
        password: password,
      );

      await _localDataSource.saveAuthData(
        token: tokenModel.accessToken,
        user: tokenModel.user,
      );

      return tokenModel.user.toEntity();
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } catch (e) {
      throw ServerFailure('Terjadi kesalahan saat mendaftar: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
    } finally {
      // Clear token and user credentials locally.
      // Database SQLite remains intact for offline safety.
      await _localDataSource.clearAuthData();
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    // 1. Try fetching from remote to ensure latest profile
    try {
      final remoteUser = await _remoteDataSource.getCurrentUser();
      await _localDataSource.saveAuthData(
        token: (await _localDataSource.getAccessToken()) ?? '',
        user: remoteUser,
      );
      return remoteUser.toEntity();
    } catch (_) {
      // 2. Fallback to cached profile if offline
      final cachedUser = await _localDataSource.getCachedUser();
      return cachedUser?.toEntity();
    }
  }

  @override
  Future<bool> checkAuthStatus() async {
    return await _localDataSource.hasToken();
  }

  @override
  Future<String?> getRememberedUsername() async {
    return await _localDataSource.getRememberedUsername();
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _remoteDataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    } catch (e) {
      throw ServerFailure('Terjadi kesalahan saat mengubah kata sandi: $e');
    }
  }
}
