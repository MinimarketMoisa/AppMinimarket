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

  test('shows a clear service error for gateway/server failures', () {
    final message = errorMessage(responseError(502));

    expect(message, contains('servidor de Minimarket'));
    expect(message, contains('HTTP 502'));
    expect(message, isNot(contains('validateStatus')));
  });

  test('keeps authentication and authorization errors distinct', () {
    expect(errorMessage(responseError(401)), contains('Correo o contraseña'));
    expect(errorMessage(responseError(403)), contains('no tiene permiso'));
  });
}
