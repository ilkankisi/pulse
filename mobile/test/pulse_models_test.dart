import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/pulse/domain/pulse_models.dart';

void main() {
  test('backend gönderi JSON sözleşmesi doğru parse edilir', () {
    final post = PulsePost.fromJson(<String, dynamic>{
      'id': 42,
      'content': 'Pulse gönderisi',
      'createdAt': '2026-08-05T12:00:00Z',
      'author': <String, dynamic>{
        'id': 7,
        'username': 'ilkan',
        'displayName': 'İlkan',
        'avatarUrl': null,
      },
      'likeCount': 3,
      'replyCount': 2,
      'isLiked': true,
      'canDelete': true,
      'replyToPostId': null,
    });

    expect(post.id, 42);
    expect(post.content, 'Pulse gönderisi');
    expect(post.author.username, 'ilkan');
    expect(post.likeCount, 3);
    expect(post.replyCount, 2);
    expect(post.isLiked, isTrue);
    expect(post.canDelete, isTrue);
    expect(post.replyToPostId, isNull);
    expect(post.createdAt, DateTime.parse('2026-08-05T12:00:00Z'));
  });

  test('yalnızca backend canDelete true gönderisi silinebilir olur', () {
    final ownedPost = PulsePost.fromJson(_postJson(id: 1, canDelete: true));
    final foreignPost = PulsePost.fromJson(_postJson(id: 2, canDelete: false));

    expect(ownedPost.canDelete, isTrue);
    expect(foreignPost.canDelete, isFalse);
  });

  test('feed liste ve items sarmalayıcı yanıtlarını parse eder', () {
    final directFeed = PulseFeed.fromJson(<Map<String, dynamic>>[
      _postJson(id: 1, canDelete: true),
    ]);
    final wrappedFeed = PulseFeed.fromJson(<String, dynamic>{
      'items': <Map<String, dynamic>>[_postJson(id: 2, canDelete: false)],
    });

    expect(directFeed.posts.single.id, 1);
    expect(wrappedFeed.posts.single.id, 2);
  });

  test('gönderi oluşturma gövdesi trimlenmiş content gönderir', () {
    final request = CreatePostRequest(content: '  Merhaba Pulse  ');

    expect(request.toJson(), <String, dynamic>{'content': 'Merhaba Pulse'});
  });

  test('yanıt oluşturma gövdesi yalnızca content gönderir', () {
    final request = CreateReplyRequest(content: '  Tek seviyeli yanıt  ');

    expect(request.toJson(), <String, dynamic>{
      'content': 'Tek seviyeli yanıt',
    });
  });

  test('profil güncelleme gövdesi boş avatar alanını göndermez', () {
    final request = UpdateProfileRequest(
      displayName: ' İlkan ',
      bio: ' Flutter geliştirici ',
      avatarUrl: ' ',
    );

    expect(request.toJson(), <String, dynamic>{
      'displayName': 'İlkan',
      'bio': 'Flutter geliştirici',
    });
  });

  test('profil güncelleme gövdesi dolu avatar URL alanını gönderir', () {
    final request = UpdateProfileRequest(
      displayName: ' İlkan ',
      bio: ' Flutter geliştirici ',
      avatarUrl: ' https://example.com/avatar.png ',
    );

    expect(request.toJson(), <String, dynamic>{
      'displayName': 'İlkan',
      'bio': 'Flutter geliştirici',
      'avatarUrl': 'https://example.com/avatar.png',
    });
  });
}

Map<String, dynamic> _postJson({required int id, required bool canDelete}) {
  return <String, dynamic>{
    'id': id,
    'content': 'Test gönderisi',
    'createdAt': '2026-08-05T10:00:00Z',
    'author': <String, dynamic>{
      'id': 7,
      'username': 'ilkan',
      'displayName': 'İlkan',
      'avatarUrl': null,
    },
    'likeCount': 0,
    'replyCount': 0,
    'isLiked': false,
    'canDelete': canDelete,
    'replyToPostId': null,
  };
}
