import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/helpers.dart';
import '../providers/orders_provider.dart';
import '../widgets/pedido_card.dart';
import 'tracking_page.dart';

class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  Future<String?> _askReportReason(BuildContext context) => showDialog<String>(
    context: context,
    builder: (context) {
      var reason = '';
      return StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Denunciar repartidor'),
          content: TextField(
            autofocus: true,
            maxLength: 150,
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
              child: const Text('Enviar denuncia'),
            ),
          ],
        ),
      );
    },
  );

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
              ? ListView(
                  children: const [
                    SizedBox(height: 200),
                    Center(child: Text('Todavía no has hecho pedidos')),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (final p in list)
                      PedidoCard(
                        pedido: p,
                        actions: [
                          if (p.tipoEntrega == 'domicilio')
                            OutlinedButton.icon(
                              icon: const Icon(Icons.location_on_outlined),
                              label: const Text('Seguimiento'),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => TrackingPage(pedidoId: p.id),
                                ),
                              ),
                            ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.email_outlined),
                            label: const Text('Reenviar factura'),
                            onPressed: () async {
                              try {
                                await ref
                                    .read(ordersRepositoryProvider)
                                    .reenviarFactura(p.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Se solicitó el reenvío de la factura',
                                      ),
                                    ),
                                  );
                                }
                              } catch (error) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(errorMessage(error)),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          if (p.tipoEntrega == 'domicilio' &&
                              p.estado != 'entregado')
                            OutlinedButton.icon(
                              icon: const Icon(Icons.report_outlined),
                              label: const Text('Denunciar'),
                              onPressed: () async {
                                final reason = await _askReportReason(context);
                                if (reason == null) return;
                                try {
                                  await ref
                                      .read(ordersRepositoryProvider)
                                      .denunciarRepartidor(p.id, reason);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Se envió la denuncia'),
                                      ),
                                    );
                                  }
                                } catch (error) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(errorMessage(error)),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          if (p.estado == 'pendiente')
                            OutlinedButton.icon(
                              icon: const Icon(Icons.cancel_outlined),
                              label: const Text('Cancelar pedido'),
                              onPressed: () async {
                                try {
                                  await ref
                                      .read(ordersRepositoryProvider)
                                      .cancelar(p.id);
                                  ref.invalidate(misPedidosProvider);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(errorMessage(e))),
                                    );
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
