import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimarket/core/utils/helpers.dart';

void main() {
  DioException responseError(int statusCode) => DioException(
    requestOptions: RequestOptions(path: '/auth/login'),
    response: Response(
      requestOptions: RequestOptions(path: '/auth/login'),
      statusCode: statusCode,
    ),
    type: DioExceptionType.badResponse,
  );

  test('shows a clear service error without exposing an HTTP code', () {
    final message = errorMessage(responseError(502));

    expect(message, contains('problema temporal con el servicio'));
    expect(message, isNot(contains('502')));
    expect(message, isNot(contains('validateStatus')));
  });

  test('keeps authentication and authorization errors distinct', () {
    expect(errorMessage(responseError(401)), contains('correo y contraseña'));
    expect(errorMessage(responseError(403)), contains('verificación'));
  });

  test('does not expose raw API validation details or status codes', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/pedidos'),
      response: Response(
        requestOptions: RequestOptions(path: '/pedidos'),
        statusCode: 422,
        data: {
          'detail': [
            {'loc': ['body', 'items'], 'msg': 'Field required'},
          ],
        },
      ),
      type: DioExceptionType.badResponse,
    );
    final message = errorMessage(error);

    expect(message, contains('Algunos datos no son válidos'));
    expect(message, isNot(contains('422')));
    expect(message, isNot(contains('Field required')));
  });
}
