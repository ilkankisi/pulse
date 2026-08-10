import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:pulse/features/pulse/data/pulse_repository.dart';
import 'package:pulse/features/pulse/domain/pulse_models.dart';

void main() {
  const profilePath = '/api/v1/me';

  test('GET /api/v1/me 404 mevcut profil için null döner', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:5000'));
    final adapter = DioAdapter(dio: dio);
    final repository = PulseRepository(dio: dio);

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

    dio.close(force: true);
  });

  test('PUT /api/v1/me canonical update body kullanır', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:5000'));
    final adapter = DioAdapter(dio: dio);
    final repository = PulseRepository(dio: dio);

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

    dio.close(force: true);
  });
}
