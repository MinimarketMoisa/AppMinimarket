import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/utils/helpers.dart';
import '../providers/auth_provider.dart';

class EmailVerificationPage extends ConsumerStatefulWidget {
  const EmailVerificationPage({
    super.key,
    this.initialEmail = '',
    this.initialToken,
    this.registrationMessage,
  });

  final String initialEmail;
  final String? initialToken;
  final String? registrationMessage;

  @override
  ConsumerState<EmailVerificationPage> createState() =>
      _EmailVerificationPageState();
}

class _EmailVerificationPageState extends ConsumerState<EmailVerificationPage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _email;
  late final TextEditingController _token;
  bool _sending = false;
  bool _verifying = false;
  String? _message;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail);
    _token = TextEditingController(text: widget.initialToken ?? '');
    _message = widget.registrationMessage;
    if (AppConfig.useMock && widget.registrationMessage != null) {
      _message = 'Registro de prueba: usa el token 123456 para verificar.';
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _token.dispose();
    super.dispose();
  }

  String _extractToken(String value) {
    final trimmed = value.trim();
    final uri = Uri.tryParse(trimmed);
    return uri != null && uri.hasQuery
        ? uri.queryParameters['token']?.trim() ?? trimmed
        : trimmed;
  }

  Future<void> _verify() async {
    if (!_form.currentState!.validate()) return;
    final token = _extractToken(_token.text);
    if (token.isEmpty) {
      setState(() => _error = 'Ingresa el token que recibiste por correo.');
      return;
    }
    setState(() {
      _verifying = true;
      _error = null;
      _message = null;
    });
    try {
      final message = await ref.read(authProvider.notifier).verifyEmail(token);
      if (!mounted) return;
      setState(() => _message = message);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _error = null;
      _message = null;
    });
    try {
      final message = await ref
          .read(authProvider.notifier)
          .resendVerification(_email.text.trim());
      if (mounted) setState(() => _message = message);
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Verificar correo')),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.mark_email_unread_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Confirma tu correo para activar la cuenta.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Revisa tu bandeja de entrada y la carpeta de spam. '
                    'Abre el enlace recibido o pega aquí el token de verificación.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) =>
                        value == null ||
                            !RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                                .hasMatch(value.trim())
                        ? 'Ingresa un correo válido'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _token,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Token o enlace del correo',
                      prefixIcon: Icon(Icons.key_outlined),
                    ),
                  ),
                  if (AppConfig.useMock)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Modo de prueba: token de verificación 123456.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  if (_message != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _message!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _verifying || _sending ? null : _verify,
                    child: _verifying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Verificar correo'),
                  ),
                  OutlinedButton(
                    onPressed: _sending || _verifying ? null : _resend,
                    child: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Reenviar correo de verificación'),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst),
                    child: const Text('Volver a iniciar sesión'),
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
