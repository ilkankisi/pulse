import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
    final repository = _ProfilePostsRepository((username) async {
      expect(username, 'ilkan');

      return <PulsePost>[
        _post(
          id: 12,
          username: 'ilkan',
          displayName: 'İlkan',
          content: 'İkinci profil gönderisi',
          likeCount: 4,
          replyCount: 1,
          isLiked: true,
        ),
        _post(
          id: 11,
          username: 'ilkan',
          displayName: 'İlkan',
          content: 'İlk profil gönderisi',
          likeCount: 2,
        ),
      ];
    });

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

    final repository = _ProfilePostsRepository((username) async {
      expect(username, 'ayse');

      return <PulsePost>[
        _post(
          id: 21,
          authorId: 9,
          username: 'ayse',
          displayName: 'Ayşe',
          content: 'Ayşe profil gönderisi',
          likeCount: 1,
          replyCount: 2,
        ),
      ];
    });

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

    final repository = _ProfilePostsRepository(
      (_) async => const <PulsePost>[],
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
    var profileLoadCount = 0;
    var postsLoadCount = 0;

    final repository = _ProfilePostsRepository((username) async {
      expect(username, 'ilkan');

      postsLoadCount++;

      return <PulsePost>[
        _post(
          id: postsLoadCount,
          username: 'ilkan',
          displayName: 'İlkan',
          content: postsLoadCount == 1 ? 'İlk yükleme' : 'Yenilenmiş gönderi',
        ),
      ];
    });

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

    await refreshIndicator.onRefresh();
    await tester.pump();

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
    var postsLoadCount = 0;

    final repository = _ProfilePostsRepository((username) async {
      expect(username, 'ilkan');

      postsLoadCount++;

      if (postsLoadCount == 1) {
        throw StateError('Gönderiler yüklenemedi.');
      }

      return <PulsePost>[
        _post(
          id: 31,
          username: 'ilkan',
          displayName: 'İlkan',
          content: 'Tekrar deneme başarılı',
        ),
      ];
    });

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
    final repository = _ProfilePostsRepository(
      (_) async => const <PulsePost>[],
    );

    final saveStarted = Completer<void>();
    final allowSaveToFinish = Completer<void>();
    Map<String, dynamic>? capturedUpdateBody;

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

class _ProfilePostsRepository extends PulseRepository {
  _ProfilePostsRepository(this._loadPosts) : super(dio: Dio());

  final Future<List<PulsePost>> Function(String username) _loadPosts;

  @override
  Future<List<PulsePost>> getProfilePosts(String username) {
    return _loadPosts(username);
  }
}

PulsePost _post({
  required int id,
  int authorId = 1,
  required String username,
  required String displayName,
  required String content,
  int likeCount = 0,
  int replyCount = 0,
  bool isLiked = false,
}) {
  return PulsePost.fromJson(<String, dynamic>{
    'id': id,
    'content': content,
    'createdAt': '2026-08-07T12:00:00Z',
    'author': <String, dynamic>{
      'id': authorId,
      'username': username,
      'displayName': displayName,
      'avatarUrl': null,
    },
    'likeCount': likeCount,
    'replyCount': replyCount,
    'isLikedByMe': isLiked,
    'parentPostId': null,
  });
}
