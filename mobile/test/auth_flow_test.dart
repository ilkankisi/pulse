import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:pulse/core/network/api_client.dart';
import 'package:pulse/core/storage/token_store.dart';

import 'package:pulse/core/network/api_routes.dart';

void main() {
  test('JWT varsa korumalı isteğe Bearer başlığı eklenir', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:5000'));
    final adapter = DioAdapter(dio: dio);
    final tokenStore = _FakeTokenStore('valid-token');
    final client = ApiClient(tokenStore: tokenStore, dio: dio);

    RequestOptions? capturedRequest;

    client.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedRequest = options;
          handler.next(options);
        },
      ),
    );

    adapter.onGet(
      ApiRoutes.feed,
      (server) => server.reply(200, <Map<String, dynamic>>[]),
    );

    await client.dio.get<dynamic>(ApiRoutes.feed);

    final request = capturedRequest;
    expect(request, isNotNull);
    expect(request?.headers['Authorization'], 'Bearer valid-token');
    expect(request?.headers.containsKey(Headers.contentTypeHeader), isFalse);
  });

  test('token yoksa Authorization başlığı gönderilmez', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:5000'));
    final adapter = DioAdapter(dio: dio);
    final client = ApiClient(tokenStore: _FakeTokenStore(null), dio: dio);

    RequestOptions? capturedRequest;

    client.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedRequest = options;
          handler.next(options);
        },
      ),
    );

    adapter.onGet(
      ApiRoutes.feed,
      (server) => server.reply(200, <Map<String, dynamic>>[]),
    );

    await client.dio.get<dynamic>(ApiRoutes.feed);

    final request = capturedRequest;
    expect(request, isNotNull);
    expect(request?.headers.containsKey('Authorization'), isFalse);
  });

  test('401 yanıtında saklanan JWT temizlenir', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:5000'));
    final adapter = DioAdapter(dio: dio);
    final tokenStore = _FakeTokenStore('expired-token');
    final client = ApiClient(tokenStore: tokenStore, dio: dio);

    adapter.onGet(
      ApiRoutes.feed,
      (server) => server.reply(401, <String, dynamic>{'error': 'Unauthorized'}),
    );

    await expectLater(
      client.dio.get<dynamic>(ApiRoutes.feed),
      throwsA(isA<DioException>()),
    );

    expect(tokenStore.clearCalled, isTrue);
    expect(await tokenStore.readToken(), isNull);
  });

  test('POST isteğine application/json Content-Type eklenir', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:5000'));
    final adapter = DioAdapter(dio: dio);
    final client = ApiClient(
      tokenStore: _FakeTokenStore('valid-token'),
      dio: dio,
    );

    RequestOptions? capturedRequest;

    client.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedRequest = options;
          handler.next(options);
        },
      ),
    );

    adapter.onPost(
      ApiRoutes.posts,
      (server) => server.reply(201, <String, dynamic>{}),
      data: <String, dynamic>{'content': 'Merhaba Pulse'},
    );

    await client.dio.post<dynamic>(
      ApiRoutes.posts,
      data: <String, dynamic>{'content': 'Merhaba Pulse'},
    );

    expect(
      capturedRequest?.headers[Headers.contentTypeHeader],
      Headers.jsonContentType,
    );
  });
}

class _FakeTokenStore extends TokenStore {
  _FakeTokenStore(this._token);

  String? _token;
  bool clearCalled = false;

  @override
  Future<String?> readToken() async {
    return _token;
  }

  @override
  Future<void> saveToken(String token) async {
    _token = token;
  }

  @override
  Future<void> clearToken() async {
    clearCalled = true;
    _token = null;
  }
}
