import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/models/catalogo_models.dart';
import '../../data/repositories/catalog_repository.dart';

final catalogRepositoryProvider =
    Provider<CatalogRepository>((ref) => CatalogRepository(ref.read(dioProvider)));

final categoriasProvider = FutureProvider.autoDispose<List<Categoria>>(
    (ref) => ref.read(catalogRepositoryProvider).categorias());

final selectedCategoriaProvider = StateProvider<int?>((ref) => null);
final searchProvider = StateProvider<String>((ref) => '');

final productosProvider = FutureProvider.autoDispose<List<Producto>>((ref) {
  final cat = ref.watch(selectedCategoriaProvider);
  final q = ref.watch(searchProvider);
  return ref.read(catalogRepositoryProvider).productos(categoriaId: cat, q: q);
});