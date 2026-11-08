import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/helpers.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  ConsumerState<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _email = TextEditingController();
  final _token = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _requestForm = GlobalKey<FormState>();
  final _resetForm = GlobalKey<FormState>();
  bool _sending = false;
  bool _resetting = false;
  bool _requestSent = false;
  bool _hidePassword = true;
  bool _hideConfirmation = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email.text = widget.initialEmail;
  }

  @override
  void dispose() {
    _email.dispose();
    _token.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _requestReset() async {
    if (!_requestForm.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref
          .read(authProvider.notifier)
          .requestPasswordReset(_email.text.trim());
      if (mounted) setState(() => _requestSent = true);
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _resetToken(String value) {
    final trimmed = value.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasQuery) {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) return token;
    }
    return trimmed;
  }

  Future<void> _resetPassword() async {
    if (!_resetForm.currentState!.validate()) return;
    setState(() {
      _resetting = true;
      _error = null;
    });
    try {
      await ref
          .read(authProvider.notifier)
          .resetPassword(
            token: _resetToken(_token.text),
            password: _password.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu contraseña se actualizó correctamente.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }

  Widget _errorCard() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: colors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_error!, style: TextStyle(color: colors.onErrorContainer)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                elevation: 0,
                color: colors.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: colors.primaryContainer,
                        child: Icon(
                          Icons.lock_reset,
                          size: 34,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _requestSent
                            ? 'Revisa tu correo'
                            : '¿Olvidaste tu contraseña?',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _requestSent
                            ? 'Si el correo está registrado, recibirás un enlace para cambiar tu contraseña. Copia el token del enlace para continuar aquí.'
                            : 'Escribe el correo asociado a tu cuenta y te enviaremos instrucciones para crear una nueva contraseña.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 22),
                      Form(
                        key: _requestForm,
                        child: TextFormField(
                          controller: _email,
                          enabled: !_requestSent && !_sending,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                    .hasMatch(email)
                                ? null
                                : 'Ingresa un correo válido';
                          },
                        ),
                      ),
                      if (_requestSent) ...[
                        const SizedBox(height: 12),
                        Form(
                          key: _resetForm,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _token,
                                enabled: !_resetting,
                                decoration: const InputDecoration(
                                  labelText: 'Token o enlace de recuperación',
                                  prefixIcon: Icon(Icons.key_outlined),
                                ),
                                validator: (value) =>
                                    (value?.trim().isEmpty ?? true)
                                    ? 'Pega el token o enlace recibido'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _password,
                                enabled: !_resetting,
                                obscureText: _hidePassword,
                                decoration: InputDecoration(
                                  labelText: 'Nueva contraseña',
                                  helperText: 'Usa al menos 8 caracteres',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(
                                      () => _hidePassword = !_hidePassword,
                                    ),
                                    icon: Icon(
                                      _hidePassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                  ),
                                ),
                                validator: (value) =>
                                    (value?.length ?? 0) < 8 ||
                                        (value?.length ?? 0) > 128
                                    ? 'La contraseña debe tener entre 8 y 128 caracteres'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _confirmPassword,
                                enabled: !_resetting,
                                obscureText: _hideConfirmation,
                                decoration: InputDecoration(
                                  labelText: 'Confirma la nueva contraseña',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(
                                      () => _hideConfirmation =
                                          !_hideConfirmation,
                                    ),
                                    icon: Icon(
                                      _hideConfirmation
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                  ),
                                ),
                                validator: (value) =>
                                    value != _password.text
                                    ? 'Las contraseñas no coinciden'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        _errorCard(),
                      ],
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _sending || _resetting
                            ? null
                            : _requestSent
                            ? _resetPassword
                            : _requestReset,
                        icon: _sending || _resetting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                _requestSent
                                    ? Icons.check_circle_outline
                                    : Icons.outgoing_mail,
                              ),
                        label: Text(
                          _sending
                              ? 'Enviando…'
                              : _resetting
                              ? 'Actualizando…'
                              : _requestSent
                              ? 'Actualizar contraseña'
                              : 'Enviar instrucciones',
                        ),
                      ),
                      if (_requestSent)
                        TextButton(
                          onPressed: _sending || _resetting
                              ? null
                              : () => setState(() {
                                  _requestSent = false;
                                  _error = null;
                                  _token.clear();
                                  _password.clear();
                                  _confirmPassword.clear();
                                }),
                          child: const Text('Usar otro correo'),
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
