import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../models/catalogo_models.dart';

class CatalogRepository {
  final Dio dio;
  CatalogRepository(this.dio);

  Future<List<Categoria>> categorias() async {
    final r = await dio.get(ApiEndpoints.categorias);
    return (r.data as List)
        .map((e) => Categoria.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Sucursal>> sucursales() async {
    final r = await dio.get(ApiEndpoints.sucursales);
    return (r.data as List)
        .map((e) => Sucursal.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Producto>> productos({
    int? categoriaId,
    String? q,
    int skip = 0,
    int limit = 24,
  }) async {
    final r = await dio.get(
      ApiEndpoints.productos,
      queryParameters: {
        'id_categoria': ?categoriaId,
        if (q != null && q.isNotEmpty) 'q': q,
        'skip': skip,
        'limit': limit,
      },
    );
    return (r.data as List)
        .map((e) => Producto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Producto> productoPorId(int productoId) async {
    final response = await dio.get(ApiEndpoints.productoPorId(productoId));
    return Producto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Disponibilidad>> disponibilidad(int productoId) async {
    final response = await dio.get(
      ApiEndpoints.disponibilidadProducto(productoId),
    );
    return (response.data as List)
        .map((item) => Disponibilidad.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> validarInventarioPedido({
    required Map<int, int> cantidades,
    required Set<int> sucursalesCandidatas,
  }) async {
    if (sucursalesCandidatas.isEmpty) {
      throw StateError('No hay sucursales activas para esta zona.');
    }

    final disponibilidades = <int, List<Disponibilidad>>{};
    await Future.wait(
      cantidades.keys.map((productoId) async {
        disponibilidades[productoId] = await disponibilidad(productoId);
      }),
    );
    final hayUnaSucursalQueCubreTodo = sucursalesCandidatas.any((sucursalId) {
      for (final entry in cantidades.entries) {
        final stock = disponibilidades[entry.key]!
            .where((item) => item.sucursalId == sucursalId)
            .fold<int>(0, (total, item) => total + item.stockDisponible);
        if (stock < entry.value) return false;
      }
      return true;
    });

    if (!hayUnaSucursalQueCubreTodo) {
      throw StateError(
        'Ninguna sucursal de la zona tiene existencias suficientes para '
        'completar todo el carrito. Reduce las cantidades o quita productos '
        'y vuelve a intentar.',
      );
    }
  }
}
