import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/pulse/presentation/profile_page.dart';
import 'package:pulse/features/pulse/presentation/social_graph_page.dart';

void main() {
  // Zorunlu social graph kabul kapsamı:
  // loading/açılış, empty, error/retry, profile navigation,
  // kendi takipçisini kaldırma.
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
}
