import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/helpers.dart';
import '../../data/models/catalogo_models.dart';
import '../pages/product_detail_page.dart';
import '../providers/catalog_provider.dart';

class ProductCard extends ConsumerWidget {
  final Producto producto;
  final VoidCallback onAdd;
  const ProductCard({super.key, required this.producto, required this.onAdd});

  void _showDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailPage(productoId: producto.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final stock = ref.watch(disponibilidadProductoProvider(producto.id));
    final hasStock =
        stock.value?.any((row) => row.stockDisponible > 0) ?? false;
    return Card(
      color: cs.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: producto.imagenUrl != null
                      ? Image.network(
                          producto.imagenUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => Icon(
                            Icons.shopping_basket_outlined,
                            size: 40,
                            color: cs.primary,
                          ),
                        )
                      : Icon(
                          Icons.shopping_basket_outlined,
                          size: 40,
                          color: cs.primary,
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                producto.nombre,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
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
                            .map(
                              (row) =>
                                  '${row.nombreSucursal}: ${row.stockDisponible}',
                            )
                            .join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      money(producto.precioBase),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    visualDensity: VisualDensity.compact,
                    onPressed: hasStock ? onAdd : null,
                    icon: const Icon(Icons.add_shopping_cart_outlined),
                    tooltip: 'Agregar al carrito',
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
