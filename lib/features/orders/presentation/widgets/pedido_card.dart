import 'package:flutter/material.dart';
import '../../../../core/utils/helpers.dart';
import '../../data/models/pedido_models.dart';

class PedidoCard extends StatelessWidget {
  final Pedido pedido;
  final List<Widget> actions;
  final bool mostrarCliente;
  const PedidoCard({
    super.key,
    required this.pedido,
    this.actions = const [],
    this.mostrarCliente = false,
  });

  Color _color(String e) => switch (e) {
        'pendiente' => Colors.orange,
        'preparando' => Colors.blue,
        'listo' => Colors.teal,
        'en_camino' => Colors.indigo,
        'entregado' => Colors.green,
        'cancelado' => Colors.red,
        _ => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = _color(pedido.estado);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('Pedido #${pedido.id}',
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              Chip(
                label: Text(estadoLabel(pedido.estado), style: TextStyle(color: c)),
                backgroundColor: c.withAlpha(35),
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
              ),
            ]),
            Text(fechaCorta(pedido.fechaCreacion), style: t.bodySmall),
            if (mostrarCliente && pedido.clienteNombre != null)
              Text('Cliente: ${pedido.clienteNombre}'),
            Text(pedido.tipoEntrega == 'domicilio' ? 'A domicilio' : 'Retiro en tienda'),
            if (pedido.direccion != null) Text('Entrega: ${pedido.direccion}'),
            Text('Pago: ${pedido.metodoPago} (${pedido.estadoPago})'),
            const Divider(),
            for (final d in pedido.detalles)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(children: [
                  Expanded(child: Text('${d.cantidad} x ${d.nombreProducto}')),
                  Text(money(d.subtotal)),
                ]),
              ),
            if (pedido.costoEnvio > 0)
              Row(children: [
                const Expanded(child: Text('Envío')),
                Text(money(pedido.costoEnvio)),
              ]),
            const Divider(),
            Row(children: [
              const Expanded(child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
              Text(money(pedido.total), style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 4, children: actions),
            ],
          ],
        ),
      ),
    );
  }
}