import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../models/pedido_models.dart';

class OrdersRepository {
  final Dio dio;
  OrdersRepository(this.dio);

  List<Pedido> _list(dynamic data) => (data as List)
      .map((e) => Pedido.fromJson(e as Map<String, dynamic>))
      .toList();

  Future<Pedido> crear({
    required List<Map<String, int>> items, // [{id_producto, cantidad}]
    int? direccionId,
    int? sucursalId,
    required String tipoEntrega, // DOMICILIO | RETIRO
    required String metodoPago, // CONTRA_ENTREGA | TRANSFERENCIA | TARJETA
  }) async {
    final r = await dio.post(
      ApiEndpoints.pedidos,
      data: {
        'items': items,
        'id_direccion': direccionId,
        'id_sucursal': sucursalId,
        'tipo_entrega': tipoEntrega.toUpperCase(),
        'metodo_pago': metodoPago.toUpperCase(),
        'canal': 'APP',
      },
    );
    return Pedido.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<Pedido>> misPedidos() async =>
      _list((await dio.get(ApiEndpoints.misPedidos)).data);

  Future<Pedido> pedidoPorCodigo(String codigo) async {
    final response = await dio.get(ApiEndpoints.pedidoPorCodigo(codigo));
    return Pedido.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> cancelar(int id) => cambiarEstado(id, 'CANCELADO');

  Future<void> cambiarEstado(int id, String estado) => dio.patch(
    ApiEndpoints.estadoPedido(id),
    data: {'estado': estado.toUpperCase()},
  );

  Future<Map<String, dynamic>> seguimiento(int id) async =>
      (await dio.get(ApiEndpoints.seguimientoPedido(id))).data
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> simularPagoWompi({
    required int pedidoId,
    required String numeroTarjeta,
    required String nombreTitular,
    required String mesExpiracion,
    required String anioExpiracion,
    required String cvv,
    required String emailPagador,
  }) async {
    final response = await dio.post(
      ApiEndpoints.simularPagoWompi,
      data: {
        'id_pedido': pedidoId,
        'numero_tarjeta': numeroTarjeta,
        'nombre_titular': nombreTitular,
        'mes_expiracion': mesExpiracion,
        'anio_expiracion': anioExpiracion,
        'cvv': cvv,
        'email_pagador': emailPagador,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<dynamic> tarjetasPruebaWompi() async =>
      (await dio.get(ApiEndpoints.tarjetasPrueba)).data;

  Future<void> reenviarFactura(int id) async {
    await dio.post(ApiEndpoints.enviarFactura(id));
  }

  Future<void> denunciarRepartidor(int id, String motivo) async {
    await dio.post(
      ApiEndpoints.denunciarRepartidor(id),
      data: {'motivo': motivo},
    );
  }
}
