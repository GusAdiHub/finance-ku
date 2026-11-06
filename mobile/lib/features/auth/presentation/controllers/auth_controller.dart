import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
  error,
}

class AuthState {
  final AuthStatus status;
  final UserEntity? user;
  final String? errorMessage;
  final String? rememberedUsername;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.rememberedUsername,
  });

  const AuthState.initial()
      : status = AuthStatus.initial,
        user = null,
        errorMessage = null,
        rememberedUsername = null;

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    String? errorMessage,
    String? rememberedUsername,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      rememberedUsername: rememberedUsername ?? this.rememberedUsername,
    );
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  late final AuthRepository _authRepository;

  @override
  AuthState build() {
    _authRepository = ref.watch(authRepositoryProvider);
    _initializeAuth();
    return const AuthState.initial();
  }

  Future<void> _initializeAuth() async {
    final rememberedUsername = await _authRepository.getRememberedUsername();
    final hasToken = await _authRepository.checkAuthStatus();

    if (hasToken) {
      final user = await _authRepository.getCurrentUser();
      state = state.copyWith(
        status: user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
        user: user,
        rememberedUsername: rememberedUsername,
      );
    } else {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        rememberedUsername: rememberedUsername,
      );
    }
  }

  Future<bool> login({
    required String username,
    required String password,
    bool rememberUsername = false,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final user = await _authRepository.login(
        username: username,
        password: password,
        rememberUsername: rememberUsername,
      );

      final remembered = rememberUsername ? username : null;

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        rememberedUsername: remembered,
        clearError: true,
      );
      return true;
    } on Failure catch (f) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: f.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Gagal masuk akun: $e',
      );
      return false;
    }
  }

  Future<bool> register({
    required String name,
    String? email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final user = await _authRepository.register(
        name: name,
        email: email,
        password: password,
      );

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        clearError: true,
      );
      return true;
    } on Failure catch (f) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: f.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Gagal mendaftar akun: $e',
      );
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _authRepository.logout();
    } finally {
      final remembered = await _authRepository.getRememberedUsername();
      state = AuthState(
        status: AuthStatus.unauthenticated,
        user: null,
        rememberedUsername: remembered,
      );
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } on Failure catch (f) {
      state = state.copyWith(errorMessage: f.message);
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
