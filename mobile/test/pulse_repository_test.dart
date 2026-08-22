import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:pulse/features/pulse/data/pulse_repository.dart';
import 'package:pulse/features/pulse/domain/pulse_models.dart';

import 'package:pulse/core/network/api_routes.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late PulseRepository repository;
  late List<RequestOptions> requests;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:5000'));
    adapter = DioAdapter(dio: dio);
    repository = PulseRepository(dio: dio);
    requests = <RequestOptions>[];

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.next(options);
        },
      ),
    );
  });

  test('feed 404 yanıtını empty state olarak döndürür', () async {
    adapter.onGet(
      ApiRoutes.feed,
      (server) => server.reply(404, <String, dynamic>{'error': 'Not found'}),
    );

    final posts = await repository.getFeed();

    expect(posts, isEmpty);
  });

  test('profil 404 yanıtını null olarak döndürür', () async {
    adapter.onGet(
      ApiRoutes.me,
      (server) => server.reply(404, <String, dynamic>{'error': 'Not found'}),
    );

    final profile = await repository.getMyProfile();

    expect(profile, isNull);
  });

  test(
    'gönderi oluşturma POST path ve gövdesi sözleşmeyle uyumludur',
    () async {
      adapter.onPost(
        ApiRoutes.posts,
        (server) => server.reply(201, _postJson()),
        data: <String, dynamic>{'content': 'Merhaba Pulse'},
      );

      final post = await repository.createPost(
        const CreatePostRequest(content: '  Merhaba Pulse  '),
      );

      expect(post.id, 10);

      final request = requests.single;
      expect(request.method, 'POST');
      expect(request.path, ApiRoutes.posts);
      expect(request.data, <String, dynamic>{'content': 'Merhaba Pulse'});
    },
  );

  test('profil güncelleme PUT path ve gövdesi sözleşmeyle uyumludur', () async {
    adapter.onPut(
      ApiRoutes.me,
      (server) => server.reply(200, _profileJson()),
      data: <String, dynamic>{
        'displayName': 'İlkan',
        'bio': 'Flutter geliştirici',
        'avatarUrl': null,
      },
    );

    await repository.updateMyProfile(
      const UpdateProfileRequest(
        displayName: ' İlkan ',
        bio: ' Flutter geliştirici ',
        avatarUrl: '',
      ),
    );

    final request = requests.single;
    expect(request.method, 'PUT');
    expect(request.path, ApiRoutes.me);
    // api-contract.md golden request: avatarUrl zorunlu alandır, boşsa null.
    expect(request.data, <String, dynamic>{
      'displayName': 'İlkan',
      'bio': 'Flutter geliştirici',
      'avatarUrl': null,
    });
  });

  test('like ve unlike doğru HTTP senaryolarını kullanır', () async {
    adapter.onPost(
      ApiRoutes.postLikes(10),
      (server) => server.reply(204, null),
    );
    adapter.onDelete(
      ApiRoutes.postLikes(10),
      (server) => server.reply(204, null),
    );

    await repository.likePost(10);
    await repository.unlikePost(10);

    expect(requests[0].method, 'POST');
    expect(requests[0].path, ApiRoutes.postLikes(10));
    expect(requests[1].method, 'DELETE');
    expect(requests[1].path, ApiRoutes.postLikes(10));
  });

  test('tek seviyeli reply doğru endpoint ve gövdeyi kullanır', () async {
    adapter.onPost(
      ApiRoutes.postReplies(10),
      (server) => server.reply(201, _postJson(id: 11, replyToPostId: 10)),
      data: <String, dynamic>{'content': 'Yanıt'},
    );

    final reply = await repository.createReply(
      postId: 10,
      request: const CreateReplyRequest(content: ' Yanıt '),
    );

    expect(reply.replyToPostId, 10);
    expect(requests.single.method, 'POST');
    expect(requests.single.path, ApiRoutes.postReplies(10));
    expect(requests.single.data, <String, dynamic>{'content': 'Yanıt'});
  });

  test('follow ve unfollow doğru HTTP senaryolarını kullanır', () async {
    adapter.onPost(
      ApiRoutes.profileFollow('ada'),
      (server) => server.reply(204, null),
    );
    adapter.onDelete(
      ApiRoutes.profileFollow('ada'),
      (server) => server.reply(204, null),
    );

    await repository.followUser('ada');
    await repository.unfollowUser('ada');

    expect(requests[0].method, 'POST');
    expect(requests[0].path, ApiRoutes.profileFollow('ada'));
    expect(requests[1].method, 'DELETE');
    expect(requests[1].path, ApiRoutes.profileFollow('ada'));
  });
}

Map<String, dynamic> _postJson({int id = 10, int? replyToPostId}) {
  return <String, dynamic>{
    'id': id,
    'content': 'Merhaba Pulse',
    'createdAt': '2026-08-05T10:00:00Z',
    'author': <String, dynamic>{
      'id': 7,
      'username': 'ilkan',
      'displayName': 'İlkan',
    },
    'likeCount': 0,
    'replyCount': 0,
    'isLiked': false,
    'canDelete': true,
    'replyToPostId': replyToPostId,
  };
}

Map<String, dynamic> _profileJson() {
  return <String, dynamic>{
    'id': 7,
    'username': 'ilkan',
    'displayName': 'İlkan',
    'bio': 'Flutter geliştirici',
    'avatarUrl': null,
    'followerCount': 1,
    'followingCount': 2,
    'postCount': 3,
    'isFollowing': false,
    'isCurrentUser': true,
  };
}
