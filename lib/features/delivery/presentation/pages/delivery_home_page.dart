import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/network/session_expiry.dart';
import '../../../../core/utils/helpers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../orders/presentation/widgets/pedido_card.dart';
import '../providers/delivery_provider.dart';

class DeliveryHomePage extends ConsumerStatefulWidget {
  const DeliveryHomePage({super.key});
  @override
  ConsumerState<DeliveryHomePage> createState() => _DeliveryHomePageState();
}

class _DeliveryHomePageState extends ConsumerState<DeliveryHomePage>
    with WidgetsBindingObserver {
  String _estado = 'LIBRE';
  Timer? _locationTimer;
  bool _sendingLocation = false;
  bool _sharingLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _stopLocationSharing();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationTimer?.cancel();
    super.dispose();
  }

  void _msg(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _cambiarEstado(String estadoUi) async {
    try {
      final estadoApi = estadoUi == 'disponible' ? 'LIBRE' : 'PENDIENTE';
      await ref.read(deliveryRepositoryProvider).cambiarEstado(estadoApi);
      if (mounted) setState(() => _estado = estadoApi);
    } catch (error) {
      _msg(errorMessage(error));
    }
  }

  Future<void> _toggleLocationSharing() async {
    if (_sharingLocation) {
      _stopLocationSharing();
      return;
    }
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
          'Permite el acceso a la ubicación para compartir tu posición',
        );
      }
      if (!await _sendLocation()) return;
      if (!mounted) return;
      setState(() => _sharingLocation = true);
      _locationTimer = Timer.periodic(
        const Duration(seconds: 8),
        (_) => _sendLocation(),
      );
    } catch (error) {
      _msg(errorMessage(error));
    }
  }

  Future<bool> _sendLocation() async {
    if (_sendingLocation) return false;
    _sendingLocation = true;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Los servicios de ubicación están desactivados');
      }
      final position = await Geolocator.getCurrentPosition();
      await ref
          .read(deliveryRepositoryProvider)
          .actualizarUbicacion(position.latitude, position.longitude);
      return true;
    } catch (error) {
      _stopLocationSharing();
      _msg(errorMessage(error));
      return false;
    } finally {
      _sendingLocation = false;
    }
  }

  void _stopLocationSharing() {
    _locationTimer?.cancel();
    _locationTimer = null;
    if (_sharingLocation && mounted) {
      setState(() => _sharingLocation = false);
    } else {
      _sharingLocation = false;
    }
  }

  Future<String?> _askRejectionReason() => showDialog<String>(
    context: context,
    builder: (context) {
      var reason = '';
      return StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Rechazar pedido'),
          content: TextField(
            autofocus: true,
            maxLength: 200,
            onChanged: (value) => setDialogState(() => reason = value),
            decoration: const InputDecoration(labelText: 'Motivo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: reason.trim().length < 3
                  ? null
                  : () => Navigator.pop(context, reason.trim()),
              child: const Text('Rechazar'),
            ),
          ],
        ),
      );
    },
  );

  Future<void> _accept(int pedidoId) async {
    try {
      await ref.read(deliveryRepositoryProvider).aceptar(pedidoId);
      ref.invalidate(pedidoEntranteProvider);
      ref.invalidate(pedidosAsignadosProvider);
      _msg('Pedido aceptado');
    } catch (error) {
      _msg(errorMessage(error));
    }
  }

  Future<void> _reject(int pedidoId) async {
    final reason = await _askRejectionReason();
    if (reason == null) return;
    try {
      await ref.read(deliveryRepositoryProvider).rechazar(pedidoId, reason);
      ref.invalidate(pedidoEntranteProvider);
      _msg('Pedido rechazado');
    } catch (error) {
      _msg(errorMessage(error));
    }
  }

  Future<void> _changeOrderState(int id, String state) async {
    try {
      await ref.read(deliveryRepositoryProvider).cambiarEstadoPedido(id, state);
      ref.invalidate(pedidosAsignadosProvider);
      _msg(state == 'ENTREGADO' ? 'Entrega completada' : 'Ruta iniciada');
    } catch (error) {
      _msg(errorMessage(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sessionExpiryProvider, (previous, next) {
      if (previous != null && next > previous) {
        ref.invalidate(authProvider);
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
    final user = ref.watch(authProvider).value;
    final pedidos = ref.watch(pedidosAsignadosProvider);
    final entrante = ref.watch(pedidoEntranteProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${user?.nombreCompleto.split(' ').first ?? ''}'),
        actions: [
          IconButton(
            tooltip: 'Ir a comprar',
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () => Navigator.of(context)
                .pushNamedAndRemoveUntil('/client', (route) => route.isFirst),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _estado == 'LIBRE'
                        ? 'disponible'
                        : 'no_disponible',
                    decoration: const InputDecoration(
                      labelText: 'Mi estado',
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'disponible',
                        child: Text('Disponible'),
                      ),
                      DropdownMenuItem(
                        value: 'no_disponible',
                        child: Text('No disponible'),
                      ),
                    ],
                    onChanged: (value) =>
                        value == null ? null : _cambiarEstado(value),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _toggleLocationSharing,
                  icon: Icon(
                    _sharingLocation ? Icons.location_off : Icons.my_location,
                  ),
                  label: Text(_sharingLocation ? 'Pausar' : 'Compartir'),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(pedidosAsignadosProvider);
                ref.invalidate(pedidoEntranteProvider);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  entrante.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (error, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('Pedido entrante: ${errorMessage(error)}'),
                    ),
                    data: (pedido) => pedido == null
                        ? const SizedBox.shrink()
                        : PedidoCard(
                            pedido: pedido,
                            mostrarCliente: true,
                            actions: [
                              FilledButton.icon(
                                icon: const Icon(Icons.check),
                                label: const Text('Aceptar'),
                                onPressed: () => _accept(pedido.id),
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.close),
                                label: const Text('Rechazar'),
                                onPressed: () => _reject(pedido.id),
                              ),
                            ],
                          ),
                  ),
                  pedidos.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(errorMessage(error)),
                    ),
                    data: (list) => list.isEmpty && entrante.value == null
                        ? const Padding(
                            padding: EdgeInsets.only(top: 120),
                            child: Center(
                              child: Text('No tienes entregas pendientes'),
                            ),
                          )
                        : Column(
                            children: [
                              for (final pedido in list)
                                PedidoCard(
                                  pedido: pedido,
                                  mostrarCliente: true,
                                  actions: [
                                    if (pedido.estado == 'preparado')
                                      FilledButton.icon(
                                        icon: const Icon(Icons.delivery_dining),
                                        label: const Text('Iniciar entrega'),
                                        onPressed: () => _changeOrderState(
                                          pedido.id,
                                          'EN_RUTA',
                                        ),
                                      ),
                                    if (pedido.estado == 'en_ruta')
                                      FilledButton.icon(
                                        icon: const Icon(
                                          Icons.check_circle_outline,
                                        ),
                                        label: const Text('Completar entrega'),
                                        onPressed: () => _changeOrderState(
                                          pedido.id,
                                          'ENTREGADO',
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
