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

  Future<List<Producto>> productos({int? categoriaId, String? q}) async {
    final r = await dio.get(
      ApiEndpoints.productos,
      queryParameters: {
        'id_categoria': ?categoriaId,
        if (q != null && q.isNotEmpty) 'q': q,
      },
    );
    return (r.data as List)
        .map((e) => Producto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Disponibilidad>> disponibilidad(int productoId) async {
    final response = await dio.get(
      ApiEndpoints.disponibilidadProducto(productoId),
    );
    return (response.data as List)
        .map((item) => Disponibilidad.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
