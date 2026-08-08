import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/app.dart';
import 'package:pulse/core/storage/token_store.dart';
import 'package:pulse/features/auth/data/auth_api.dart';
import 'package:pulse/features/auth/domain/auth_models.dart';
import 'package:pulse/features/auth/presentation/login_page.dart';
import 'package:pulse/features/auth/presentation/register_page.dart';
import 'package:pulse/features/pulse/data/pulse_repository.dart';
import 'package:pulse/features/pulse/domain/pulse_models.dart';

void main() {
  const user = AuthUser(
    id: 7,
    username: 'ilkan',
    displayName: 'İlkan',
    email: 'ilkan@example.com',
  );

  testWidgets('token yoksa Oturum Aç ekranı gösterilir', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        authApi: _FakeAuthApi(user: user),
        repository: _FakePulseRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Oturum Aç'), findsWidgets);
    expect(find.text('Hesabın yok mu? Kayıt ol'), findsOneWidget);
  });

  testWidgets('Oturum Aç ekranından Kayıt Ol ekranına geçilir', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        authApi: _FakeAuthApi(user: user),
        repository: _FakePulseRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hesabın yok mu? Kayıt ol'));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterPage), findsOneWidget);
    expect(find.text('Pulse’a katıl'), findsOneWidget);
  });

  testWidgets('JWT dönmeyen kayıt sonrası e-posta doldurulmuş girişe döner', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        authApi: _FakeAuthApi(user: user),
        repository: _FakePulseRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hesabın yok mu? Kayıt ol'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'ilkan');
    await tester.enterText(fields.at(1), 'İlkan');
    await tester.enterText(fields.at(2), 'ilkan@example.com');
    await tester.enterText(fields.at(3), 'password123');
    await tester.enterText(fields.at(4), 'password123');

    await tester.tap(find.widgetWithText(FilledButton, 'Kayıt Ol'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);

    final emailField = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    expect(emailField.controller?.text, 'ilkan@example.com');
  });

  testWidgets('başarılı giriş Feed açar ve çıkış Login ekranına döner', (
    tester,
  ) async {
    final authApi = _FakeAuthApi(user: user);

    await tester.pumpWidget(
      _buildApp(authApi: authApi, repository: _FakePulseRepository()),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'ilkan@example.com');
    await tester.enterText(fields.at(1), 'password123');
    await tester.tap(find.widgetWithText(FilledButton, 'Oturum Aç'));
    await tester.pumpAndSettle();

    expect(authApi.loginCalled, isTrue);
    expect(find.text('Ana Akış'), findsWidgets);
    expect(find.text('Akış henüz boş'), findsOneWidget);

    await tester.tap(find.byTooltip('Çıkış yap'));
    await tester.pumpAndSettle();

    expect(authApi.logoutCalled, isTrue);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Akış henüz boş'), findsNothing);
  });
}

Widget _buildApp({
  required AuthApi authApi,
  required PulseRepository repository,
}) {
  return ProviderScope(
    overrides: <Override>[
      authApiProvider.overrideWithValue(authApi),
      pulseRepositoryProvider.overrideWithValue(repository),
    ],
    child: const PulseApp(),
  );
}

class _FakeAuthApi extends AuthApi {
  _FakeAuthApi({required this.user})
    : super(dio: Dio(), tokenStore: const TokenStore());

  final AuthUser user;
  String? token;
  bool loginCalled = false;
  bool logoutCalled = false;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<AuthUser> getCurrentUser() async => user;

  @override
  Future<AuthSession> login(LoginRequest request) async {
    loginCalled = true;
    token = 'valid-token';

    return AuthSession(accessToken: token!, user: user);
  }

  @override
  Future<RegisterResult> register(RegisterRequest request) async {
    return RegisterResult.requiresLogin(email: request.email.trim());
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
    token = null;
  }
}

class _FakePulseRepository extends PulseRepository {
  _FakePulseRepository() : super(dio: Dio());

  @override
  Future<List<PulsePost>> getFeed() async {
    return const <PulsePost>[];
  }

  @override
  Future<PulseProfile?> getMyProfile() async {
    return const PulseProfile(
      id: 7,
      username: 'ilkan',
      displayName: 'İlkan',
      followerCount: 0,
      followingCount: 0,
      postCount: 0,
      isFollowing: false,
      isCurrentUser: true,
    );
  }

  @override
  Future<List<PulsePost>> getProfilePosts(String username) async {
    return const <PulsePost>[];
  }
}
