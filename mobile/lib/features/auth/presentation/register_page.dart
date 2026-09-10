import 'package:flutter/material.dart';

import '../domain/auth_models.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,

    required this.onRegister,

    this.initialEmail = '',
  });

  final Future<bool> Function(RegisterRequest request) onRegister;

  final String initialEmail;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _displayNameController;

  late final TextEditingController _usernameController;

  late final TextEditingController _loginUsernameController;

  late final TextEditingController _passwordController;

  late final TextEditingController _passwordConfirmController;

  bool _isSubmitting = false;

  bool _obscurePassword = true;

  bool _obscurePasswordConfirm = true;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _displayNameController = TextEditingController();

    _usernameController = TextEditingController();

    _loginUsernameController = TextEditingController(text: widget.initialEmail);

    _passwordController = TextEditingController();

    _passwordConfirmController = TextEditingController();
  }

  @override
  void dispose() {
    _displayNameController.dispose();

    _usernameController.dispose();

    _loginUsernameController.dispose();

    _passwordController.dispose();

    _passwordConfirmController.dispose();

    super.dispose();
  }

  String? _validateDisplayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Görünen ad zorunludur.';
    }

    return null;
  }

  String? _validateUsername(String? value) {
    final username = value?.trim() ?? '';

    if (username.isEmpty) {
      return 'Kullanıcı adı zorunludur.';
    }

    if (username.length < 3) {
      return 'Kullanıcı adı en az 3 karakter olmalıdır.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre zorunludur.';
    }

    return null;
  }

  String? _validatePasswordConfirm(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre tekrarı zorunludur.';
    }

    if (value != _passwordController.text) {
      return 'Şifreler eşleşmiyor.';
    }

    return null;
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.onRegister(
        RegisterRequest(
          username: _usernameController.text.trim(),
          email: _loginUsernameController.text.trim(),
          password: _passwordController.text,
          displayName: _displayNameController.text.trim(),
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
      });

      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Kayıt oluşturulamadı.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Pulse’a katıl')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _displayNameController,
                        enabled: !_isSubmitting,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Görünen ad',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: _validateDisplayName,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _usernameController,
                        enabled: !_isSubmitting,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newUsername],
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Kullanıcı adı',
                          hintText: 'Kullanıcı adınızı girin',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: _validateUsername,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _loginUsernameController,
                        enabled: !_isSubmitting,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Giriş kullanıcı adı',
                          hintText: 'Girişte kullanılacak adı girin',
                          prefixIcon: Icon(Icons.account_circle_outlined),
                        ),
                        validator: _validateUsername,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        enabled: !_isSubmitting,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: InputDecoration(
                          labelText: 'Şifre',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: _isSubmitting
                                ? null
                                : () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordConfirmController,
                        enabled: !_isSubmitting,
                        obscureText: _obscurePasswordConfirm,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: InputDecoration(
                          labelText: 'Şifre tekrarı',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: _isSubmitting
                                ? null
                                : () {
                                    setState(() {
                                      _obscurePasswordConfirm =
                                          !_obscurePasswordConfirm;
                                    });
                                  },
                            icon: Icon(
                              _obscurePasswordConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: _validatePasswordConfirm,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: TextStyle(color: theme.colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Kayıt Ol'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
