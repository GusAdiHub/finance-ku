import '../entities/user_entity.dart';

/// Contract definition for Authentication operations
abstract class AuthRepository {
  /// Authenticates user with username or email and password
  Future<UserEntity> login({
    required String username,
    required String password,
    bool rememberUsername = false,
  });

  /// Registers a new user account with name and password (email optional)
  Future<UserEntity> register({
    required String name,
    String? email,
    required String password,
  });

  /// Logs out the user, invalidates token, and clears credentials
  Future<void> logout();

  /// Gets current user profile from local cache or remote server
  Future<UserEntity?> getCurrentUser();

  /// Checks if valid access token exists locally
  Future<bool> checkAuthStatus();

  /// Retrieves remembered username for the login screen input
  Future<String?> getRememberedUsername();

  /// Changes the user's password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
