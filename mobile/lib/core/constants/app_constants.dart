/// Application-wide Constants for SakuKu Mobile
class AppConstants {
  AppConstants._();

  // --- Network Timeouts ---
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 10);

  // --- Pagination ---
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // --- Offline Sync Engine ---
  static const int maxSyncRetries = 5;
  static const Duration syncDebounceDelay = Duration(milliseconds: 1500);

  // --- Secure Storage Keys ---
  static const String keyAccessToken = 'sakuku_access_token';
  static const String keyUserId = 'sakuku_user_id';
  static const String keyUserName = 'sakuku_user_name';
  static const String keyUserEmail = 'sakuku_user_email';
  static const String keyRememberedUsername = 'sakuku_remembered_username';
  static const String keySessionExpired = 'sakuku_session_expired';
  static const String keyLastSyncedAt = 'sakuku_last_synced_at';

  // --- Database ---
  static const String databaseName = 'sakuku_local.sqlite';
  static const int databaseSchemaVersion = 1;
}
