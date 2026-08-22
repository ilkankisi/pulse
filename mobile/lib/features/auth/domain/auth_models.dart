class LoginRequest {
  const LoginRequest({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'email': email.trim(), 'password': password};
  }
}

class RegisterRequest {
  const RegisterRequest({
    required this.username,
    required this.displayName,
    required this.email,
    required this.password,
  });

  final String username;
  final String displayName;
  final String email;
  final String password;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'username': username.trim(),
      'displayName': displayName.trim(),
      'email': email.trim(),
      'password': password,
    };
  }
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.email,
    this.bio,
    this.avatarUrl,
  });

  final int id;
  final String username;
  final String displayName;
  final String email;
  final String? bio;
  final String? avatarUrl;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: _readRequiredInt(json, const <String>['id', 'userId']),
      username: _readRequiredString(json, const <String>[
        'username',
        'userName',
      ]),
      displayName: _readRequiredString(json, const <String>[
        'displayName',
        'name',
      ]),
      email: _readOptionalString(json['email']) ?? '',
      bio: _readOptionalString(json['bio']),
      avatarUrl: _readOptionalString(json['avatarUrl']),
    );
  }
}

class AuthSession {
  const AuthSession({required this.accessToken, this.user});

  final String accessToken;
  final AuthUser? user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    final user = rawUser is Map
        ? AuthUser.fromJson(Map<String, dynamic>.from(rawUser))
        : null;

    return AuthSession(
      accessToken: _readRequiredString(json, const <String>[
        'accessToken',
        'token',
        'jwt',
      ]),
      user: user,
    );
  }
}

class RegisterResult {
  const RegisterResult._({required this.email, this.session});

  final String email;
  final AuthSession? session;

  bool get isAuthenticated => session != null;

  factory RegisterResult.authenticated({
    required String email,
    required AuthSession session,
  }) {
    return RegisterResult._(email: email, session: session);
  }

  factory RegisterResult.requiresLogin({required String email}) {
    return RegisterResult._(email: email);
  }
}

String _readRequiredString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }

  throw FormatException('Zorunlu metin alanı bulunamadı: ${keys.join(', ')}');
}

int _readRequiredInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      final parsedValue = int.tryParse(value);
      if (parsedValue != null) {
        return parsedValue;
      }
    }
  }

  throw FormatException('Zorunlu sayısal alan bulunamadı: ${keys.join(', ')}');
}

String? _readOptionalString(dynamic value) {
  if (value is! String) {
    return null;
  }

  final trimmedValue = value.trim();
  return trimmedValue.isEmpty ? null : trimmedValue;
}
