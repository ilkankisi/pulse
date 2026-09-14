import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:pulse/core/network/api_routes.dart';
import 'package:pulse/features/pulse/data/pulse_repository.dart';

void main() {
  test('feed 404 empty state için boş liste döner', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:5000'));
    final adapter = DioAdapter(dio: dio);
    final repository = PulseRepository(dio: dio);

    addTearDown(() => dio.close(force: true));

    RequestOptions? capturedRequest;

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedRequest = options;
          handler.next(options);
        },
      ),
    );

    adapter.onGet(
      ApiRoutes.feed,
      (server) => server.reply(404, <String, dynamic>{
        'error': 'Feed not found.',
        'field': null,
      }),
    );

    final posts = await repository.getFeed();

    expect(posts, isEmpty);

    final request = capturedRequest;
    expect(request, isNotNull);
    expect(request!.method, 'GET');
    expect(request.uri.path, ApiRoutes.feed);
    expect(request.data, isNull);
  });
}
