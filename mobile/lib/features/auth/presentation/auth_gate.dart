import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_api.dart';
import '../domain/auth_models.dart';
import '../../pulse/presentation/app_shell.dart';
import 'login_page.dart';

enum _GateStatus { checking, unauthenticated, authenticated }

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  _GateStatus _status = _GateStatus.checking;
  AuthUser? _user;
  String _prefilledEmail = '';
  String? _errorMessage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_checkSession);
  }

  Future<void> _checkSession() async {
    final api = ref.read(authApiProvider);

    try {
      final token = await api.readToken();

      if (token == null || token.trim().isEmpty) {
        if (mounted) {
          setState(() => _status = _GateStatus.unauthenticated);
        }
        return;
      }

      final user = await api.getCurrentUser();

      if (mounted) {
        setState(() {
          _user = user;
          _status = _GateStatus.authenticated;
        });
      }
    } on DioException {
      await api.logout();

      if (mounted) {
        setState(() {
          _user = null;
          _status = _GateStatus.unauthenticated;
        });
      }
    } on FormatException {
      await api.logout();

      if (mounted) {
        setState(() {
          _user = null;
          _status = _GateStatus.unauthenticated;
        });
      }
    } catch (_) {
      await api.logout();

      if (mounted) {
        setState(() {
          _user = null;
          _status = _GateStatus.unauthenticated;
        });
      }
    }
  }

  Future<void> _login(String email, String password) async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(authApiProvider);
      final session = await api.login(
        LoginRequest(email: email, password: password),
      );
      final user = session.user ?? await api.getCurrentUser();

      if (!mounted) {
        return;
      }

      setState(() {
        _user = user;
        _status = _GateStatus.authenticated;
        _isSubmitting = false;
      });
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _errorMessage = _readError(error, 'Oturum açılamadı.');
      });
    } on FormatException {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Sunucu yanıtı okunamadı.';
      });
    }
  }

  Future<bool> _register(RegisterRequest request) async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(authApiProvider);
      final result = await api.register(request);

      if (result.isAuthenticated && result.session != null) {
        final user = result.session!.user ?? await api.getCurrentUser();

        if (!mounted) {
          return false;
        }

        setState(() {
          _user = user;
          _status = _GateStatus.authenticated;
          _isSubmitting = false;
        });

        return true;
      }

      if (!mounted) {
        return false;
      }

      setState(() {
        _prefilledEmail = result.email;
        _isSubmitting = false;
      });

      return false;
    } on DioException catch (error) {
      if (!mounted) {
        return false;
      }

      setState(() {
        _isSubmitting = false;
        _errorMessage = _readError(error, 'Kayıt oluşturulamadı.');
      });

      return false;
    } on FormatException {
      if (!mounted) {
        return false;
      }

      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Sunucu yanıtı okunamadı.';
      });

      return false;
    }
  }

  Future<void> _logout() async {
    await ref.read(authApiProvider).logout();

    if (!mounted) {
      return;
    }

    setState(() {
      _user = null;
      _errorMessage = null;
      _status = _GateStatus.unauthenticated;
    });
  }

  Future<void> _handleUnauthorized() async {
    await _logout();
  }

  @override
  Widget build(BuildContext context) {
    switch (_status) {
      case _GateStatus.checking:
        return const Scaffold(
          body: SafeArea(child: Center(child: CircularProgressIndicator())),
        );
      case _GateStatus.unauthenticated:
        return LoginPage(
          initialEmail: _prefilledEmail,
          isSubmitting: _isSubmitting,
          errorMessage: _errorMessage,
          onLogin: _login,
          onRegister: _register,
        );
      case _GateStatus.authenticated:
        return AppShell(
          currentUser: _user!,
          onLogout: _logout,
          onUnauthorized: _handleUnauthorized,
        );
    }
  }

  static String _readError(DioException exception, String fallback) {
    final data = exception.response?.data;

    if (data is Map) {
      final json = Map<String, dynamic>.from(data);
      final message = json['error'] ?? json['message'];

      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }

    return fallback;
  }
}
