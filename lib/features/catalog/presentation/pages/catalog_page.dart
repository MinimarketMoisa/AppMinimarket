import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../data/models/catalogo_models.dart';
import '../providers/catalog_provider.dart';
import '../widgets/product_card.dart';

class CatalogPage extends ConsumerStatefulWidget {
  const CatalogPage({super.key});

  @override
  ConsumerState<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends ConsumerState<CatalogPage> {
  static const _pageSize = 24;
  final _scrollController = ScrollController();
  List<Producto> _products = [];
  String? _loadedFilter;
  String? _paginationError;
  int _requestGeneration = 0;
  int? _activeCategory;
  String _activeQuery = '';
  String _activeFilterKey = '';
  bool _hasMore = true;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _resetPagination() {
    _requestGeneration++;
    setState(() {
      _products = [];
      _loadedFilter = null;
      _paginationError = null;
      _hasMore = true;
      _loadingMore = false;
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 500 &&
        _loadedFilter == _activeFilterKey) {
      _loadMore(
        categoryId: _activeCategory,
        query: _activeQuery,
        filterKey: _activeFilterKey,
      );
    }
  }

  Future<void> _loadMore({
    List<Producto>? firstPage,
    required int? categoryId,
    required String query,
    required String filterKey,
  }) async {
    if (_loadingMore || !_hasMore || !mounted) return;
    final generation = _requestGeneration;
    setState(() {
      _loadingMore = true;
      _paginationError = null;
      if (_loadedFilter != filterKey && firstPage != null) {
        _products = firstPage;
        _loadedFilter = filterKey;
        _hasMore = firstPage.length == _pageSize;
      }
    });
    final offset = _products.length;
    if (!_hasMore) {
      if (mounted) setState(() => _loadingMore = false);
      return;
    }
    try {
      final nextPage = await ref
          .read(catalogRepositoryProvider)
          .productos(
            categoriaId: categoryId,
            q: query,
            skip: offset,
            limit: _pageSize,
          );
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _products = [..._products, ...nextPage];
        _hasMore = nextPage.length == _pageSize;
      });
    } catch (error) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() => _paginationError = errorMessage(error));
    } finally {
      if (mounted && generation == _requestGeneration) {
        setState(() => _loadingMore = false);
      }
    }
  }

  Future<void> _refresh() async {
    _resetPagination();
    final categoryId = ref.read(selectedCategoriaProvider);
    final query = ref.read(searchProvider);
    ref.invalidate(
      productosProvider(
        CatalogPageRequest(
          categoriaId: categoryId,
          query: query,
          skip: 0,
          limit: _pageSize,
        ),
      ),
    );
    await ref.read(
      productosProvider(
        CatalogPageRequest(
          categoriaId: categoryId,
          query: query,
          skip: 0,
          limit: _pageSize,
        ),
      ).future,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(selectedCategoriaProvider, (_, _) => _resetPagination());
    ref.listen(searchProvider, (_, _) => _resetPagination());

    final categories = ref.watch(categoriasProvider);
    final categoryId = ref.watch(selectedCategoriaProvider);
    final query = ref.watch(searchProvider);
    final request = CatalogPageRequest(
      categoriaId: categoryId,
      query: query,
      skip: 0,
      limit: _pageSize,
    );
    final filterKey = '${request.categoriaId}|${request.query}';
    _activeCategory = categoryId;
    _activeQuery = query;
    _activeFilterKey = filterKey;
    final firstPage = ref.watch(productosProvider(request));

    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
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
          SizedBox(
            height: 48,
            child: categories.when(
              loading: () => const SizedBox(),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('Todos'),
                      selected: categoryId == null,
                      onSelected: (_) =>
                          ref.read(selectedCategoriaProvider.notifier).state =
                              null,
                    ),
                  ),
                  for (final category in list)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category.nombre),
                        selected: categoryId == category.id,
                        onSelected: (_) =>
                            ref.read(selectedCategoriaProvider.notifier).state =
                                category.id,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: firstPage.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => AppErrorView(
                error: error,
                title: 'No pudimos cargar los productos',
                onRetry: () => ref.invalidate(productosProvider(request)),
              ),
              data: (page) {
                final products = _loadedFilter == filterKey
                    ? _products
                    : page;
                if (_loadedFilter != filterKey &&
                    !_loadingMore &&
                    products.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted || _loadedFilter == filterKey) return;
                    setState(() {
                      _products = page;
                      _loadedFilter = filterKey;
                      _hasMore = page.length == _pageSize;
                    });
                  });
                }
                if (products.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 140),
                        Icon(Icons.search_off, size: 48),
                        SizedBox(height: 12),
                        Center(child: Text('No se encontraron productos')),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.all(12),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 220,
                                childAspectRatio: 0.72,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => ProductCard(
                              producto: products[index],
                              onAdd: () {
                                ref
                                    .read(cartProvider.notifier)
                                    .add(products[index]);
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
                            childCount: products.length,
                          ),
                        ),
                      ),
                      if (_paginationError != null)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Text(
                                  'No pudimos cargar más productos. '
                                  '$_paginationError',
                                  textAlign: TextAlign.center,
                                ),
                                TextButton(
                                  onPressed: () => _loadMore(
                                    categoryId: categoryId,
                                    query: query,
                                    filterKey: filterKey,
                                    firstPage: page,
                                  ),
                                  child: const Text('Reintentar'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (_loadingMore)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        )
                      else if (_hasMore)
                        SliverToBoxAdapter(
                          child: Center(
                            child: TextButton.icon(
                              onPressed: () => _loadMore(
                                categoryId: categoryId,
                                query: query,
                                filterKey: filterKey,
                                firstPage: page,
                              ),
                              icon: const Icon(Icons.expand_more),
                              label: const Text('Cargar más productos'),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
