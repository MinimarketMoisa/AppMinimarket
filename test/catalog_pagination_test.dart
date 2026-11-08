import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimarket/features/catalog/data/models/catalogo_models.dart';
import 'package:minimarket/features/catalog/data/repositories/catalog_repository.dart';
import 'package:minimarket/features/catalog/presentation/pages/catalog_page.dart';
import 'package:minimarket/features/catalog/presentation/providers/catalog_provider.dart';

class _PaginatedCatalogRepository extends CatalogRepository {
  _PaginatedCatalogRepository() : super(Dio());

  final requestedOffsets = <int>[];
  final requestedCategoryIds = <int?>[];
  final products = List.generate(
    30,
    (index) => Producto(
      id: index + 1,
      nombre: 'Producto ${index + 1}',
      precioBase: 1,
      categoriaId: index.isEven ? 1 : 2,
    ),
  );

  @override
  Future<List<Categoria>> categorias() async => const [
    Categoria(id: 1, nombre: 'Bebidas'),
    Categoria(id: 2, nombre: 'Despensa'),
  ];

  @override
  Future<List<Producto>> productos({
    int? categoriaId,
    String? q,
    int skip = 0,
    int limit = 24,
  }) async {
    requestedOffsets.add(skip);
    requestedCategoryIds.add(categoriaId);
    final filtered = categoriaId == null
        ? products
        : products.where((product) => product.categoriaId == categoriaId);
    return filtered.skip(skip).take(limit).toList();
  }
}

void main() {
  testWidgets('catalog pagination buttons navigate between API pages', (
    tester,
  ) async {
    final repository = _PaginatedCatalogRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(repository),
          for (var id = 1; id <= 30; id++)
            disponibilidadProductoProvider(id).overrideWith(
              (ref) async => [
                const Disponibilidad(
                  sucursalId: 1,
                  nombreSucursal: 'Sucursal',
                  stockDisponible: 5,
                ),
              ],
            ),
        ],
        child: const MaterialApp(home: CatalogPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.requestedOffsets, contains(0));
    expect(find.text('Anterior'), findsOneWidget);
    expect(find.text('Siguiente'), findsOneWidget);
    expect(find.text('Página 1'), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
    );

    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(repository.requestedOffsets, contains(24));
    expect(find.text('Página 2'), findsOneWidget);
    expect(find.text('Producto 30'), findsOneWidget);

    await tester.tap(find.text('Anterior'));
    await tester.pumpAndSettle();
    expect(find.text('Página 1'), findsOneWidget);

    await tester.tap(find.text('Despensa'));
    await tester.pumpAndSettle();
    expect(repository.requestedCategoryIds.last, 2);
    expect(find.text('Despensa'), findsWidgets);
    expect(find.text('Página 1'), findsNWidgets(2));
  });
}
