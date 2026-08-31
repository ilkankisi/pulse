import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/auth/domain/auth_models.dart';
import 'package:pulse/features/pulse/data/pulse_repository.dart';
import 'package:pulse/features/pulse/domain/pulse_models.dart';
import 'package:pulse/features/pulse/presentation/feed_page.dart';

void main() {
  const currentUser = AuthUser(
    id: 7,
    username: 'ilkan',
    displayName: 'İlkan',
    email: 'ilkan@example.com',
  );

  testWidgets('ana akış eski gönderileri aşağı kaydırdıkça kademeli gösterir', (
    tester,
  ) async {
    final repository = _FakePulseRepository(_buildPosts(45));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          pulseRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: FeedPage(
              currentUser: currentUser,
              onUnauthorized: () async {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.loadCount, 1);
    expect(_renderedChildCount(tester), 39);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -10000));
    await tester.pumpAndSettle();

    expect(_renderedChildCount(tester), 79);
    expect(repository.loadCount, 1);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -10000));
    await tester.pumpAndSettle();

    expect(_renderedChildCount(tester), 89);
    expect(repository.loadCount, 1);
  });
}

int _renderedChildCount(WidgetTester tester) {
  final sliverList = tester.widget<SliverList>(find.byType(SliverList));
  final delegate = sliverList.delegate as SliverChildBuilderDelegate;
  return delegate.childCount!;
}

List<PulsePost> _buildPosts(int count) {
  const author = PulseAuthor(id: 7, username: 'ilkan', displayName: 'İlkan');

  return List<PulsePost>.generate(count, (index) {
    final number = index + 1;

    return PulsePost(
      id: number,
      content: 'Gönderi $number',
      createdAt: DateTime.utc(
        2026,
        8,
        14,
        12,
      ).subtract(Duration(minutes: index)),
      author: author,
      likeCount: 0,
      replyCount: 0,
      isLiked: false,
      canDelete: true,
    );
  });
}

class _FakePulseRepository extends PulseRepository {
  _FakePulseRepository(this.posts) : super(dio: Dio());

  final List<PulsePost> posts;
  int loadCount = 0;

  @override
  Future<List<PulsePost>> getFeed() async {
    loadCount += 1;
    return posts;
  }
}
