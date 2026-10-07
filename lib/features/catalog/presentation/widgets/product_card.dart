import 'package:flutter/material.dart';
import '../../../../core/utils/helpers.dart';
import '../../data/models/catalogo_models.dart';

class ProductCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback onAdd;
  const ProductCard({super.key, required this.producto, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
                    color: cs.primaryContainer, borderRadius: BorderRadius.circular(10)),
                child: producto.imagenUrl != null
                    ? Image.network(producto.imagenUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.shopping_basket, size: 40))
                    : Icon(Icons.shopping_basket, size: 40, color: cs.primary),
              ),
            ),
            const SizedBox(height: 8),
            Text(producto.nombre, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(money(producto.precioBase),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton.filled(
                  visualDensity: VisualDensity.compact,
                  onPressed: onAdd,
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