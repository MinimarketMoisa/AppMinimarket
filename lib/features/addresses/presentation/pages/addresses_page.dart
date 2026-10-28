import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/utils/helpers.dart';
import '../providers/addresses_provider.dart';

class AddressesPage extends ConsumerWidget {
  const AddressesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dirs = ref.watch(direccionesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mis direcciones')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Agregar'),
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const _AddressForm(),
        ),
      ),
      body: dirs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(errorMessage(e))),
        data: (list) => list.isEmpty
            ? const Center(child: Text('Aún no tienes direcciones'))
            : ListView(
                padding: const EdgeInsets.only(bottom: 90),
                children: [
                  for (final d in list)
                    ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: Text(d.detalleDireccion),
                      subtitle: Text(
                        '${d.municipioNombre ?? ''}${d.puntoReferencia != null ? ' · ${d.puntoReferencia}' : ''}',
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _AddressForm extends ConsumerStatefulWidget {
  const _AddressForm();
  @override
  ConsumerState<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends ConsumerState<_AddressForm> {
  final _form = GlobalKey<FormState>();
  final _detalle = TextEditingController();
  final _ref = TextEditingController();
  final _latitud = TextEditingController();
  final _longitud = TextEditingController();
  int? _municipio;
  bool _saving = false;

  @override
  void dispose() {
    _detalle.dispose();
    _ref.dispose();
    _latitud.dispose();
    _longitud.dispose();
    super.dispose();
  }

  Future<void> _usarUbicacion() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Activa los servicios de ubicación del dispositivo');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(
          'Permite el acceso a la ubicación para guardar las coordenadas',
        );
      }
      final position = await Geolocator.getCurrentPosition();
      _latitud.text = position.latitude.toString();
      _longitud.text = position.longitude.toString();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage(error))));
      }
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final latitudeText = _latitud.text.trim();
    final longitudeText = _longitud.text.trim();
    if (latitudeText.isEmpty != longitudeText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa ambas coordenadas')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(addressesRepositoryProvider)
          .crear(
            detalle: _detalle.text.trim(),
            referencia: _ref.text.trim().isEmpty ? null : _ref.text.trim(),
            municipioId: _municipio!,
            latitud: latitudeText.isEmpty ? null : double.parse(latitudeText),
            longitud: longitudeText.isEmpty ? null : double.parse(longitudeText),
          );
      ref.invalidate(direccionesProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final municipios = ref.watch(municipiosProvider);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Text(
              'Nueva dirección',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            municipios.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(errorMessage(e)),
              data: (list) => DropdownButtonFormField<int>(
                initialValue: _municipio,
                decoration: const InputDecoration(labelText: 'Municipio'),
                items: [
                  for (final m in list)
                    DropdownMenuItem(value: m.id, child: Text(m.nombre)),
                ],
                onChanged: (v) => setState(() => _municipio = v),
                validator: (v) => v == null ? 'Selecciona un municipio' : null,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _detalle,
              decoration: const InputDecoration(labelText: 'Dirección'),
              validator: (v) => (v == null || v.trim().length < 5)
                  ? 'Ingresa la dirección'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ref,
              decoration: const InputDecoration(
                labelText: 'Punto de referencia (opcional)',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _usarUbicacion,
              icon: const Icon(Icons.my_location),
              label: const Text('Usar ubicación actual'),
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latitud,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Latitud'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final coordinate = double.tryParse(value.trim());
                      return coordinate == null ||
                              coordinate < -90 ||
                              coordinate > 90
                          ? 'Latitud inválida'
                          : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _longitud,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Longitud'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final coordinate = double.tryParse(value.trim());
                      return coordinate == null ||
                              coordinate < -180 ||
                              coordinate > 180
                          ? 'Longitud inválida'
                          : null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar'),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
