import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

/// Provider for FlutterSecureStorage instance
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: true,
    ),
  );
});

/// Provider for SecureStorageService
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return SecureStorageService(storage);
});

/// High-level encrypted key-value storage service
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService(this._storage);

  // --- Auth Token Management ---
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: AppConstants.keyAccessToken, value: token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: AppConstants.keyAccessToken);
  }

  Future<void> deleteAccessToken() async {
    await _storage.delete(key: AppConstants.keyAccessToken);
  }

  Future<bool> hasAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // --- User Profile Metadata ---
  Future<void> saveUserData({
    required String id,
    required String name,
    required String email,
  }) async {
    await _storage.write(key: AppConstants.keyUserId, value: id);
    await _storage.write(key: AppConstants.keyUserName, value: name);
    await _storage.write(key: AppConstants.keyUserEmail, value: email);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: AppConstants.keyUserId);
  }

  Future<String?> getUserName() async {
    return await _storage.read(key: AppConstants.keyUserName);
  }

  Future<String?> getUserEmail() async {
    return await _storage.read(key: AppConstants.keyUserEmail);
  }

  // --- Username Persistence ("Ingat username di perangkat ini") ---
  Future<void> saveRememberedUsername(String username) async {
    await _storage.write(key: AppConstants.keyRememberedUsername, value: username);
  }

  Future<String?> getRememberedUsername() async {
    return await _storage.read(key: AppConstants.keyRememberedUsername);
  }

  Future<void> clearRememberedUsername() async {
    await _storage.delete(key: AppConstants.keyRememberedUsername);
  }

  // --- Session Expiry Tracking for Offline Resiliency ---
  Future<void> setSessionExpired(bool expired) async {
    await _storage.write(
      key: AppConstants.keySessionExpired,
      value: expired ? 'true' : 'false',
    );
  }

  Future<bool> isSessionExpired() async {
    final val = await _storage.read(key: AppConstants.keySessionExpired);
    return val == 'true';
  }

  // --- Last Synced Timestamp ---
  Future<void> saveLastSyncedAt(DateTime dateTime) async {
    await _storage.write(
      key: AppConstants.keyLastSyncedAt,
      value: dateTime.toUtc().toIso8601String(),
    );
  }

  Future<DateTime?> getLastSyncedAt() async {
    final val = await _storage.read(key: AppConstants.keyLastSyncedAt);
    if (val == null) return null;
    return DateTime.tryParse(val)?.toUtc();
  }

  /// Clears only authentication credentials.
  /// IMPORTANT: Never touches or wipes the local SQLite database.
  Future<void> clearAuthCredentials() async {
    await _storage.delete(key: AppConstants.keyAccessToken);
    await _storage.delete(key: AppConstants.keyUserId);
    await _storage.delete(key: AppConstants.keyUserName);
    await _storage.delete(key: AppConstants.keyUserEmail);
    await _storage.delete(key: AppConstants.keySessionExpired);
  }
}
