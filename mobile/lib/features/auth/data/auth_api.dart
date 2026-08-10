import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_store.dart';
import '../domain/auth_models.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(
    dio: ref.watch(dioProvider),
    tokenStore: ref.watch(tokenStoreProvider),
  );
});

class AuthApi {
  AuthApi({required Dio dio, required TokenStore tokenStore})
    : _dio = dio,
      _tokenStore = tokenStore;

  final Dio _dio;
  final TokenStore _tokenStore;

  Future<AuthSession> login(LoginRequest request) async {
    final response = await _dio.post<dynamic>(
      '/api/v1/auth/login',
      data: request.toJson(),
    );

    final session = AuthSession.fromJson(_asJsonMap(response.data));
    await _tokenStore.saveToken(session.accessToken);
    return session;
  }

  Future<RegisterResult> register(RegisterRequest request) async {
    final response = await _dio.post<dynamic>(
      '/api/v1/auth/register',
      data: request.toJson(),
    );

    final json = _asJsonMap(response.data);
    final token = _readOptionalToken(json);

    if (token == null) {
      return RegisterResult.requiresLogin(email: request.email.trim());
    }

    final session = AuthSession.fromJson(json);
    await _tokenStore.saveToken(session.accessToken);

    return RegisterResult.authenticated(
      email: request.email.trim(),
      session: session,
    );
  }

  Future<AuthUser> getCurrentUser() async {
    final response = await _dio.get<dynamic>('/api/v1/me');
    return AuthUser.fromJson(_asJsonMap(response.data));
  }

  Future<String?> readToken() {
    return _tokenStore.readToken();
  }

  Future<void> logout() {
    return _tokenStore.clearToken();
  }

  static Map<String, dynamic> _asJsonMap(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw const FormatException('API yanıtı geçerli bir JSON nesnesi değil.');
  }

  static String? _readOptionalToken(Map<String, dynamic> json) {
    final value = json['accessToken'] ?? json['token'] ?? json['jwt'];

    if (value is! String || value.trim().isEmpty) {
      return null;
    }

    return value.trim();
  }
}
