import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimarket/core/network/mock_api_interceptor.dart';
import 'package:minimarket/features/catalog/data/repositories/catalog_repository.dart';

void main() {
  late Dio dio;
  late CatalogRepository repository;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://mock.minimarket.test'));
    dio.interceptors.add(MockApiInterceptor());
    repository = CatalogRepository(dio);
  });

  tearDown(() => dio.close());

  test('accepts a cart covered by one selected branch', () async {
    await expectLater(
      repository.validarInventarioPedido(
        cantidades: {1: 2, 7: 1},
        sucursalesCandidatas: {1},
      ),
      completes,
    );
  });

  test('rejects a cart that exceeds stock at its selected branch', () async {
    await expectLater(
      repository.validarInventarioPedido(
        cantidades: {1: 100000},
        sucursalesCandidatas: {1},
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('existencias suficientes'),
        ),
      ),
    );
  });

  test('loads product details from the public product endpoint', () async {
    final product = await repository.productoPorId(1);

    expect(product.id, 1);
    expect(product.nombre, 'Coca-Cola 600ml');
    expect(product.precioBase, 1);
    expect(product.activo, isTrue);
  });
}
