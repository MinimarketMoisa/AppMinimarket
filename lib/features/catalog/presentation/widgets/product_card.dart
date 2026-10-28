import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/helpers.dart';
import '../../data/models/catalogo_models.dart';
import '../providers/catalog_provider.dart';

class ProductCard extends ConsumerWidget {
  final Producto producto;
  final VoidCallback onAdd;
  const ProductCard({super.key, required this.producto, required this.onAdd});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final stock = ref.watch(disponibilidadProductoProvider(producto.id));
    final hasStock =
        stock.value?.any((row) => row.stockDisponible > 0) ?? false;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: producto.imagenUrl != null
                    ? Image.network(
                        producto.imagenUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.shopping_basket, size: 40),
                      )
                    : Icon(Icons.shopping_basket, size: 40, color: cs.primary),
              ),
            ),
            const SizedBox(height: 8),
            Text(producto.nombre, maxLines: 2, overflow: TextOverflow.ellipsis),
            stock.when(
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (error, _) => Tooltip(
                message: errorMessage(error),
                child: const Text(
                  'No se pudo cargar stock',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11),
                ),
              ),
              data: (rows) => Text(
                rows.isEmpty
                    ? 'Sin stock disponible'
                    : rows
                        .map((row) => '${row.nombreSucursal}: ${row.stockDisponible}')
                        .join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  money(producto.precioBase),
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton.filled(
                  visualDensity: VisualDensity.compact,
                  onPressed: hasStock ? onAdd : null,
                  icon: const Icon(Icons.add),
                  tooltip: 'Agregar',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
