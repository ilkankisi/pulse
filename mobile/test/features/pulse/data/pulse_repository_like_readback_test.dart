import 'package:dio/dio.dart';

import 'package:flutter_test/flutter_test.dart';

import '../../../../lib/features/pulse/data/pulse_repository.dart';

void main() {
  group('PulseRepository likes write/read integrity', () {
    test('likePost performs POST then consumes canonical GET', () async {
      final calls = <String>[];

      final dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            calls.add('${options.method} ${options.path}');

            if (options.method == 'POST') {
              handler.resolve(
                Response<dynamic>(requestOptions: options, statusCode: 204),
              );
              return;
            }

            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: const <dynamic>[
                  <String, dynamic>{'username': 'ada', 'displayName': 'Ada'},
                ],
              ),
            );
          },
        ),
      );

      final repository = PulseRepository(dio: dio);

      final result = await repository.likePost(42);

      expect(calls, <String>[
        'POST /api/v1/posts/42/likes',
        'GET /api/v1/posts/42/likes',
      ]);
      expect(result, isA<List<dynamic>>());
      expect((result as List<dynamic>).length, 1);
    });

    test('unlikePost performs DELETE then consumes canonical GET', () async {
      final calls = <String>[];
      final dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            calls.add('${options.method} ${options.path}');

            if (options.method == 'DELETE') {
              handler.resolve(
                Response<dynamic>(requestOptions: options, statusCode: 204),
              );
              return;
            }

            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: const <dynamic>[],
              ),
            );
          },
        ),
      );

      final repository = PulseRepository(dio: dio);

      final result = await repository.unlikePost(42);

      expect(calls, <String>[
        'DELETE /api/v1/posts/42/likes',
        'GET /api/v1/posts/42/likes',
      ]);
      expect(result, isA<List<dynamic>>());
      expect(result, isEmpty);
    });

    test('likePost rejects an unreadable canonical GET payload', () async {
      final dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: options.method == 'POST' ? 204 : 200,
                data: null,
              ),
            );
          },
        ),
      );

      final repository = PulseRepository(dio: dio);

      expect(() => repository.likePost(42), throwsA(isA<FormatException>()));
    });
  });
}
