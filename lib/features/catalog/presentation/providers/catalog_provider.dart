import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/models/catalogo_models.dart';
import '../../data/repositories/catalog_repository.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(ref.read(dioProvider)),
);

final categoriasProvider = FutureProvider.autoDispose<List<Categoria>>(
  (ref) => ref.read(catalogRepositoryProvider).categorias(),
);

final sucursalesProvider = FutureProvider.autoDispose<List<Sucursal>>(
  (ref) => ref.read(catalogRepositoryProvider).sucursales(),
);

final selectedCategoriaProvider = StateProvider<int?>((ref) => null);
final searchProvider = StateProvider<String>((ref) => '');

class CatalogPageRequest {
  const CatalogPageRequest({
    this.categoriaId,
    this.query = '',
    this.skip = 0,
    this.limit = 24,
  });

  final int? categoriaId;
  final String query;
  final int skip;
  final int limit;

  @override
  bool operator ==(Object other) =>
      other is CatalogPageRequest &&
      other.categoriaId == categoriaId &&
      other.query == query &&
      other.skip == skip &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(categoriaId, query, skip, limit);
}

final productosProvider =
    FutureProvider.autoDispose.family<List<Producto>, CatalogPageRequest>(
      (ref, request) => ref
          .read(catalogRepositoryProvider)
          .productos(
            categoriaId: request.categoriaId,
            q: request.query,
            skip: request.skip,
            limit: request.limit,
          ),
    );

final disponibilidadProductoProvider =
    FutureProvider.autoDispose.family<List<Disponibilidad>, int>(
      (ref, productoId) =>
          ref.read(catalogRepositoryProvider).disponibilidad(productoId),
    );
