import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:pulse/core/network/api_routes.dart';
import 'package:pulse/features/pulse/data/pulse_repository.dart';
import 'package:pulse/features/pulse/domain/pulse_models.dart';

void main() {
  final profilePath = ApiRoutes.me;

  test('me 404 mevcut profil için null döner', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:5000'));
    final adapter = DioAdapter(dio: dio);
    final repository = PulseRepository(dio: dio);

    addTearDown(() => dio.close(force: true));

    RequestOptions? capturedRequest;

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedRequest = options;
          handler.next(options);
        },
      ),
    );

    adapter.onGet(profilePath, (server) {
      server.reply(404, <String, dynamic>{
        'error': 'Profile not found.',
        'field': null,
      });
    });

    final profile = await repository.getMyProfile();

    expect(profile, isNull);

    final request = capturedRequest;
    expect(request, isNotNull);
    expect(request!.method, 'GET');
    expect(request.uri.path, profilePath);
    expect(request.data, isNull);
  });

  test('create post canonical POST body kullanır', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:5000'));
    final adapter = DioAdapter(dio: dio);
    final repository = PulseRepository(dio: dio);

    addTearDown(() => dio.close(force: true));

    RequestOptions? capturedRequest;

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedRequest = options;
          handler.next(options);
        },
      ),
    );

    const requestBody = <String, dynamic>{'content': 'Yeni gönderi'};

    adapter.onPost(
      ApiRoutes.posts,
      (server) =>
          server.reply(400, <String, dynamic>{'error': 'Test response'}),
      data: requestBody,
    );

    await expectLater(
      repository.createPost(const CreatePostRequest(content: 'Yeni gönderi')),
      throwsA(isA<DioException>()),
    );

    final request = capturedRequest;
    expect(request, isNotNull);
    expect(request!.method, 'POST');
    expect(request.uri.path, ApiRoutes.posts);
    expect(Map<String, dynamic>.from(request.data as Map), requestBody);
  });

  test('me canonical update body kullanır', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:5000'));
    final adapter = DioAdapter(dio: dio);
    final repository = PulseRepository(dio: dio);

    addTearDown(() => dio.close(force: true));

    RequestOptions? capturedRequest;

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedRequest = options;
          handler.next(options);
        },
      ),
    );

    final expectedBody = <String, dynamic>{
      'displayName': 'İlkan Kişi',
      'bio': 'Yeni biyografi',
      'avatarUrl': null,
    };

    adapter.onPut(profilePath, (server) {
      server.reply(200, <String, dynamic>{
        'id': 1,
        'username': 'ilkan',
        'displayName': 'İlkan Kişi',
        'bio': 'Yeni biyografi',
        'avatarUrl': null,
        'postCount': 1,
        'followerCount': 2,
        'followingCount': 3,
        'isFollowing': false,
        'isCurrentUser': true,
      });
    }, data: expectedBody);

    final profile = await repository.updateMyProfile(
      const UpdateProfileRequest(
        displayName: 'İlkan Kişi',
        bio: 'Yeni biyografi',
        avatarUrl: '',
      ),
    );

    final request = capturedRequest;

    expect(request, isNotNull);
    expect(request!.method, 'PUT');
    expect(request.uri.path, profilePath);
    expect(request.data, isNotNull);
    expect(Map<String, dynamic>.from(request.data as Map), expectedBody);

    expect(profile.displayName, 'İlkan Kişi');
    expect(profile.bio, 'Yeni biyografi');
  });
}
