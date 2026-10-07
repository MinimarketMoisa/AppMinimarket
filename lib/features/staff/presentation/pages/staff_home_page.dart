import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/helpers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../../orders/presentation/widgets/pedido_card.dart';
import '../providers/staff_provider.dart';

const _estados = [
  'pendiente',
  'preparando',
  'listo',
  'en_camino',
  'entregado',
  'cancelado',
];

class StaffHomePage extends ConsumerWidget {
  const StaffHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel de empleado'),
          actions: [
            IconButton(
              tooltip: 'Cerrar sesión',
              icon: const Icon(Icons.logout),
              onPressed: () => ref.read(authProvider.notifier).logout(),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.receipt_long), text: 'Pedidos'),
              Tab(icon: Icon(Icons.inventory_2), text: 'Inventario'),
            ],
          ),
        ),
        body: const TabBarView(children: [_PedidosTab(), _InventarioTab()]),
      ),
    );
  }
}

class _PedidosTab extends ConsumerWidget {
  const _PedidosTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pedidos = ref.watch(todosPedidosProvider);
    return pedidos.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(errorMessage(e))),
      data: (list) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(todosPedidosProvider),
        child: list.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 160),
                  Center(child: Text('Sin pedidos')),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  for (final p in list)
                    PedidoCard(
                      pedido: p,
                      mostrarCliente: true,
                      actions: [
                        DropdownButton<String>(
                          value: _estados.contains(p.estado) ? p.estado : null,
                          hint: const Text('Cambiar estado'),
                          items: [
                            for (final e in _estados)
                              DropdownMenuItem(
                                value: e,
                                child: Text(estadoLabel(e)),
                              ),
                          ],
                          onChanged: (v) async {
                            if (v == null || v == p.estado) return;
                            try {
                              await ref
                                  .read(ordersRepositoryProvider)
                                  .cambiarEstado(p.id, v);
                              ref.invalidate(todosPedidosProvider);
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
    );
  }
}

class _InventarioTab extends ConsumerWidget {
  const _InventarioTab();

  Future<void> _editar(
    BuildContext context,
    WidgetRef ref,
    int id,
    String nombre,
    int actual,
  ) async {
    final nuevo = await showDialog<int>(
      context: context,
      builder: (_) => _StockEditorDialog(nombre: nombre, stockActual: actual),
    );
    if (nuevo == null || nuevo < 0) return;
    try {
      await ref.read(inventoryRepositoryProvider).fijarStock(id, nuevo);
      ref.invalidate(inventarioProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inv = ref.watch(inventarioProvider);
    return inv.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(errorMessage(e))),
      data: (list) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(inventarioProvider),
        child: ListView(
          children: [
            for (final i in list)
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(i.productoNombre),
                subtitle: Text(
                  i.fechaVencimiento != null
                      ? 'Vence: ${i.fechaVencimiento}'
                      : '',
                ),
                trailing: Text(
                  '${i.stockDisponible}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: i.stockDisponible < 10 ? Colors.red : null,
                  ),
                ),
                onTap: () => _editar(
                  context,
                  ref,
                  i.id,
                  i.productoNombre,
                  i.stockDisponible,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StockEditorDialog extends StatefulWidget {
  const _StockEditorDialog({required this.nombre, required this.stockActual});

  final String nombre;
  final int stockActual;

  @override
  State<_StockEditorDialog> createState() => _StockEditorDialogState();
}

class _StockEditorDialogState extends State<_StockEditorDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.stockActual}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.nombre),
    content: TextField(
      controller: _controller,
      keyboardType: TextInputType.number,
      autofocus: true,
      decoration: const InputDecoration(labelText: 'Nuevo stock'),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () =>
            Navigator.pop(context, int.tryParse(_controller.text.trim())),
        child: const Text('Guardar'),
      ),
    ],
  );
}
