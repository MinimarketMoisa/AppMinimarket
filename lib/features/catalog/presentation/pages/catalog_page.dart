import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/helpers.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../providers/catalog_provider.dart';
import '../widgets/product_card.dart';

class CatalogPage extends ConsumerWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categorias = ref.watch(categoriasProvider);
    final productos = ref.watch(productosProvider);
    final selected = ref.watch(selectedCategoriaProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onSubmitted: (v) => ref.read(searchProvider.notifier).state = v.trim(),
            ),
          ),
          SizedBox(
            height: 48,
            child: categorias.when(
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
              data: (cats) => ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('Todos'),
                      selected: selected == null,
                      onSelected: (_) => ref.read(selectedCategoriaProvider.notifier).state = null,
                    ),
                  ),
                  for (final c in cats)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(c.nombre),
                        selected: selected == c.id,
                        onSelected: (_) =>
                            ref.read(selectedCategoriaProvider.notifier).state = c.id,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: productos.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(errorMessage(e)),
                  TextButton(
                      onPressed: () => ref.invalidate(productosProvider),
                      child: const Text('Reintentar')),
                ]),
              ),
              data: (list) => list.isEmpty
                  ? const Center(child: Text('No se encontraron productos'))
                  : RefreshIndicator(
                      onRefresh: () async => ref.invalidate(productosProvider),
                      child: GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: list.length,
                        itemBuilder: (_, i) => ProductCard(
                          producto: list[i],
                          onAdd: () {
                            ref.read(cartProvider.notifier).add(list[i]);
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(SnackBar(
                                  duration: const Duration(seconds: 1),
                                  content: Text('${list[i].nombre} agregado')));
                          },
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}