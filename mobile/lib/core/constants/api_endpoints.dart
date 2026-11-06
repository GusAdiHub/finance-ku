/// API Endpoints for SakuKu Backend (FastAPI)
class ApiEndpoints {
  ApiEndpoints._();

  /// Default Base URL for SakuKu Backend API.
  /// Overridable with --dart-define=BASE_URL=http://...
  /// When testing on real Android device over USB, run:
  /// `adb reverse tcp:8000 tcp:8000` so localhost:8000 maps to your Mac!
  static const String defaultBaseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  // --- Authentication ---
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String changePassword = '/auth/change-password';

  // --- Categories ---
  static const String categories = '/categories';
  static String categoryById(String id) => '/categories/$id';

  // --- Transactions ---
  static const String transactions = '/transactions';
  static String transactionById(String id) => '/transactions/$id';

  // --- Dashboard & Reports ---
  static const String dashboardPersonal = '/dashboard/personal';
  static const String reportsPersonal = '/reports/personal';

  // --- Receipts & OCR ---
  static const String receipts = '/receipts';
  static String receiptById(String id) => '/receipts/$id';
  static String receiptConfirm(String id) => '/receipts/$id/confirm';
  static String receiptFile(String id) => '/receipts/$id/file';

  // --- Voice Input ---
  static const String voiceParse = '/voice/parse';

  // --- Groups / Kas Tim ---
  static const String groups = '/groups';
  static String groupById(String id) => '/groups/$id';
  static const String joinGroup = '/groups/join';
  static String groupLeave(String id) => '/groups/$id/leave';
  static String groupMembers(String id) => '/groups/$id/members';
  static String groupInvitations(String id) => '/groups/$id/invitations';
  static String groupTransactions(String id) => '/groups/$id/transactions';
  static String groupTransactionById(String groupId, String txId) =>
      '/groups/$groupId/transactions/$txId';
  static String groupDashboard(String id) => '/groups/$id/dashboard';
  static String groupReports(String id) => '/groups/$id/reports';
}
