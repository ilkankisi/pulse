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
      (server) => server.reply(200, <String, dynamic>{
        'items': <Map<String, dynamic>>[
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
            'isLikedByMe': true,
            'parentPostId': null,
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
            'isLikedByMe': false,
            'parentPostId': null,
          },
        ],
      }),
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
      (server) => server.reply(200, <String, dynamic>{
        'items': <Map<String, dynamic>>[
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
            'isLikedByMe': false,
            'parentPostId': null,
          },
        ],
      }),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          pulseRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ProfilePage(
              initialProfile: otherProfile,
              loadProfile: () async => otherProfile,
              showAppBar: false,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Ayşe profil gönderisi'), findsOneWidget);
    expect(find.text('Henüz gönderi yok'), findsNothing);
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
      (server) => server.reply(200, <String, dynamic>{
        'items': <Map<String, dynamic>>[],
      }),
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
              data: <String, dynamic>{
                'items': <Map<String, dynamic>>[
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
                    'isLikedByMe': false,
                    'parentPostId': null,
                  },
                ],
              },
            ),
          );
        },
      ),
    );

    Future<PulseProfile> loadProfile() async {
      profileLoadCount++;
      return profile;
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          pulseRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ProfilePage(
              initialProfile: profile,
              loadProfile: loadProfile,
              showAppBar: false,
            ),
          ),
        ),
      ),
    );

    for (var i = 0; i < 40 && postsLoadCount < 1; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(profileLoadCount, 1);
    expect(postsLoadCount, 1);
    expect(find.text('İlk yükleme'), findsOneWidget);
    expect(find.text('Yenilenmiş gönderi'), findsNothing);

    final refreshIndicator = tester.widget<RefreshIndicator>(
      find.byType(RefreshIndicator),
    );

    unawaited(refreshIndicator.onRefresh());

    for (var i = 0; i < 40 && postsLoadCount < 2; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    for (
      var i = 0;
      i < 40 && find.text('Yenilenmiş gönderi').evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(tester.takeException(), isNull);
    expect(profileLoadCount, 2);
    expect(postsLoadCount, 2);
    expect(find.text('İlk yükleme'), findsNothing);
    expect(find.text('Yenilenmiş gönderi'), findsOneWidget);
  });

  testWidgets('profil gönderileri yüklenemezse retry state gösterilir', (
    tester,
  ) async {
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:5000'));
    final repository = PulseRepository(dio: dio);

    addTearDown(() => dio.close(force: true));

    var postsLoadCount = 0;

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path != '/api/v1/profiles/ilkan/posts') {
            handler.next(options);
            return;
          }

          postsLoadCount++;

          if (postsLoadCount == 1) {
            final response = Response<dynamic>(
              requestOptions: options,
              statusCode: 500,
              data: <String, dynamic>{
                'error': 'Gönderiler yüklenemedi.',
                'field': null,
              },
            );

            handler.reject(
              DioException(
                requestOptions: options,
                response: response,
                type: DioExceptionType.badResponse,
              ),
            );
            return;
          }

          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: <String, dynamic>{
                'items': <Map<String, dynamic>>[
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
                    'isLikedByMe': false,
                    'parentPostId': null,
                  },
                ],
              },
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

    for (
      var i = 0;
      i < 40 && find.text('Gönderiler yüklenemedi').evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(tester.takeException(), isNull);
    expect(postsLoadCount, 1);
    expect(find.text('Gönderiler yüklenemedi'), findsOneWidget);

    final retryButton = find.text('Tekrar Dene');

    expect(retryButton, findsOneWidget);

    await tester.tap(retryButton);
    await tester.pump();

    for (var i = 0; i < 40 && postsLoadCount < 2; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    for (
      var i = 0;
      i < 40 && find.text('Tekrar deneme başarılı').evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(tester.takeException(), isNull);
    expect(postsLoadCount, 2);
    expect(find.text('Gönderiler yüklenemedi'), findsNothing);
    expect(find.text('Tekrar deneme başarılı'), findsOneWidget);
  });

  testWidgets('profil düzenleme dialogu güvenle kapanır ve snackbar gösterir', (
    tester,
  ) async {
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:5000'));
    final repository = PulseRepository(dio: dio);

    addTearDown(() => dio.close(force: true));

    final saveStarted = Completer<void>();
    final allowSaveToFinish = Completer<void>();
    Map<String, dynamic>? capturedUpdateBody;

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.method == 'GET' &&
              options.path == '/api/v1/profiles/ilkan/posts') {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: <String, dynamic>{'items': <Map<String, dynamic>>[]},
              ),
            );
            return;
          }

          handler.next(options);
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
              updateProfile: (request) async {
                capturedUpdateBody = request.toJson();

                if (!saveStarted.isCompleted) {
                  saveStarted.complete();
                }

                await allowSaveToFinish.future;

                return const PulseProfile(
                  id: 1,
                  username: 'ilkan',
                  displayName: 'İlkan Kişi',
                  bio: 'Yeni biyografi',
                  avatarUrl: null,
                  followerCount: 2,
                  followingCount: 3,
                  postCount: 2,
                  isFollowing: false,
                  isCurrentUser: true,
                );
              },
              showAppBar: false,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Profili Düzenle'));
    await tester.pumpAndSettle();

    final editDialog = find.byType(AlertDialog);

    expect(editDialog, findsOneWidget);
    expect(find.byKey(const Key('profile-display-name-field')), findsOneWidget);
    expect(find.byKey(const Key('profile-bio-field')), findsOneWidget);
    expect(find.byKey(const Key('profile-avatar-url-field')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('profile-display-name-field')),
      'İlkan Kişi',
    );
    await tester.enterText(
      find.byKey(const Key('profile-bio-field')),
      'Yeni biyografi',
    );

    final dialogSaveButton = find.descendant(
      of: editDialog,
      matching: find.byKey(const ValueKey<String>('profile-save-button')),
    );

    expect(dialogSaveButton, findsOneWidget);

    final saveButton = tester.widget<FilledButton>(dialogSaveButton);

    expect(saveButton.onPressed, isNotNull);

    saveButton.onPressed!.call();
    await tester.pump();

    for (var i = 0; i < 20 && !saveStarted.isCompleted; i++) {
      await tester.pump();
    }

    expect(saveStarted.isCompleted, isTrue);
    expect(editDialog, findsOneWidget);
    expect(dialogSaveButton, findsOneWidget);

    final updateBody = capturedUpdateBody;

    expect(updateBody, isNotNull);
    expect(updateBody?['displayName'], 'İlkan Kişi');
    expect(updateBody?['bio'], 'Yeni biyografi');
    expect(updateBody?.containsKey('avatarUrl'), isTrue);

    allowSaveToFinish.complete();

    await tester.pump();
    await tester.pumpAndSettle();

    expect(editDialog, findsNothing);
    expect(dialogSaveButton, findsNothing);
    expect(find.text('Profil güncellendi.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
