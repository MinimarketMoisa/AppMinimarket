import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/helpers.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _email;
  bool _sending = false;
  bool _requestSent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _requestReset() async {
    if (!_form.currentState!.validate()) return;
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
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: colors.primaryContainer,
                          child: Icon(
                            _requestSent
                                ? Icons.mark_email_read_outlined
                                : Icons.lock_reset,
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
                              ? 'Si el correo existe, te enviamos un enlace '
                                    'para restablecer tu contraseña. Ábrelo desde '
                                    'tu correo para continuar en el navegador.'
                              : 'Escribe el correo asociado a tu cuenta y te '
                                    'enviaremos un enlace para restablecer la '
                                    'contraseña.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 22),
                        TextFormField(
                          controller: _email,
                          enabled: !_requestSent && !_sending,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) =>
                              value != null &&
                                  RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                      .hasMatch(value.trim())
                              ? null
                              : 'Ingresa un correo válido',
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colors.error),
                          ),
                        ],
                        if (!_requestSent) ...[
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: _sending ? null : _requestReset,
                            icon: _sending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.outgoing_mail),
                            label: Text(
                              _sending ? 'Enviando…' : 'Enviar instrucciones',
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Volver a iniciar sesión'),
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
      ),
    );
  }
}
