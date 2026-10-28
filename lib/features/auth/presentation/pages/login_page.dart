import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/utils/helpers.dart';
import '../providers/auth_provider.dart';
import 'email_verification_page.dart';
import 'register_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false, _hide = true;
  bool _needsVerification = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _needsVerification = false;
    });
    try {
      await ref
          .read(authProvider.notifier)
          .login(_email.text.trim(), _pass.text);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = errorMessage(e);
          _needsVerification = e is DioException &&
              (e.response?.statusCode == 403 ||
                  (e.response?.data is Map &&
                      '${(e.response!.data as Map)['detail'] ?? ''}'
                          .toLowerCase()
                          .contains('verific')));
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/images/minimarket_logo.png',
                        width: 280,
                        height: 76,
                        fit: BoxFit.contain,
                        semanticLabel: 'MiniMarket, ahorra tiempo y dinero',
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'Ingresa un correo válido'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _pass,
                      obscureText: _hide,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _hide ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () => setState(() => _hide = !_hide),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 4)
                          ? 'Mínimo 4 caracteres'
                          : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(color: cs.error),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Iniciar sesión'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      ),
                      child: const Text('¿No tienes cuenta? Regístrate'),
                    ),
                    if (_needsVerification)
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EmailVerificationPage(
                              initialEmail: _email.text.trim(),
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.mark_email_unread_outlined),
                        label: const Text('Verificar o reenviar correo'),
                      ),
                    if (!_needsVerification)
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EmailVerificationPage(
                              initialEmail: _email.text.trim(),
                            ),
                          ),
                        ),
                        child: const Text('¿No recibiste el correo?'),
                      ),
                    if (AppConfig.useMock) ...[const Divider(height: 32)],
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
