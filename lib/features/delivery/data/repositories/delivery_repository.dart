import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../orders/data/models/pedido_models.dart';

class DeliveryRepository {
  final Dio dio;
  DeliveryRepository(this.dio);

  Future<Pedido?> entrante() async {
    final data = (await dio.get(ApiEndpoints.repartidorEntrante)).data;
    if (data == null) return null;
    return Pedido.fromJson(data as Map<String, dynamic>);
  }

  Future<List<Pedido>> asignados() async {
    final r = await dio.get(ApiEndpoints.repartidorPedidos);
    return (r.data as List)
        .map((e) => Pedido.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> cambiarEstado(String estado) =>
      dio.patch(ApiEndpoints.repartidorEstado, data: {'estado': estado});

  Future<void> actualizarUbicacion(double lat, double lng) => dio.patch(
    ApiEndpoints.repartidorUbicacion,
    data: {'latitud': lat, 'longitud': lng},
  );

  Future<void> aceptar(int pedidoId) async {
    await dio.post(ApiEndpoints.aceptarPedidoRepartidor(pedidoId));
  }

  Future<void> rechazar(int pedidoId, String motivo) async {
    await dio.post(
      ApiEndpoints.rechazarPedidoRepartidor(pedidoId),
      data: {'motivo': motivo},
    );
  }

  Future<void> cambiarEstadoPedido(int pedidoId, String estado) =>
      dio.patch(ApiEndpoints.estadoPedido(pedidoId), data: {'estado': estado});
}
