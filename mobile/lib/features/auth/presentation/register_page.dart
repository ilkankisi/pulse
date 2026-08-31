import 'package:flutter/material.dart';

import '../domain/auth_models.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    required this.initialEmail,
    required this.onRegister,
    super.key,
  });

  final String initialEmail;
  final Future<bool> Function(RegisterRequest request) onRegister;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();

  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final authenticated = await widget.onRegister(
      RegisterRequest(
        username: _usernameController.text.trim(),
        displayName: _displayNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );

    if (!mounted) {
      return;
    }

    if (authenticated) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    Navigator.of(context).pop(_emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Ol')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text('Pulse’a katıl', style: theme.textTheme.headlineLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Davet kodu veya yönetici onayı gerekmez.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _usernameController,
                      enabled: !_isSubmitting,
                      decoration: const InputDecoration(
                        labelText: 'Kullanıcı adı',
                        prefixText: '@',
                      ),
                      validator: (value) {
                        final username = value?.trim() ?? '';

                        if (username.isEmpty) {
                          return 'Kullanıcı adı girin.';
                        }

                        if (username.length < 3 || username.length > 30) {
                          return 'Kullanıcı adı 3-30 karakter olmalıdır.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _displayNameController,
                      enabled: !_isSubmitting,
                      decoration: const InputDecoration(labelText: 'Ad'),
                      validator: (value) {
                        final displayName = value?.trim() ?? '';

                        if (displayName.isEmpty) {
                          return 'Görünen adınızı girin.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      enabled: !_isSubmitting,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'E-posta'),
                      validator: (value) {
                        final email = value?.trim() ?? '';

                        if (email.isEmpty || !email.contains('@')) {
                          return 'Geçerli bir e-posta adresi girin.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      enabled: !_isSubmitting,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Şifre',
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Şifreyi göster'
                              : 'Şifreyi gizle',
                          onPressed: () {
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
                      validator: (value) {
                        if ((value ?? '').length < 8) {
                          return 'Şifre en az 8 karakter olmalıdır.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmationController,
                      enabled: !_isSubmitting,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Şifre tekrarı',
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Şifreler eşleşmiyor.';
                        }

                        return null;
                      },
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (_errorMessage != null) ...<Widget>[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
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
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
