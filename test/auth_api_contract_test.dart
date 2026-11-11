import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimarket/core/network/api_endpoints.dart';
import 'package:minimarket/core/network/mock_api_interceptor.dart';

void main() {
  late Dio dio;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://minimarket-api.duckdns.org'));
    dio.interceptors.add(MockApiInterceptor());
  });

  test('verification status is queried by email', () async {
    final response = await dio.get(
      ApiEndpoints.verificationStatus,
      queryParameters: {'email': 'cliente@demo.com'},
    );

    expect(response.data, {
      'email': 'cliente@demo.com',
      'email_verificado': true,
      'activo': true,
    });
  });

  test(
    'email change requires an authenticated request and confirmation code',
    () async {
      final login = await dio.post(
        ApiEndpoints.login,
        data: {'username': 'cliente@demo.com', 'password': '123456'},
      );
      dio.options.headers['Authorization'] =
          'Bearer ${login.data['access_token']}';

      final requested = await dio.post(
        ApiEndpoints.requestEmailChange,
        data: {'nuevo_email': 'nuevo@demo.com', 'password': '123456'},
      );
      expect(requested.data['mensaje'], contains('Código enviado'));

      await dio.post(
        ApiEndpoints.confirmEmailChange,
        data: {'token': 'mock-email-change-1'},
      );
      final user = await dio.get(ApiEndpoints.me);
      expect(user.data['email'], 'nuevo@demo.com');
    },
  );
}
