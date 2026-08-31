import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/api_config.dart';
import '../storage/token_store.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(tokenStore: ref.watch(tokenStoreProvider));
});

final dioProvider = Provider<Dio>((ref) {
  return ref.watch(apiClientProvider).dio;
});

class ApiClient {
  ApiClient({required TokenStore tokenStore, Dio? dio})
    : _tokenStore = tokenStore,
      _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 15),
              headers: const <String, dynamic>{
                Headers.acceptHeader: Headers.jsonContentType,
              },
            ),
          ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStore.readToken();

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            options.headers.remove('Authorization');
          }

          final method = options.method.toUpperCase();
          final hasJsonBody =
              method == 'POST' || method == 'PUT' || method == 'PATCH';

          if (hasJsonBody) {
            options.headers[Headers.contentTypeHeader] =
                Headers.jsonContentType;
          } else {
            options.headers.remove(Headers.contentTypeHeader);
          }

          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await _tokenStore.clearToken();
          }

          handler.next(error);
        },
      ),
    );
  }

  final TokenStore _tokenStore;
  final Dio _dio;

  Dio get dio => _dio;
}
