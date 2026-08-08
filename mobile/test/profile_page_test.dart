import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:pulse/features/pulse/data/pulse_repository.dart';
import 'package:pulse/features/pulse/domain/pulse_models.dart';
import 'package:pulse/features/pulse/presentation/profile_page.dart';

void main() {
  const profile = PulseProfile(
    id: 1,
    username: 'ilkan',
    displayName: 'İlkan',
    bio: 'Pulse kullanıcısı',
    avatarUrl: null,
    followerCount: 2,
    followingCount: 3,
    postCount: 2,
    isFollowing: false,
    isCurrentUser: true,
  );

  testWidgets('profil ekranı kullanıcının gönderilerini listeler', (
    tester,
  ) async {
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:5000'));
    final adapter = DioAdapter(dio: dio);
    final repository = PulseRepository(dio: dio);

    addTearDown(() => dio.close(force: true));

    const postsPath = '/api/v1/profiles/ilkan/posts';

    adapter.onGet(
      postsPath,
      (server) => server.reply(200, <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 12,
          'content': 'İkinci profil gönderisi',
          'createdAt': '2026-08-07T12:00:00Z',
          'author': <String, dynamic>{
            'id': 1,
            'username': 'ilkan',
            'displayName': 'İlkan',
            'avatarUrl': null,
          },
          'likeCount': 4,
          'replyCount': 1,
          'isLiked': true,
          'canDelete': true,
          'replyToPostId': null,
        },
        <String, dynamic>{
          'id': 11,
          'content': 'İlk profil gönderisi',
          'createdAt': '2026-08-07T11:00:00Z',
          'author': <String, dynamic>{
            'id': 1,
            'username': 'ilkan',
            'displayName': 'İlkan',
            'avatarUrl': null,
          },
          'likeCount': 2,
          'replyCount': 0,
          'isLiked': false,
          'canDelete': true,
          'replyToPostId': null,
        },
      ]),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          pulseRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ProfilePage(
              initialProfile: profile,
              loadProfile: () async => profile,
              showAppBar: false,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Gönderiler'), findsOneWidget);
    expect(find.text('İkinci profil gönderisi'), findsOneWidget);
    expect(find.text('İlk profil gönderisi'), findsOneWidget);
    expect(find.text('Henüz gönderi yok'), findsNothing);
  });

  testWidgets('başka kullanıcının profil gönderileri aynı akışta gösterilir', (
    tester,
  ) async {
    const otherProfile = PulseProfile(
      id: 9,
      username: 'ayse',
      displayName: 'Ayşe',
      bio: 'Merhaba',
      avatarUrl: null,
      followerCount: 5,
      followingCount: 2,
      postCount: 1,
      isFollowing: true,
      isCurrentUser: false,
    );

    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:5000'));
    final adapter = DioAdapter(dio: dio);
    final repository = PulseRepository(dio: dio);

    addTearDown(() => dio.close(force: true));

    const postsPath = '/api/v1/profiles/ayse/posts';

    adapter.onGet(
      postsPath,
      (server) => server.reply(200, <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 21,
          'content': 'Ayşe profil gönderisi',
          'createdAt': '2026-08-07T13:00:00Z',
          'author': <String, dynamic>{
            'id': 9,
            'username': 'ayse',
            'displayName': 'Ayşe',
            'avatarUrl': null,
          },
          'likeCount': 1,
          'replyCount': 2,
          'isLiked': false,
          'canDelete': false,
          'replyToPostId': null,
        },
      ]),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          pulseRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ProfilePage(
              username: 'ayse',
              initialProfile: otherProfile,
              loadProfile: () async => otherProfile,
              isCurrentUser: false,
              showAppBar: false,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Ayşe profil gönderisi'), findsOneWidget);
    expect(find.text('Profili Düzenle'), findsNothing);
  });

  testWidgets('gönderisi olmayan profil empty state gösterir', (tester) async {
    const emptyProfile = PulseProfile(
      id: 1,
      username: 'ilkan',
      displayName: 'İlkan',
      bio: null,
      avatarUrl: null,
      followerCount: 0,
      followingCount: 0,
      postCount: 0,
      isFollowing: false,
      isCurrentUser: true,
    );

    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:5000'));
    final adapter = DioAdapter(dio: dio);
    final repository = PulseRepository(dio: dio);

    addTearDown(() => dio.close(force: true));

    adapter.onGet(
      '/api/v1/profiles/ilkan/posts',
      (server) => server.reply(200, <Map<String, dynamic>>[]),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          pulseRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ProfilePage(
              initialProfile: emptyProfile,
              loadProfile: () async => emptyProfile,
              showAppBar: false,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Henüz gönderi yok'), findsOneWidget);
    expect(
      find.text('Paylaştığın gönderiler burada görünecek.'),
      findsOneWidget,
    );
    expect(find.text('Gönderiler yüklenemedi'), findsNothing);
  });

  testWidgets('pull-to-refresh profil ve gönderileri birlikte yeniler', (
    tester,
  ) async {
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:5000'));
    final repository = PulseRepository(dio: dio);

    addTearDown(() => dio.close(force: true));

    var profileLoadCount = 0;
    var postsLoadCount = 0;

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path != '/api/v1/profiles/ilkan/posts') {
            handler.next(options);
            return;
          }

          postsLoadCount++;

          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': postsLoadCount,
                  'content': postsLoadCount == 1
                      ? 'İlk yükleme'
                      : 'Yenilenmiş gönderi',
                  'createdAt': '2026-08-07T12:00:00Z',
                  'author': <String, dynamic>{
                    'id': 1,
                    'username': 'ilkan',
                    'displayName': 'İlkan',
                    'avatarUrl': null,
                  },
                  'likeCount': 0,
                  'replyCount': 0,
                  'isLiked': false,
                  'canDelete': true,
                  'replyToPostId': null,
                },
              ],
            ),
          );
        },
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          pulseRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ProfilePage(
              initialProfile: profile,
              loadProfile: () async {
                profileLoadCount++;
                return profile;
              },
              showAppBar: false,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('İlk yükleme'), findsOneWidget);
    expect(profileLoadCount, 1);
    expect(postsLoadCount, 1);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 500));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(profileLoadCount, 2);
    expect(postsLoadCount, 2);
    expect(find.text('Yenilenmiş gönderi'), findsOneWidget);
  });

  testWidgets('profil gönderileri yüklenemezse retry state gösterilir', (
    tester,
  ) async {
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:5000'));
    final repository = PulseRepository(dio: dio);

    addTearDown(() => dio.close(force: true));

    var requestCount = 0;

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path != '/api/v1/profiles/ilkan/posts') {
            handler.next(options);
            return;
          }

          requestCount++;

          if (requestCount == 1) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response<dynamic>(
                  requestOptions: options,
                  statusCode: 500,
                  data: <String, dynamic>{'error': 'Sunucu hatası'},
                ),
                type: DioExceptionType.badResponse,
              ),
            );
            return;
          }

          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 31,
                  'content': 'Tekrar deneme başarılı',
                  'createdAt': '2026-08-07T14:00:00Z',
                  'author': <String, dynamic>{
                    'id': 1,
                    'username': 'ilkan',
                    'displayName': 'İlkan',
                    'avatarUrl': null,
                  },
                  'likeCount': 0,
                  'replyCount': 0,
                  'isLiked': false,
                  'canDelete': true,
                  'replyToPostId': null,
                },
              ],
            ),
          );
        },
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          pulseRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ProfilePage(
              initialProfile: profile,
              loadProfile: () async => profile,
              showAppBar: false,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(requestCount, 1);
    expect(find.text('Gönderiler yüklenemedi'), findsOneWidget);

    final retryButton = find.widgetWithText(FilledButton, 'Tekrar Dene');

    await tester.ensureVisible(retryButton);
    await tester.tap(retryButton);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(requestCount, 2);
    expect(find.text('Tekrar deneme başarılı'), findsOneWidget);
    expect(find.text('Gönderiler yüklenemedi'), findsNothing);
  });

  testWidgets('profil düzenleme dialogu güvenle kapanır ve snackbar gösterir', (
    tester,
  ) async {
    const updatedProfile = PulseProfile(
      id: 1,
      username: 'ilkan',
      displayName: 'İlkan Kişi',
      bio: 'Yeni biyografi',
      avatarUrl: '',
      followerCount: 2,
      followingCount: 3,
      postCount: 2,
      isFollowing: false,
      isCurrentUser: true,
    );

    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:5000'));
    final adapter = DioAdapter(dio: dio);
    final repository = PulseRepository(dio: dio);

    final saveStarted = Completer<void>();
    final allowSaveToFinish = Completer<void>();
    Map<String, dynamic>? submittedBody;

    addTearDown(() {
      if (!saveStarted.isCompleted) {
        saveStarted.complete();
      }

      if (!allowSaveToFinish.isCompleted) {
        allowSaveToFinish.complete();
      }

      dio.close(force: true);
    });

    adapter.onGet(
      '/api/v1/profiles/ilkan/posts',
      (server) => server.reply(200, <Map<String, dynamic>>[]),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          pulseRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ProfilePage(
              initialProfile: profile,
              loadProfile: () async => profile,
              updateProfile: (request) async {
                submittedBody = request.toJson();

                if (!saveStarted.isCompleted) {
                  saveStarted.complete();
                }

                await allowSaveToFinish.future;
                return updatedProfile;
              },
              showAppBar: false,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Profili Düzenle'), findsOneWidget);

    await tester.tap(find.text('Profili Düzenle'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(AlertDialog), findsOneWidget);

    final displayNameField = find.byKey(
      const ValueKey<String>('profile-display-name-field'),
    );
    final bioField = find.byKey(const ValueKey<String>('profile-bio-field'));

    await tester.enterText(displayNameField, 'İlkan Kişi');
    await tester.enterText(bioField, 'Yeni biyografi');

    await tester.tap(find.widgetWithText(FilledButton, 'Kaydet'));
    await tester.pump();

    await saveStarted.future;

    expect(tester.takeException(), isNull);
    expect(submittedBody, <String, dynamic>{
      'displayName': 'İlkan Kişi',
      'bio': 'Yeni biyografi',
    });
    expect(find.byType(AlertDialog), findsOneWidget);

    allowSaveToFinish.complete();

    for (var index = 0; index < 40; index++) {
      await tester.pump(const Duration(milliseconds: 50));

      final dialogClosed = find.byType(AlertDialog).evaluate().isEmpty;
      final snackbarVisible = find
          .text('Profil güncellendi.')
          .evaluate()
          .isNotEmpty;

      if (dialogClosed && snackbarVisible) {
        break;
      }
    }

    expect(tester.takeException(), isNull);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Profil güncellendi.'), findsOneWidget);
    expect(find.text('İlkan Kişi'), findsOneWidget);
    expect(find.text('Yeni biyografi'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
