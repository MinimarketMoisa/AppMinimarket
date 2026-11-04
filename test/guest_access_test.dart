import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimarket/core/network/api_endpoints.dart';
import 'package:minimarket/core/network/mock_api_interceptor.dart';

void main() {
  late Dio dio;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://mock.minimarket.test'));
    dio.interceptors.add(MockApiInterceptor());
  });

  tearDown(() => dio.close());

  test('guest can browse the public catalog', () async {
    final response = await dio.get(ApiEndpoints.productos);

    expect(response.statusCode, 200);
    expect(response.data, isA<List<dynamic>>());
    expect((response.data as List).isNotEmpty, isTrue);
  });

  test('guest cannot access customer addresses', () async {
    await expectLater(
      dio.get(ApiEndpoints.direcciones),
      throwsA(
        isA<DioException>().having(
          (error) => error.response?.statusCode,
          'statusCode',
          401,
        ),
      ),
    );
  });

  test('guest can submit a courier application', () async {
    final response = await dio.post(
      ApiEndpoints.solicitudRepartidor,
      data: {
        'nombre_completo': 'Repartidor de prueba',
        'email': 'repartidor.nuevo@example.com',
        'password': 'ClaveSegura123',
        'telefono': '70000000',
      },
    );

    expect(response.statusCode, 200);
    expect(response.data['id_solicitud'], isNotNull);
  });
}
