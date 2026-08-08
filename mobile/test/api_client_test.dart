import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:pulse/core/network/api_client.dart';
import 'package:pulse/core/storage/token_store.dart';

void main() {
  test('JWT Bearer başlığı eklenir ve GET Content-Type taşımaz', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:5000'));
    final adapter = DioAdapter(dio: dio);
    final tokenStore = _FakeTokenStore(token: 'jwt-token');
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
      '/api/v1/feed',
      (server) => server.reply(200, <Map<String, dynamic>>[]),
    );

    await client.dio.get<dynamic>('/api/v1/feed');

    final request = capturedRequest;
    if (request == null) {
      fail('İstek yakalanamadı.');
    }

    expect(request.headers['Authorization'], 'Bearer jwt-token');
    expect(request.headers.containsKey(Headers.contentTypeHeader), isFalse);
  });

  test('POST isteğinde JSON Content-Type eklenir', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:5000'));
    final adapter = DioAdapter(dio: dio);
    final client = ApiClient(tokenStore: _FakeTokenStore(), dio: dio);

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
      '/api/v1/posts',
      (server) => server.reply(201, <String, dynamic>{}),
      data: <String, dynamic>{'content': 'Merhaba'},
    );

    await client.dio.post<dynamic>(
      '/api/v1/posts',
      data: <String, dynamic>{'content': 'Merhaba'},
    );

    final request = capturedRequest;
    if (request == null) {
      fail('İstek yakalanamadı.');
    }

    expect(request.headers[Headers.contentTypeHeader], Headers.jsonContentType);
  });

  test('401 yanıtından sonra kayıtlı token temizlenir', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:5000'));
    final adapter = DioAdapter(dio: dio);
    final tokenStore = _FakeTokenStore(token: 'expired-token');
    final client = ApiClient(tokenStore: tokenStore, dio: dio);

    adapter.onGet(
      '/api/v1/feed',
      (server) => server.reply(401, <String, dynamic>{'error': 'Unauthorized'}),
    );

    await expectLater(
      client.dio.get<dynamic>('/api/v1/feed'),
      throwsA(isA<DioException>()),
    );

    expect(tokenStore.clearCalled, isTrue);
    expect(await tokenStore.readToken(), isNull);
  });
}

class _FakeTokenStore extends TokenStore {
  _FakeTokenStore({this.token});

  String? token;
  bool clearCalled = false;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> saveToken(String value) async {
    token = value;
  }

  @override
  Future<void> clearToken() async {
    clearCalled = true;
    token = null;
  }
}
