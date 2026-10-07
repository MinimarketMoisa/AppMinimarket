import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/helpers.dart';
import '../providers/orders_provider.dart';
import '../widgets/pedido_card.dart';

class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pedidos = ref.watch(misPedidosProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mis pedidos')),
      body: pedidos.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(errorMessage(e))),
        data: (list) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(misPedidosProvider),
          child: list.isEmpty
              ? ListView(children: const [
                  SizedBox(height: 200),
                  Center(child: Text('Todavía no has hecho pedidos')),
                ])
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (final p in list)
                      PedidoCard(
                        pedido: p,
                        actions: [
                          if (p.estado == 'pendiente')
                            OutlinedButton.icon(
                              icon: const Icon(Icons.cancel_outlined),
                              label: const Text('Cancelar pedido'),
                              onPressed: () async {
                                try {
                                  await ref.read(ordersRepositoryProvider).cancelar(p.id);
                                  ref.invalidate(misPedidosProvider);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(content: Text(errorMessage(e))));
                                  }
                                }
                              },
                            ),
                        ],
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}