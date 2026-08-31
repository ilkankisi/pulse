import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_api.dart';
import '../domain/auth_models.dart';

enum AuthStatus { checking, unauthenticated, authenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.prefilledEmail = '',
    this.isSubmitting = false,
    this.errorMessage,
  });

  const AuthState.checking()
    : status = AuthStatus.checking,
      user = null,
      prefilledEmail = '',
      isSubmitting = false,
      errorMessage = null;

  final AuthStatus status;
  final AuthUser? user;
  final String prefilledEmail;
  final bool isSubmitting;
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? prefilledEmail,
    bool? isSubmitting,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      prefilledEmail: prefilledEmail ?? this.prefilledEmail,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(ref.watch(authApiProvider));
  },
);

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._authApi) : super(const AuthState.checking());

  final AuthApi _authApi;

  Future<void> checkSession() async {
    state = const AuthState.checking();

    try {
      final token = await _authApi.readToken();
      if (token == null || token.isEmpty) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }

      final user = await _authApi.getCurrentUser();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await _authApi.logout();
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }

      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: _errorMessage(error, 'Oturum doğrulanamadı.'),
      );
    } on FormatException {
      await _authApi.logout();
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Oturum bilgileri okunamadı.',
      );
    }
  }

  Future<bool> login(LoginRequest request) async {
    state = AuthState(
      status: AuthStatus.unauthenticated,
      prefilledEmail: request.email.trim(),
      isSubmitting: true,
    );

    try {
      final session = await _authApi.login(request);
      final user = session.user ?? await _authApi.getCurrentUser();

      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } on DioException catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        prefilledEmail: request.email.trim(),
        errorMessage: _errorMessage(
          error,
          'Oturum açılamadı. Bilgilerinizi kontrol edin.',
        ),
      );
      return false;
    } on FormatException {
      await _authApi.logout();
      state = AuthState(
        status: AuthStatus.unauthenticated,
        prefilledEmail: request.email.trim(),
        errorMessage: 'Sunucu yanıtı okunamadı.',
      );
      return false;
    }
  }

  Future<RegisterResult?> register(RegisterRequest request) async {
    state = AuthState(
      status: AuthStatus.unauthenticated,
      prefilledEmail: request.email.trim(),
      isSubmitting: true,
    );

    try {
      final result = await _authApi.register(request);
      final session = result.session;

      if (session == null) {
        state = AuthState(
          status: AuthStatus.unauthenticated,
          prefilledEmail: result.email,
        );
        return result;
      }

      final user = session.user ?? await _authApi.getCurrentUser();
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return result;
    } on DioException catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        prefilledEmail: request.email.trim(),
        errorMessage: _errorMessage(
          error,
          'Kayıt oluşturulamadı. Bilgilerinizi kontrol edin.',
        ),
      );
      return null;
    } on FormatException {
      await _authApi.logout();
      state = AuthState(
        status: AuthStatus.unauthenticated,
        prefilledEmail: request.email.trim(),
        errorMessage: 'Sunucu yanıtı okunamadı.',
      );
      return null;
    }
  }

  Future<void> handleUnauthorized() async {
    await _authApi.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> logout() async {
    await _authApi.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  static String _errorMessage(DioException exception, String fallback) {
    final data = exception.response?.data;
    if (data is Map) {
      final json = Map<String, dynamic>.from(data);
      final message = json['error'] ?? json['message'];

      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }

    return fallback;
  }
}
