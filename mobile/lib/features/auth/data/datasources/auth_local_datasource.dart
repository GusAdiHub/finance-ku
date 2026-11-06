import '../../../../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveAuthData({
    required String token,
    required UserModel user,
  });

  Future<String?> getAccessToken();

  Future<UserModel?> getCachedUser();

  Future<void> clearAuthData();

  Future<void> saveRememberedUsername(String username);

  Future<String?> getRememberedUsername();

  Future<void> clearRememberedUsername();

  Future<bool> hasToken();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SecureStorageService _storageService;

  AuthLocalDataSourceImpl(this._storageService);

  @override
  Future<void> saveAuthData({
    required String token,
    required UserModel user,
  }) async {
    await _storageService.saveAccessToken(token);
    await _storageService.saveUserData(
      id: user.id,
      name: user.name,
      email: user.email,
    );
    await _storageService.setSessionExpired(false);
  }

  @override
  Future<String?> getAccessToken() async {
    return await _storageService.getAccessToken();
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final id = await _storageService.getUserId();
    final name = await _storageService.getUserName();
    final email = await _storageService.getUserEmail();

    if (id == null || name == null) {
      return null;
    }

    return UserModel(
      id: id,
      name: name,
      email: email ?? '',
      isActive: true,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<void> clearAuthData() async {
    await _storageService.clearAuthCredentials();
  }

  @override
  Future<void> saveRememberedUsername(String username) async {
    await _storageService.saveRememberedUsername(username);
  }

  @override
  Future<String?> getRememberedUsername() async {
    return await _storageService.getRememberedUsername();
  }

  @override
  Future<void> clearRememberedUsername() async {
    await _storageService.clearRememberedUsername();
  }

  @override
  Future<bool> hasToken() async {
    return await _storageService.hasAccessToken();
  }
}
