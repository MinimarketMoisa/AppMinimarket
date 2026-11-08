import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_error_view.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../providers/catalog_provider.dart';
import '../widgets/product_card.dart';

class CatalogPage extends ConsumerStatefulWidget {
  const CatalogPage({super.key});

  @override
  ConsumerState<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends ConsumerState<CatalogPage> {
  static const _pageSize = 24;
  int _pageIndex = 0;

  void _resetPage() {
    if (_pageIndex == 0) return;
    setState(() => _pageIndex = 0);
  }

  Future<void> _refresh(CatalogPageRequest request) async {
    ref.invalidate(productosProvider(request));
    await ref.read(productosProvider(request).future);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(selectedCategoriaProvider, (_, _) => _resetPage());
    ref.listen(searchProvider, (_, _) => _resetPage());

    final theme = Theme.of(context);
    final categories = ref.watch(categoriasProvider);
    final categoryId = ref.watch(selectedCategoriaProvider);
    final query = ref.watch(searchProvider);
    final request = CatalogPageRequest(
      categoriaId: categoryId,
      query: query,
      skip: _pageIndex * _pageSize,
      limit: _pageSize,
    );
    final productsPage = ref.watch(productosProvider(request));
    final selectedCategoryName = categories.value
        ?.where((category) => category.id == categoryId)
        .map((category) => category.nombre)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar productos',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpiar búsqueda',
                        onPressed: () =>
                            ref.read(searchProvider.notifier).state = '',
                        icon: const Icon(Icons.close),
                      ),
              ),
              onSubmitted: (value) =>
                  ref.read(searchProvider.notifier).state = value.trim(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.grid_view_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Compra por categoría',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: categories.when(
              loading: () => const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: AppErrorNotice(
                  error: error,
                  title: 'No pudimos cargar las categorías',
                  onRetry: () => ref.invalidate(categoriasProvider),
                ),
              ),
              data: (list) => ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _CategoryButton(
                    label: 'Todos',
                    selected: categoryId == null,
                    onPressed: () =>
                        ref.read(selectedCategoriaProvider.notifier).state =
                            null,
                  ),
                  for (final category in list)
                    _CategoryButton(
                      label: category.nombre,
                      selected: categoryId == category.id,
                      onPressed: () =>
                          ref.read(selectedCategoriaProvider.notifier).state =
                              category.id,
                    ),
                ],
              ),
            ),
          ),
          if (selectedCategoryName != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedCategoryName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    'Página ${_pageIndex + 1}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  query.isEmpty ? 'Productos destacados' : 'Resultados',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Expanded(
            child: productsPage.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => AppErrorView(
                error: error,
                title: 'No pudimos cargar los productos',
                onRetry: () => ref.invalidate(productosProvider(request)),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () => _refresh(request),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Icon(Icons.search_off, size: 48),
                        SizedBox(height: 12),
                        Center(child: Text('No se encontraron productos')),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => _refresh(request),
                  child: GridView.builder(
                    key: PageStorageKey(
                      'catalog-${categoryId ?? 'all'}-$query-$_pageIndex',
                    ),
                    padding: const EdgeInsets.all(12),
                    physics: const AlwaysScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount: products.length,
                    itemBuilder: (context, index) => ProductCard(
                      producto: products[index],
                      onAdd: () {
                        ref.read(cartProvider.notifier).add(products[index]);
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              duration: const Duration(seconds: 1),
                              content: Text(
                                '${products[index].nombre} agregado',
                              ),
                            ),
                          );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          productsPage.when(
            loading: () => const LinearProgressIndicator(minHeight: 2),
            error: (_, _) => const SizedBox(height: 2),
            data: (products) => _PaginationBar(
              pageIndex: _pageIndex,
              hasPrevious: _pageIndex > 0,
              hasNext: products.length == _pageSize,
              onPrevious: () => setState(() => _pageIndex--),
              onNext: () => setState(() => _pageIndex++),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      avatar: selected ? const Icon(Icons.check, size: 16) : null,
      label: Text(label),
      selected: selected,
      onSelected: (_) => onPressed(),
      showCheckmark: false,
    ),
  );
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.pageIndex,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPrevious,
    required this.onNext,
  });

  final int pageIndex;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: hasPrevious ? onPrevious : null,
              icon: const Icon(Icons.chevron_left),
              label: const Text('Anterior'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Página ${pageIndex + 1}',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: FilledButton.icon(
              onPressed: hasNext ? onNext : null,
              icon: const Icon(Icons.chevron_right),
              label: const Text('Siguiente'),
              iconAlignment: IconAlignment.end,
            ),
          ),
        ],
      ),
    ),
  );
}
