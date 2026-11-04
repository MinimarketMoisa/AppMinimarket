import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/helpers.dart';
import '../providers/auth_provider.dart';

class DriverApplicationPage extends ConsumerStatefulWidget {
  const DriverApplicationPage({super.key});

  @override
  ConsumerState<DriverApplicationPage> createState() =>
      _DriverApplicationPageState();
}

class _DriverApplicationPageState extends ConsumerState<DriverApplicationPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _vehiclePlate = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirmation = TextEditingController();
  bool _loading = false;
  bool _submitted = false;
  bool _hidePassword = true;
  String? _error;

  String _applicationError(Object error) {
    if (error is DioException) {
      if (error.response?.statusCode == 404) {
        return 'El registro de repartidores aún no está habilitado en el '
            'servidor. Inténtalo de nuevo cuando la empresa actualice la API.';
      }
      final detail = error.response?.data;
      if (detail is Map && detail['detail'] is String) {
        return detail['detail'] as String;
      }
    }
    return errorMessage(error);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _vehiclePlate.dispose();
    _password.dispose();
    _passwordConfirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authProvider.notifier)
          .applyAsCourier(
            nombreCompleto: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            telefono: _phone.text.trim(),
            placaVehiculo: _vehiclePlate.text.trim().isEmpty
                ? null
                : _vehiclePlate.text.trim(),
          );
      if (mounted) {
        _password.clear();
        _passwordConfirmation.clear();
        setState(() => _submitted = true);
      }
    } catch (error) {
      if (mounted) setState(() => _error = _applicationError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Scaffold(
        appBar: AppBar(title: const Text('Solicitud de repartidor')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.mark_email_read_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Solicitud enviada',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'La empresa revisará tus datos antes de habilitar la cuenta. '
                  'El acceso de repartidor no estará disponible hasta que un '
                  'administrador apruebe la solicitud.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Entendido'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Solicitar acceso como repartidor')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Completa tus datos. La cuenta solo se habilitará '
                      'después de la revisión de la empresa.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      maxLength: 150,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                      ),
                      validator: (value) =>
                          value == null || value.trim().length < 3
                          ? 'Ingresa tu nombre completo'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                      ),
                      validator: (value) =>
                          value == null ||
                              !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                  .hasMatch(value.trim())
                          ? 'Ingresa un correo válido'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      maxLength: 20,
                      decoration: const InputDecoration(labelText: 'Teléfono'),
                      validator: (value) =>
                          value == null || value.trim().length < 7
                          ? 'Ingresa un teléfono válido'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _vehiclePlate,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 20,
                      decoration: const InputDecoration(
                        labelText: 'Placa del vehículo (opcional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: _hidePassword,
                      maxLength: 128,
                      decoration: InputDecoration(
                        labelText: 'Contraseña para tu cuenta',
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setState(() => _hidePassword = !_hidePassword),
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                      validator: (value) => value == null || value.length < 8
                          ? 'Usa al menos 8 caracteres'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordConfirmation,
                      obscureText: _hidePassword,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar contraseña',
                      ),
                      validator: (value) => value != _password.text
                          ? 'Las contraseñas no coinciden'
                          : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _loading ? null : _submit,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_outlined),
                      label: const Text('Enviar solicitud'),
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
