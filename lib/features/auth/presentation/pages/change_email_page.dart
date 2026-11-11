import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/helpers.dart';
import '../providers/auth_provider.dart';
import 'login_page.dart';

class ChangeEmailPage extends ConsumerStatefulWidget {
  const ChangeEmailPage({super.key});

  @override
  ConsumerState<ChangeEmailPage> createState() => _ChangeEmailPageState();
}

class _ChangeEmailPageState extends ConsumerState<ChangeEmailPage> {
  final _requestForm = GlobalKey<FormState>();
  final _confirmForm = GlobalKey<FormState>();
  final _newEmail = TextEditingController();
  final _password = TextEditingController();
  final _token = TextEditingController();
  bool _codeSent = false;
  bool _loading = false;
  bool _hidePassword = true;
  String? _error;
  String? _message;

  @override
  void dispose() {
    _newEmail.dispose();
    _password.dispose();
    _token.dispose();
    super.dispose();
  }

  String _changeEmailError(Object error) {
    if (error is DioException) {
      switch (error.response?.statusCode) {
        case 400:
          return 'El nuevo correo debe ser distinto al actual.';
        case 403:
          return 'La contraseña actual es incorrecta.';
        case 409:
          return 'Ese correo ya está asociado a otra cuenta.';
        case 429:
          return 'Espera un minuto antes de volver a solicitar otro código.';
      }
    }
    return errorMessage(error);
  }

  Future<void> _requestCode() async {
    if (!_requestForm.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });
    try {
      final message = await ref
          .read(authProvider.notifier)
          .requestEmailChange(
            newEmail: _newEmail.text.trim(),
            password: _password.text,
          );
      if (mounted) {
        setState(() {
          _codeSent = true;
          _message = message;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = _changeEmailError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmCode() async {
    if (!_confirmForm.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final message = await ref
          .read(authProvider.notifier)
          .confirmEmailChange(_token.text.trim());
      if (!mounted) return;
      await ref.read(authProvider.notifier).logout();
      if (!mounted) return;
      final navigator = Navigator.of(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      navigator.popUntil((route) => route.isFirst);
      await navigator.push(
        MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      );
    } catch (error) {
      if (mounted) setState(() => _error = _changeEmailError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cambiar correo')),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: _codeSent ? _buildConfirmation() : _buildRequest(),
          ),
        ),
      ),
    ),
  );

  Widget _buildRequest() => Form(
    key: _requestForm,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Te enviaremos un código al nuevo correo. Para proteger tu cuenta, '
          'confirma el cambio con el código recibido.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _newEmail,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Nuevo correo'),
          validator: (value) =>
              value != null &&
                  RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())
              ? null
              : 'Ingresa un correo válido',
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _password,
          obscureText: _hidePassword,
          decoration: InputDecoration(
            labelText: 'Contraseña actual',
            suffixIcon: IconButton(
              onPressed: () => setState(() => _hidePassword = !_hidePassword),
              icon: Icon(
                _hidePassword ? Icons.visibility : Icons.visibility_off,
              ),
            ),
          ),
          validator: (value) =>
              value == null || value.isEmpty ? 'Ingresa tu contraseña' : null,
        ),
        if (_error != null) _errorText(),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _loading ? null : _requestCode,
          child: _loading
              ? const CircularProgressIndicator()
              : const Text('Enviar código'),
        ),
      ],
    ),
  );

  Widget _buildConfirmation() => Form(
    key: _confirmForm,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _message ??
              'Pega el código que enviamos a ${_newEmail.text.trim()}. '
                  'El código es largo y vence en 15 minutos.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _token,
          minLines: 2,
          maxLines: 5,
          keyboardType: TextInputType.multiline,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration(
            labelText: 'Código de confirmación',
            alignLabelWithHint: true,
            prefixIcon: Icon(Icons.key_outlined),
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Pega el código recibido por correo'
              : null,
        ),
        if (_error != null) _errorText(),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _loading ? null : _confirmCode,
          child: _loading
              ? const CircularProgressIndicator()
              : const Text('Confirmar cambio'),
        ),
      ],
    ),
  );

  Widget _errorText() => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Text(
      _error!,
      textAlign: TextAlign.center,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    ),
  );
}
