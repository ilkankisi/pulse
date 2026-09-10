import 'package:flutter/material.dart';

import '../domain/auth_models.dart';

import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,

    required this.onLogin,

    this.onRegister,

    this.prefilledEmail = '',

    this.initialEmail,

    this.isSubmitting = false,

    this.errorMessage,
  });

  final Future<dynamic> Function(String username, String password) onLogin;

  final Future<bool> Function(RegisterRequest request)? onRegister;

  final String prefilledEmail;

  final String? initialEmail;

  final bool isSubmitting;

  final String? errorMessage;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _usernameController;

  late final TextEditingController _passwordController;

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();

    _usernameController = TextEditingController(
      text: widget.initialEmail ?? widget.prefilledEmail,
    );

    _passwordController = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant LoginPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldValue = oldWidget.initialEmail ?? oldWidget.prefilledEmail;
    final newValue = widget.initialEmail ?? widget.prefilledEmail;

    if (oldValue != newValue &&
        newValue.isNotEmpty &&
        _usernameController.text != newValue) {
      _usernameController.text = newValue;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();

    _passwordController.dispose();

    super.dispose();
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

  Future<void> _submit() async {
    if (widget.isSubmitting || !_formKey.currentState!.validate()) {
      return;
    }

    await widget.onLogin(
      _usernameController.text.trim(),
      _passwordController.text,
    );
  }

  Future<void> _openRegister() async {
    final onRegister = widget.onRegister;

    if (onRegister == null || widget.isSubmitting) {
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => RegisterPage(
          onRegister: onRegister,
          initialEmail: _usernameController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
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
                      Text(
                        'Oturum Aç',
                        style: theme.textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _usernameController,
                        enabled: !widget.isSubmitting,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
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
                        controller: _passwordController,
                        enabled: !widget.isSubmitting,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'Şifre',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: widget.isSubmitting
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
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      if (widget.errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          widget.errorMessage!,
                          style: TextStyle(color: theme.colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: widget.isSubmitting ? null : _submit,
                        child: widget.isSubmitting
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Oturum Aç'),
                      ),
                      if (widget.onRegister != null) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: widget.isSubmitting ? null : _openRegister,
                          child: const Text('Hesabın yok mu? Kayıt ol'),
                        ),
                      ],
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
