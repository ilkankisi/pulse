class LoginRequest {
  LoginRequest({required String email, required String password})
    : email = email,

      password = password,

      toJson = LoginRequestJson(email, password);

  final String email;

  final String password;

  final LoginRequestJson toJson;
}

class LoginRequestJson {
  const LoginRequestJson(this.email, this.password);

  final String email;

  final String password;

  Map<String, dynamic> call() => <String, dynamic>{
    'username': email,

    'password': password,
  };
}

class RegisterRequest {
  const RegisterRequest({
    required this.username,

    required this.email,

    required this.password,

    required this.displayName,
  });

  final String username;

  final String email;

  final String password;

  final String displayName;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'username': username,

    'password': password,

    'displayName': displayName,
  };
}

class AuthUser {
  const AuthUser({
    required this.id,

    required this.username,

    required this.displayName,

    this.email,

    this.avatarUrl,
  });

  final int id;

  final String username;

  final String displayName;

  final String? email;

  final String? avatarUrl;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,

      username: json['username'] as String,

      displayName: json['displayName'] as String,

      email: json['email'] as String?,

      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

class AuthSession {
  const AuthSession({required this.accessToken, this.user});

  final String accessToken;

  final AuthUser? user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];

    return AuthSession(
      accessToken: json['accessToken'] as String,
      user: userJson is Map
          ? AuthUser.fromJson(Map<String, dynamic>.from(userJson))
          : null,
    );
  }
}

class RegisterResult {
  const RegisterResult._({required this.email, this.session});

  const RegisterResult.requiresLogin({required String email})
    : this._(email: email);

  const RegisterResult.authenticated({
    required String email,

    required AuthSession session,
  }) : this._(email: email, session: session);

  final String email;

  final AuthSession? session;

  bool get requiresLogin => session == null;

  bool get isAuthenticated => session != null;
}

class AuthResponse {
  const AuthResponse({
    required this.accessToken,

    required this.tokenType,

    required this.expiresIn,

    required this.user,
  });

  final String accessToken;

  final String tokenType;

  final int expiresIn;

  final AuthUser user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String,

      tokenType: json['tokenType'] as String,

      expiresIn: json['expiresIn'] as int,

      user: AuthUser.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
    );
  }
}
