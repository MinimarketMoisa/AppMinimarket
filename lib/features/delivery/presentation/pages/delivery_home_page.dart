import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/helpers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../orders/presentation/widgets/pedido_card.dart';
import '../providers/delivery_provider.dart';

class DeliveryHomePage extends ConsumerStatefulWidget {
  const DeliveryHomePage({super.key});
  @override
  ConsumerState<DeliveryHomePage> createState() => _DeliveryHomePageState();
}

class _DeliveryHomePageState extends ConsumerState<DeliveryHomePage> {
  String _estado = 'disponible';

  void _msg(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _cambiarEstado(String e) async {
    try {
      await ref.read(deliveryRepositoryProvider).cambiarEstado(e);
      setState(() => _estado = e);
    } catch (err) {
      _msg(errorMessage(err));
    }
  }

  Future<void> _enviarUbicacion() async {
    try {
      // TODO: reemplazar por GPS real con el paquete `geolocator`.
      await ref.read(deliveryRepositoryProvider).actualizarUbicacion(13.4833, -88.1833);
      _msg('Ubicación enviada');
    } catch (err) {
      _msg(errorMessage(err));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    final pedidos = ref.watch(pedidosAsignadosProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${user?.nombreCompleto.split(' ').first ?? ''}'),
        actions: [
          IconButton(
              tooltip: 'Cerrar sesión',
              icon: const Icon(Icons.logout),
              onPressed: () => ref.read(authProvider.notifier).logout()),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _estado,
                  decoration: const InputDecoration(labelText: 'Mi estado', isDense: true),
                  items: const [
                    DropdownMenuItem(value: 'disponible', child: Text('Disponible')),
                    DropdownMenuItem(value: 'en_ruta', child: Text('En ruta')),
                    DropdownMenuItem(value: 'descanso', child: Text('En descanso')),
                  ],
                  onChanged: (v) => v == null ? null : _cambiarEstado(v),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.tonalIcon(
                onPressed: _enviarUbicacion,
                icon: const Icon(Icons.my_location),
                label: const Text('Ubicación'),
              ),
            ]),
          ),
          Expanded(
            child: pedidos.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(errorMessage(e))),
              data: (list) => RefreshIndicator(
                onRefresh: () async => ref.invalidate(pedidosAsignadosProvider),
                child: list.isEmpty
                    ? ListView(children: const [
                        SizedBox(height: 160),
                        Center(child: Text('No tienes entregas pendientes')),
                      ])
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          for (final p in list)
                            PedidoCard(
                              pedido: p,
                              mostrarCliente: true,
                              actions: [
                                FilledButton.icon(
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text('Completar entrega'),
                                  onPressed: () async {
                                    try {
                                      await ref.read(deliveryRepositoryProvider).completar(p.id);
                                      ref.invalidate(pedidosAsignadosProvider);
                                      _msg('Entrega completada');
                                    } catch (err) {
                                      _msg(errorMessage(err));
                                    }
                                  },
                                ),
                              ],
                            ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}