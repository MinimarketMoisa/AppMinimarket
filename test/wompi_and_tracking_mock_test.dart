import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimarket/core/network/api_endpoints.dart';
import 'package:minimarket/core/network/mock_api_interceptor.dart';

void main() {
  late Dio dio;

  Future<String> authenticate(String email) async {
    final response = await dio.post(
      ApiEndpoints.login,
      data: {'username': email, 'password': '123456'},
    );
    return response.data['access_token'] as String;
  }

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://minimarket-api.duckdns.org'));
    dio.interceptors.add(MockApiInterceptor());
  });

  test(
    'Wompi payment records approved cards and leaves declined cards unpaid',
    () async {
      final clientToken = await authenticate('cliente@demo.com');
      dio.options.headers['Authorization'] = 'Bearer $clientToken';

      final catalog = await dio.get(ApiEndpoints.tarjetasPrueba);
      expect(catalog.data, isA<List>());

      final order = await dio.post(
        ApiEndpoints.pedidos,
        data: {
          'items': [
            {'id_producto': 1, 'cantidad': 1},
          ],
          'id_direccion': 1,
          'tipo_entrega': 'DOMICILIO',
          'metodo_pago': 'TARJETA',
          'canal': 'APP',
        },
      );
      final orderId = order.data['id'] as int;
      final paymentFields = {
        'id_pedido': orderId,
        'nombre_titular': 'CLIENTE DEMO',
        'mes_expiracion': '12',
        'anio_expiracion': '2028',
        'cvv': '123',
        'email_pagador': 'cliente@demo.com',
      };

      final rejected = await dio.post(
        ApiEndpoints.simularPagoWompi,
        data: {...paymentFields, 'numero_tarjeta': '4000 0000 0000 0002'},
      );
      expect(rejected.data['estado_transaccion'], 'DECLINADA');

      final approved = await dio.post(
        ApiEndpoints.simularPagoWompi,
        data: {...paymentFields, 'numero_tarjeta': '4242 4242 4242 4242'},
      );
      expect(approved.data['estado_transaccion'], 'APROBADA');
      expect(
        (await dio.get(ApiEndpoints.misPedidos)).data
            .firstWhere((item) => item['id'] == orderId)['estado_pago'],
        'pagado',
      );
    },
  );

  test(
    'repartidor location updates persist heading and speed in tracking',
    () async {
      final courierToken = await authenticate('repartidor@demo.com');
      dio.options.headers['Authorization'] = 'Bearer $courierToken';
      await dio.patch(
        ApiEndpoints.repartidorUbicacion,
        data: {
          'latitud': 13.4875,
          'longitud': -88.1805,
          'rumbo': 142.0,
          'velocidad': 7.5,
        },
      );

      final clientToken = await authenticate('cliente@demo.com');
      dio.options.headers['Authorization'] = 'Bearer $clientToken';
      final tracking = await dio.get(ApiEndpoints.seguimientoPedido(1));
      expect(tracking.data['repartidor']['latitud'], 13.4875);
      expect(tracking.data['repartidor']['longitud'], -88.1805);
      expect(tracking.data['repartidor']['rumbo'], 142.0);
      expect(tracking.data['repartidor']['velocidad'], 7.5);
    },
  );

  test('password recovery requests the browser reset link', () async {
    final requested = await dio.post(
      ApiEndpoints.forgotPassword,
      data: {'email': 'cliente@demo.com'},
    );
    expect(requested.data['mensaje'], contains('Si el correo está registrado'));

    final response = await dio.post(
      ApiEndpoints.login,
      data: {'username': 'cliente@demo.com', 'password': '123456'},
    );
    expect(response.data['access_token'], 'mock-1');
  });

  test('catalog pagination and order codes match the deployed API', () async {
    final firstPage = await dio.get(
      ApiEndpoints.productos,
      queryParameters: {'skip': 0, 'limit': 3},
    );
    final secondPage = await dio.get(
      ApiEndpoints.productos,
      queryParameters: {'skip': 3, 'limit': 3},
    );
    expect(firstPage.data, hasLength(3));
    expect(secondPage.data, hasLength(3));
    expect(
      firstPage.data
          .map((item) => item['id'])
          .toSet()
          .intersection(secondPage.data.map((item) => item['id']).toSet()),
      isEmpty,
    );

    final clientToken = await authenticate('cliente@demo.com');
    dio.options.headers['Authorization'] = 'Bearer $clientToken';
    final created = await dio.post(
      ApiEndpoints.pedidos,
      data: {
        'items': [
          {'id_producto': 1, 'cantidad': 1},
        ],
        'id_direccion': 1,
        'tipo_entrega': 'DOMICILIO',
        'metodo_pago': 'CONTRA_ENTREGA',
        'canal': 'APP',
      },
    );
    final code = created.data['codigo_pedido'] as String;
    expect(code, matches(RegExp(r'^PED-\d{6}$')));
    final byCode = await dio.get(ApiEndpoints.pedidoPorCodigo(code));
    expect(byCode.data['codigo_pedido'], code);
    final tracking = await dio.get(
      ApiEndpoints.seguimientoPedido(created.data['id_pedido'] as int),
    );
    expect(tracking.data['codigo_pedido'], code);
  });

  test(
    'courier can accept consecutive assigned orders without mixing queues',
    () async {
      final clientToken = await authenticate('cliente@demo.com');
      dio.options.headers['Authorization'] = 'Bearer $clientToken';
      final orderData = {
        'items': [
          {'id_producto': 1, 'cantidad': 1},
        ],
        'id_direccion': 1,
        'tipo_entrega': 'DOMICILIO',
        'metodo_pago': 'CONTRA_ENTREGA',
        'canal': 'APP',
      };
      final firstCreated = await dio.post(
        ApiEndpoints.pedidos,
        data: orderData,
      );
      final secondCreated = await dio.post(
        ApiEndpoints.pedidos,
        data: orderData,
      );
      final firstId = firstCreated.data['id_pedido'] as int;
      final secondId = secondCreated.data['id_pedido'] as int;

      final courierToken = await authenticate('repartidor@demo.com');
      dio.options.headers['Authorization'] = 'Bearer $courierToken';
      final incoming = await dio.get(ApiEndpoints.repartidorEntrante);
      expect(incoming.data['id_pedido'], firstId);

      await dio.post(ApiEndpoints.aceptarPedidoRepartidor(firstId));
      final nextIncoming = await dio.get(ApiEndpoints.repartidorEntrante);
      expect(nextIncoming.data['id_pedido'], secondId);

      await dio.post(ApiEndpoints.aceptarPedidoRepartidor(secondId));
      final assigned = await dio.get(
        ApiEndpoints.repartidorPedidos,
        queryParameters: {'estado_repartidor': 'ACEPTADO'},
      );
      expect(
        (assigned.data as List).map((order) => order['id_pedido']),
        containsAll([firstId, secondId]),
      );
      expect(
        (assigned.data as List).every(
          (order) => order['estado_repartidor'] == 'ACEPTADO',
        ),
        isTrue,
      );
    },
  );
}
