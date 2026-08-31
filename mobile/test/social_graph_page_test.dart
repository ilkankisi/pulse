import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/pulse/data/pulse_repository.dart';
import 'package:pulse/features/pulse/domain/pulse_models.dart';
import 'package:pulse/features/pulse/presentation/profile_page.dart';
import 'package:pulse/features/pulse/presentation/social_graph_page.dart';

void main() {
  // Zorunlu social graph kabul kapsamı:
  // loading/açılış, empty, error/retry, profile navigation,
  // kendi takipçisini kaldırma, profil sayaçları ve zincir navigasyonu.
  const users = <SocialGraphUser>[
    SocialGraphUser(
      id: 2,
      username: 'ada',
      displayName: 'Ada',
      isFollowing: true,
    ),
  ];

  testWidgets('takipçiler ekranı açılır ve loading state gösterilir', (
    tester,
  ) async {
    final completer = Completer<List<SocialGraphUser>>();

    await tester.pumpWidget(
      MaterialApp(
        home: SocialGraphPage(
          username: 'ilkan',
          kind: SocialGraphKind.followers,
          isCurrentUser: true,
          loadUsers: () => completer.future,
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Takipçiler'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(users);
    await tester.pumpAndSettle();

    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('@ada'), findsOneWidget);
  });

  testWidgets('takip edilenler ekranı empty state gösterir', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SocialGraphPage(
          username: 'ilkan',
          kind: SocialGraphKind.following,
          isCurrentUser: true,
          loadUsers: () async => const <SocialGraphUser>[],
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Takip Edilenler'), findsOneWidget);
    expect(find.text('Henüz kimse yok'), findsOneWidget);
  });

  testWidgets('takipçiler ekranı error ve retry state gösterir', (
    tester,
  ) async {
    var attempts = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: SocialGraphPage(
          username: 'ilkan',
          kind: SocialGraphKind.followers,
          isCurrentUser: true,
          loadUsers: () async {
            attempts += 1;

            if (attempts == 1) {
              throw StateError('network error');
            }

            return users;
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Liste yüklenemedi'), findsOneWidget);
    expect(find.text('Tekrar Dene'), findsOneWidget);

    await tester.tap(find.text('Tekrar Dene'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Liste yüklenemedi'), findsNothing);
  });

  testWidgets('listedeki kullanıcıdan profile navigation yapılır', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SocialGraphPage(
          username: 'ilkan',
          kind: SocialGraphKind.following,
          isCurrentUser: true,
          loadUsers: () async => users,
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Ada'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfilePage), findsOneWidget);

    final profilePage = tester.widget<ProfilePage>(find.byType(ProfilePage));

    expect(profilePage.username, 'ada');
  });

  testWidgets('kendi takipçisi listeden kaldırılabilir', (tester) async {
    String? removedUsername;

    await tester.pumpWidget(
      MaterialApp(
        home: SocialGraphPage(
          username: 'ilkan',
          kind: SocialGraphKind.followers,
          isCurrentUser: true,
          loadUsers: () async => users,
          removeFollower: (username) async {
            removedUsername = username;
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Kaldır'), findsOneWidget);

    await tester.tap(find.text('Kaldır'));
    await tester.pumpAndSettle();

    expect(removedUsername, 'ada');
    expect(find.text('Ada'), findsNothing);
  });

  testWidgets(
    'kendi profil Takipçi ve Takip sayaçları profile.username ile doğru social graph modunu açar',
    (tester) async {
      const profile = PulseProfile(
        id: 1,
        username: 'ilkan',
        displayName: 'İlkan',
        followerCount: 2,
        followingCount: 3,
        postCount: 0,
        isFollowing: false,
        isCurrentUser: true,
      );

      final dio = Dio();
      final repository = _RecordingPulseRepository(dio);

      addTearDown(() => dio.close(force: true));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [pulseRepositoryProvider.overrideWithValue(repository)],
          child: MaterialApp(
            home: ProfilePage(
              initialProfile: profile,
              loadProfile: () async => profile,
              showAppBar: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Takipçi'));
      await tester.pumpAndSettle();

      var page = tester.widget<SocialGraphPage>(find.byType(SocialGraphPage));

      expect(page.username, profile.username);
      expect(page.username, 'ilkan');
      expect(page.kind, SocialGraphKind.followers);
      expect(page.isCurrentUser, isTrue);
      expect(repository.followerUsernames, <String>['ilkan']);

      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Takip'));
      await tester.pumpAndSettle();

      page = tester.widget<SocialGraphPage>(find.byType(SocialGraphPage));

      expect(page.username, profile.username);
      expect(page.username, 'ilkan');
      expect(page.kind, SocialGraphKind.following);
      expect(page.isCurrentUser, isTrue);
      expect(repository.followingUsernames, <String>['ilkan']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'başka profil Takipçi ve Takip sayaçları session yerine görüntülenen profile.username kullanır',
    (tester) async {
      const profile = PulseProfile(
        id: 9,
        username: 'ayse',
        displayName: 'Ayşe',
        followerCount: 5,
        followingCount: 2,
        postCount: 0,
        isFollowing: true,
        isCurrentUser: false,
      );

      final dio = Dio();
      final repository = _RecordingPulseRepository(dio);

      addTearDown(() => dio.close(force: true));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [pulseRepositoryProvider.overrideWithValue(repository)],
          child: MaterialApp(
            home: ProfilePage(
              username: profile.username,
              initialProfile: profile,
              loadProfile: () async => profile,
              isCurrentUser: false,
              showAppBar: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Takipçi'));
      await tester.pumpAndSettle();

      var page = tester.widget<SocialGraphPage>(find.byType(SocialGraphPage));

      expect(page.username, profile.username);
      expect(page.username, 'ayse');
      expect(page.username, isNot('ilkan'));
      expect(page.kind, SocialGraphKind.followers);
      expect(page.isCurrentUser, isFalse);
      expect(repository.followerUsernames, <String>['ayse']);

      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Takip'));
      await tester.pumpAndSettle();

      page = tester.widget<SocialGraphPage>(find.byType(SocialGraphPage));

      expect(page.username, profile.username);
      expect(page.username, 'ayse');
      expect(page.username, isNot('ilkan'));
      expect(page.kind, SocialGraphKind.following);
      expect(page.isCurrentUser, isFalse);
      expect(repository.followingUsernames, <String>['ayse']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Profil A sosyal graf listesinden Profil B açılır ve Profil B social graph listesi Profil B username kullanır',
    (tester) async {
      final dio = Dio();
      final repository = _RecordingPulseRepository(dio);

      addTearDown(() => dio.close(force: true));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [pulseRepositoryProvider.overrideWithValue(repository)],
          child: MaterialApp(
            home: SocialGraphPage(
              username: 'profil-a',
              kind: SocialGraphKind.followers,
              isCurrentUser: true,
              loadUsers: () async => users,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      var graphPage = tester.widget<SocialGraphPage>(
        find.byType(SocialGraphPage),
      );

      expect(graphPage.username, 'profil-a');
      expect(graphPage.kind, SocialGraphKind.followers);

      await tester.tap(find.text('Ada'));
      await tester.pumpAndSettle();

      final profileB = tester.widget<ProfilePage>(find.byType(ProfilePage));

      expect(profileB.username, 'ada');

      await tester.tap(find.text('Takip'));
      await tester.pumpAndSettle();

      graphPage = tester.widget<SocialGraphPage>(find.byType(SocialGraphPage));

      expect(graphPage.username, 'ada');
      expect(graphPage.username, isNot('profil-a'));
      expect(graphPage.kind, SocialGraphKind.following);
      expect(graphPage.isCurrentUser, isFalse);
      expect(repository.followingUsernames, <String>['ada']);
      expect(repository.followingUsernames, isNot(contains('profil-a')));
      expect(tester.takeException(), isNull);
    },
  );
}

class _RecordingPulseRepository extends PulseRepository {
  _RecordingPulseRepository(Dio dio) : super(dio: dio);

  final List<String> postUsernames = <String>[];
  final List<String> followerUsernames = <String>[];
  final List<String> followingUsernames = <String>[];

  @override
  Future<List<PulsePost>> getProfilePosts(String username) async {
    postUsernames.add(username);
    return const <PulsePost>[];
  }

  @override
  Future<List<PulseSocialGraphUser>> getFollowers(String username) async {
    followerUsernames.add(username);
    return const <PulseSocialGraphUser>[];
  }

  @override
  Future<List<PulseSocialGraphUser>> getFollowing(String username) async {
    followingUsernames.add(username);
    return const <PulseSocialGraphUser>[];
  }
}
