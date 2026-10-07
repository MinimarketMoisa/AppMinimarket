import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/pedido_models.dart';

class OrdersRepository {
  final Dio dio;
  OrdersRepository(this.dio);

  List<Pedido> _list(dynamic data) =>
      (data as List).map((e) => Pedido.fromJson(e as Map<String, dynamic>)).toList();

  Future<Pedido> crear({
    required List<Map<String, int>> items, // [{producto_id, cantidad}]
    int? direccionId,
    required String tipoEntrega, // domicilio | retiro
    required String metodoPago, // efectivo | tarjeta
  }) async {
    final r = await dio.post(ApiEndpoints.pedidos, data: {
      'items': items,
      'direccion_id': direccionId,
      'tipo_entrega': tipoEntrega,
      'metodo_pago': metodoPago,
      'canal': 'app_movil',
    });
    return Pedido.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<Pedido>> misPedidos() async =>
      _list((await dio.get(ApiEndpoints.misPedidos)).data);

  Future<List<Pedido>> todos() async => _list((await dio.get(ApiEndpoints.pedidos)).data);

  Future<void> cancelar(int id) => dio.post(ApiEndpoints.cancelarPedido(id));

  Future<void> cambiarEstado(int id, String estado) =>
      dio.patch(ApiEndpoints.estadoPedido(id), data: {'estado': estado});
}