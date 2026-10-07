import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/inventario_model.dart';

class InventoryRepository {
  final Dio dio;
  InventoryRepository(this.dio);

  Future<List<Inventario>> listar() async {
    final r = await dio.get(ApiEndpoints.inventario);
    return (r.data as List).map((e) => Inventario.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> fijarStock(int id, int cantidad) =>
      dio.patch(ApiEndpoints.stock(id), data: {'stock_disponible': cantidad});
}