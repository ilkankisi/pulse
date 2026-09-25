import 'package:dio/dio.dart';

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import '../../../../lib/features/pulse/data/pulse_repository.dart';

import '../../../../lib/features/pulse/presentation/post_detail_page.dart';

void main() {
  Future<void> pumpLikesPage(
    WidgetTester tester, {

    required PulseRepository repository,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PostLikesPage(
          postId: 7,

          repository: repository,

          onUnauthorized: () async {},
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('renders canonical likes list on success', (tester) async {
    final dio = Dio();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: const <dynamic>[
                <String, dynamic>{
                  'username': 'ada',
                  'displayName': 'Ada Lovelace',
                },
              ],
            ),
          );
        },
      ),
    );

    await pumpLikesPage(tester, repository: PulseRepository(dio: dio));

    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.text('@ada'), findsOneWidget);
  });

  testWidgets('renders empty state for an empty canonical list', (
    tester,
  ) async {
    final dio = Dio();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
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

    await pumpLikesPage(tester, repository: PulseRepository(dio: dio));

    expect(find.text('Henüz beğenen yok.'), findsOneWidget);
  });

  testWidgets('renders error state and retry reloads without stale users', (
    tester,
  ) async {
    var attempts = 0;

    final dio = Dio();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          attempts += 1;

          if (attempts == 1) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response<dynamic>(
                  requestOptions: options,
                  statusCode: 500,
                ),
              ),
            );
            return;
          }

          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: const <dynamic>[
                <String, dynamic>{
                  'username': 'grace',
                  'displayName': 'Grace Hopper',
                },
              ],
            ),
          );
        },
      ),
    );

    await pumpLikesPage(tester, repository: PulseRepository(dio: dio));

    expect(find.text('Beğenenler yüklenemedi.'), findsOneWidget);
    expect(find.text('Grace Hopper'), findsNothing);

    await tester.tap(find.text('Tekrar dene'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Beğenenler yüklenemedi.'), findsNothing);
    expect(find.text('Grace Hopper'), findsOneWidget);
    expect(find.text('@grace'), findsOneWidget);
  });
}
