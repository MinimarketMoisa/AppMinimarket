import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../orders/data/models/pedido_models.dart';

class DeliveryRepository {
  final Dio dio;
  DeliveryRepository(this.dio);

  Future<List<Pedido>> asignados() async {
    final r = await dio.get(ApiEndpoints.repartidorPedidos);
    return (r.data as List).map((e) => Pedido.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> completar(int pedidoId) => dio.post(ApiEndpoints.completarEntrega(pedidoId));

  Future<void> cambiarEstado(String estadoOperativo) =>
      dio.patch(ApiEndpoints.repartidorEstado, data: {'estado_operativo': estadoOperativo});

  Future<void> actualizarUbicacion(double lat, double lng) =>
      dio.post(ApiEndpoints.repartidorUbicacion, data: {'latitud': lat, 'longitud': lng});
}