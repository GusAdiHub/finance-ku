import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/categories/presentation/screens/categories_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/groups/domain/entities/group_entity.dart';
import '../../features/groups/presentation/screens/group_detail_screen.dart';
import '../../features/groups/presentation/screens/groups_screen.dart';
import '../../features/receipts/presentation/screens/scan_receipt_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/transactions/domain/entities/transaction_entity.dart';
import '../../features/transactions/presentation/screens/transaction_detail_screen.dart';
import '../../features/transactions/presentation/screens/transactions_screen.dart';
import 'main_scaffold.dart';

/// Notifier bridging Riverpod AuthState changes to GoRouter refresh
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authControllerProvider,
      (_, __) => notifyListeners(),
    );
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authControllerProvider);
    final location = state.matchedLocation;
    final isAuthRoute = location == '/login' || location == '/register';

    // Wait until initial auth check completes
    if (authState.status == AuthStatus.initial) {
      return null;
    }

    final isAuthenticated = authState.status == AuthStatus.authenticated;

    // Unauthenticated users attempting to access protected routes are redirected to login
    if (!isAuthenticated) {
      return isAuthRoute ? null : '/login';
    }

    // Authenticated users on login/register/root are redirected to dashboard
    if (isAuthRoute || location == '/') {
      return '/app/dashboard';
    }

    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

/// Global navigator key
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Provider for GoRouter navigation instance
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/app/dashboard',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Main Navigation Shell containing persistent Bottom Navigation Bar
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/app/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/app/transactions',
            name: 'transactions',
            builder: (context, state) => const TransactionsScreen(),
          ),
          GoRoute(
            path: '/app/groups',
            name: 'groups',
            builder: (context, state) => const GroupsScreen(),
          ),
          GoRoute(
            path: '/app/reports',
            name: 'reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/app/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Full-screen overlay routes (pushed on top of the shell)
      GoRoute(
        path: '/app/transactions/detail',
        name: 'transaction_detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final tx = state.extra as TransactionEntity;
          return TransactionDetailScreen(transaction: tx);
        },
      ),
      GoRoute(
        path: '/app/groups/:id',
        name: 'group_detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final group = state.extra as GroupEntity;
          return GroupDetailScreen(group: group);
        },
      ),
      GoRoute(
        path: '/app/categories',
        name: 'categories',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        path: '/app/scan-receipt',
        name: 'scan_receipt',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ScanReceiptScreen(),
      ),
    ],
  );
});
