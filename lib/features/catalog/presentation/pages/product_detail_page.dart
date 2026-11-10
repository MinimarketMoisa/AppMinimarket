import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../providers/catalog_provider.dart';

class ProductDetailPage extends ConsumerWidget {
  const ProductDetailPage({super.key, required this.productoId});

  final int productoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final product = ref.watch(productoDetalleProvider(productoId));
    final categories = ref.watch(categoriasProvider);
    final stock = ref.watch(disponibilidadProductoProvider(productoId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del producto')),
      body: product.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorView(
          error: error,
          title: 'No pudimos cargar el producto',
          onRetry: () => ref.invalidate(productoDetalleProvider(productoId)),
        ),
        data: (item) {
          final categoryName = categories.value
              ?.where((category) => category.id == item.categoriaId)
              .map((category) => category.nombre)
              .firstOrNull;
          final availableAt = stock.value
              ?.where((branch) => branch.stockDisponible > 0)
              .toList();
          final available = availableAt?.isNotEmpty ?? false;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: ColoredBox(
                        color: colors.surfaceContainerLow,
                        child: SizedBox(
                          height: 300,
                          child: item.imagenUrl == null ||
                                  item.imagenUrl!.isEmpty
                              ? Icon(
                                  Icons.shopping_basket_outlined,
                                  size: 88,
                                  color: colors.primary,
                                )
                              : Image.network(
                                  item.imagenUrl!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => Icon(
                                    Icons.shopping_basket_outlined,
                                    size: 88,
                                    color: colors.primary,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (categoryName != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Chip(
                          avatar: Icon(
                            Icons.sell_outlined,
                            size: 16,
                            color: colors.primary,
                          ),
                          label: Text(categoryName),
                          backgroundColor: colors.primaryContainer,
                          side: BorderSide.none,
                        ),
                      ),
                    Text(
                      item.nombre,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      money(item.precioBase),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (item.descripcion?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Descripción',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.descripcion!,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ],
                    if (item.codigoBarras?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Código: ${item.codigoBarras}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      'Disponibilidad por sucursal',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    stock.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (error, _) => AppErrorNotice(
                        error: error,
                        title: 'No pudimos consultar las existencias',
                        onRetry: () => ref.invalidate(
                          disponibilidadProductoProvider(productoId),
                        ),
                      ),
                      data: (branches) => branches.isEmpty
                          ? const ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.info_outline),
                              title: Text('No hay existencias registradas'),
                            )
                          : Column(
                              children: [
                                for (final branch in branches)
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(
                                      branch.stockDisponible > 0
                                          ? Icons.storefront_outlined
                                          : Icons.store_outlined,
                                      color: branch.stockDisponible > 0
                                          ? colors.primary
                                          : colors.onSurfaceVariant,
                                    ),
                                    title: Text(branch.nombreSucursal),
                                    trailing: Text(
                                      branch.stockDisponible > 0
                                          ? '${branch.stockDisponible} disponibles'
                                          : 'Agotado',
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            color: branch.stockDisponible > 0
                                                ? colors.primary
                                                : colors.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: stock.hasError
                          ? () => ref.invalidate(
                              disponibilidadProductoProvider(productoId),
                            )
                          : available
                          ? () {
                              ref.read(cartProvider.notifier).add(item);
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(
                                    content: Text('${item.nombre} agregado'),
                                  ),
                                );
                              Navigator.of(context).pop();
                            }
                          : null,
                      icon: Icon(
                        stock.hasError
                            ? Icons.refresh
                            : Icons.add_shopping_cart,
                      ),
                      label: Text(
                        stock.hasError
                            ? 'Reintentar existencias'
                            : available
                            ? 'Agregar al carrito'
                            : 'Agotado',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
