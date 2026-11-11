import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/helpers.dart';
import '../providers/auth_provider.dart';

class EmailVerificationPage extends ConsumerStatefulWidget {
  const EmailVerificationPage({
    super.key,
    this.initialEmail = '',
    this.registrationMessage,
  });

  final String initialEmail;
  final String? registrationMessage;

  @override
  ConsumerState<EmailVerificationPage> createState() =>
      _EmailVerificationPageState();
}

class _EmailVerificationPageState extends ConsumerState<EmailVerificationPage>
    with WidgetsBindingObserver {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _email;
  Timer? _cooldownTimer;
  int _resendCooldown = 0;
  bool _sending = false;
  bool _checking = false;
  String? _message;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail);
    _message = widget.registrationMessage;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cooldownTimer?.cancel();
    _email.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkVerification(showPendingMessage: false);
    }
  }

  void _startResendCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldown = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _resendCooldown <= 1) {
        timer.cancel();
        if (mounted) setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  Future<void> _checkVerification({bool showPendingMessage = true}) async {
    if (_checking || _form.currentState?.validate() != true) return;
    setState(() {
      _checking = true;
      _error = null;
      if (showPendingMessage) _message = null;
    });
    try {
      final verified = await ref
          .read(authProvider.notifier)
          .isEmailVerified(_email.text.trim());
      if (!mounted) return;
      if (!verified) {
        if (showPendingMessage) {
          setState(() {
            _message =
                'Aún no aparece la verificación. Abre el enlace '
                'del correo y vuelve a intentarlo.';
          });
        }
        return;
      }
      setState(
        () => _message = '¡Correo verificado! Ya puedes iniciar sesión.',
      );
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _resend() async {
    if (_sending || _resendCooldown > 0 || !_form.currentState!.validate()) {
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
      _message = null;
    });
    try {
      final message = await ref
          .read(authProvider.notifier)
          .resendVerification(_email.text.trim());
      if (mounted) {
        setState(() => _message = message);
        _startResendCooldown();
      }
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
                    'Revisa tu correo',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Abre el mensaje de MiniMarket y toca el enlace para '
                    'verificar tu cuenta. Después, vuelve a esta app.',
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
                            !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(value.trim())
                        ? 'Ingresa un correo válido'
                        : null,
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
                    Text(_message!, textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _checking || _sending
                        ? null
                        : _checkVerification,
                    child: _checking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Ya verifiqué mi correo'),
                  ),
                  OutlinedButton(
                    onPressed: _sending || _checking || _resendCooldown > 0
                        ? null
                        : _resend,
                    child: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _resendCooldown > 0
                                ? 'Reenviar correo ($_resendCooldown s)'
                                : 'Reenviar correo',
                          ),
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
