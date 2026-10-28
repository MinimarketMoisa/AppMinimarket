import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/helpers.dart';
import '../../../catalog/presentation/providers/catalog_provider.dart';
import '../../../addresses/presentation/pages/addresses_page.dart';
import '../../../addresses/presentation/providers/addresses_provider.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../providers/cart_provider.dart';

class CartPage extends ConsumerStatefulWidget {
  final VoidCallback? onOrdered;
  const CartPage({super.key, this.onOrdered});
  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  String _entrega = 'domicilio';
  String _pago = 'contra_entrega';
  int? _dirId;
  int? _sucursalId;
  bool _loading = false;

  Future<void> _confirmar() async {
    final items = ref.read(cartProvider);
    if (_entrega == 'domicilio' && _dirId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una dirección de entrega')),
      );
      return;
    }
    if (_entrega == 'retiro' && _sucursalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una sucursal para retirar')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref
          .read(ordersRepositoryProvider)
          .crear(
            items: [
              for (final i in items)
                {'id_producto': i.producto.id, 'cantidad': i.cantidad},
            ],
            direccionId: _entrega == 'domicilio' ? _dirId : null,
            sucursalId: _entrega == 'retiro' ? _sucursalId : null,
            tipoEntrega: _entrega,
            metodoPago: _pago,
          );
      ref.read(cartProvider.notifier).clear();
      ref.invalidate(misPedidosProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Pedido realizado con éxito!')),
        );
        widget.onOrdered?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(cartProvider);
    if (items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Carrito')),
        body: const Center(child: Text('Tu carrito está vacío')),
      );
    }
    final subtotal = ref.watch(cartTotalProvider);
    final dirs = ref.watch(direccionesProvider);
    final sucursales = ref.watch(sucursalesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Carrito')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final i in items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(i.producto.nombre),
              subtitle: Text(
                '${money(i.producto.precioBase)} c/u · ${money(i.subtotal)}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () =>
                        ref.read(cartProvider.notifier).decrement(i.producto),
                  ),
                  Text(
                    '${i.cantidad}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () =>
                        ref.read(cartProvider.notifier).add(i.producto),
                  ),
                ],
              ),
            ),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'Tipo de entrega',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'domicilio',
                label: Text('Domicilio'),
                icon: Icon(Icons.delivery_dining),
              ),
              ButtonSegment(
                value: 'retiro',
                label: Text('Retiro'),
                icon: Icon(Icons.store),
              ),
            ],
            selected: {_entrega},
            onSelectionChanged: (s) => setState(() => _entrega = s.first),
          ),
          if (_entrega == 'domicilio') ...[
            const SizedBox(height: 12),
            dirs.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(errorMessage(e)),
              data: (list) => list.isEmpty
                  ? TextButton.icon(
                      icon: const Icon(Icons.add_location_alt),
                      label: const Text('Agrega una dirección para continuar'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AddressesPage(),
                        ),
                      ),
                    )
                  : DropdownButtonFormField<int>(
                      initialValue:
                          list.any((d) => d.id == _dirId) ? _dirId : null,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Dirección de entrega',
                      ),
                      items: [
                        for (final d in list)
                          DropdownMenuItem(
                            value: d.id,
                            child: Text(
                              d.resumen,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (v) => setState(() => _dirId = v),
                    ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            sucursales.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(errorMessage(e)),
              data: (list) => DropdownButtonFormField<int>(
                initialValue: list.any((s) => s.id == _sucursalId)
                    ? _sucursalId
                    : null,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Sucursal de retiro',
                ),
                items: [
                  for (final s in list)
                    DropdownMenuItem(
                      value: s.id,
                      child: Text(
                        '${s.nombre} · ${s.direccion}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _sucursalId = v),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Método de pago',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'contra_entrega',
                label: Text('Efectivo'),
                icon: Icon(Icons.payments_outlined),
              ),
              ButtonSegment(
                value: 'transferencia',
                label: Text('Transferencia'),
                icon: Icon(Icons.account_balance),
              ),
            ],
            selected: {_pago},
            onSelectionChanged: (s) => setState(() => _pago = s.first),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(child: Text('Subtotal')),
              Text(money(subtotal)),
            ],
          ),
          if (_entrega == 'domicilio')
            const Row(
              children: [
                Expanded(child: Text('Envío')),
                Text('Se calcula al confirmar'),
              ],
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  _entrega == 'domicilio'
                      ? 'Total (envío al confirmar)'
                      : 'Total',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Text(
                money(subtotal),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loading ? null : _confirmar,
            icon: _loading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: const Text('Confirmar pedido'),
          ),
        ],
      ),
    );
  }
}
