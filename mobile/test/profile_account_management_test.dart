import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/pulse/data/pulse_repository.dart';
import 'package:pulse/features/pulse/domain/pulse_models.dart';
import 'package:pulse/features/pulse/presentation/profile_page.dart';

void main() {
  const otherProfile = PulseProfile(
    id: 2,
    username: 'ada',
    displayName: 'Ada',
    followerCount: 12,
    followingCount: 4,
    postCount: 8,
    isFollowing: false,
    isCurrentUser: false,
  );

  const ownProfile = PulseProfile(
    id: 1,
    username: 'ilkan',
    displayName: 'İlkan',
    followerCount: 20,
    followingCount: 7,
    postCount: 9,
    isFollowing: false,
    isCurrentUser: true,
  );

  testWidgets(
    'Takip Et optimistic olarak butonu ve followerCount değerini günceller',
    (tester) async {
      final repository = _FakePulseRepository(profile: otherProfile);
      final completer = Completer<void>();
      repository.followFuture = completer.future;

      await tester.pumpWidget(
        _buildProfile(
          repository: repository,
          profile: otherProfile,
          isCurrentUser: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Takip Et'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);

      await tester.tap(find.byKey(const Key('profile-follow-button')));
      await tester.pump();

      expect(repository.followedUsername, 'ada');
      expect(find.text('Takipten Çık'), findsOneWidget);
      expect(find.text('13'), findsOneWidget);

      completer.complete();
      await tester.pumpAndSettle();

      expect(find.text('Takipten Çık'), findsOneWidget);
      expect(find.text('13'), findsOneWidget);
    },
  );

  testWidgets(
    'Takipten Çık başarısız olursa optimistic değişiklik rollback edilir',
    (tester) async {
      final profile = otherProfile.copyWith(
        isFollowing: true,
        followerCount: 12,
      );
      final repository = _FakePulseRepository(profile: profile);
      final completer = Completer<void>();
      repository.unfollowFuture = completer.future;

      await tester.pumpWidget(
        _buildProfile(
          repository: repository,
          profile: profile,
          isCurrentUser: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Takipten Çık'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);

      await tester.tap(find.byKey(const Key('profile-follow-button')));
      await tester.pump();

      expect(repository.unfollowedUsername, 'ada');
      expect(find.text('Takip Et'), findsOneWidget);
      expect(find.text('11'), findsOneWidget);

      completer.completeError(StateError('network error'));
      await tester.pumpAndSettle();

      expect(find.text('Takipten Çık'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(
        find.text('Takip işlemi tamamlanamadı. Tekrar deneyin.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Ayarlar ekranına gidilir ve hesap silme dialogu iptal edilebilir',
    (tester) async {
      var deleteCalled = false;

      await tester.pumpWidget(
        _buildProfile(
          repository: _FakePulseRepository(profile: ownProfile),
          profile: ownProfile,
          isCurrentUser: true,
          deleteAccount: () async {
            deleteCalled = true;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('profile-settings-button')));
      await tester.pumpAndSettle();

      expect(find.text('Ayarlar'), findsWidgets);
      expect(find.text('Hesabımı Sil'), findsOneWidget);

      await tester.tap(find.byKey(const Key('delete-account-tile')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Vazgeç'), findsOneWidget);
      expect(find.text('Hesabı Sil'), findsOneWidget);

      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();

      expect(deleteCalled, isFalse);
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets(
    'hesap silme onaylandığında başarılı action ve completion çağrılır',
    (tester) async {
      var deleteCalled = false;
      var accountDeletedCalled = false;

      await tester.pumpWidget(
        _buildProfile(
          repository: _FakePulseRepository(profile: ownProfile),
          profile: ownProfile,
          isCurrentUser: true,
          deleteAccount: () async {
            deleteCalled = true;
          },
          onAccountDeleted: () async {
            accountDeletedCalled = true;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('profile-settings-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('delete-account-tile')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-delete-account')));
      await tester.pumpAndSettle();

      expect(deleteCalled, isTrue);
      expect(accountDeletedCalled, isTrue);
      expect(find.byKey(const Key('delete-account-error')), findsNothing);
    },
  );

  testWidgets('hesap silme action hatası kullanıcıya error state gösterir', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildProfile(
        repository: _FakePulseRepository(profile: ownProfile),
        profile: ownProfile,
        isCurrentUser: true,
        deleteAccount: () async {
          throw StateError('delete failed');
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('profile-settings-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-account-tile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-delete-account')));
    await tester.pumpAndSettle();

    expect(find.text('Hesap silinemedi. Tekrar deneyin.'), findsOneWidget);
    expect(find.byKey(const Key('delete-account-error')), findsOneWidget);
  });
}

Widget _buildProfile({
  required _FakePulseRepository repository,
  required PulseProfile profile,
  required bool isCurrentUser,
  Future<void> Function()? deleteAccount,
  Future<void> Function()? onAccountDeleted,
}) {
  return ProviderScope(
    overrides: <Override>[
      pulseRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: ProfilePage(
          initialProfile: profile,
          loadProfile: () async => profile,
          isCurrentUser: isCurrentUser,
          showAppBar: false,
          deleteAccount: deleteAccount,
          onAccountDeleted: onAccountDeleted,
        ),
      ),
    ),
  );
}

class _FakePulseRepository extends PulseRepository {
  _FakePulseRepository({required this.profile}) : super(dio: Dio());

  final PulseProfile profile;

  Future<void>? followFuture;
  Future<void>? unfollowFuture;

  String? followedUsername;
  String? unfollowedUsername;

  @override
  Future<PulseProfile?> getMyProfile() async => profile;

  @override
  Future<PulseProfile?> getProfile(String username) async => profile;

  @override
  Future<List<PulsePost>> getProfilePosts(String username) async {
    return const <PulsePost>[];
  }

  @override
  Future<void> followUser(String username) {
    followedUsername = username;
    return followFuture ?? Future<void>.value();
  }

  @override
  Future<void> unfollowUser(String username) {
    unfollowedUsername = username;
    return unfollowFuture ?? Future<void>.value();
  }
}
