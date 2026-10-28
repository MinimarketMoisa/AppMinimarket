import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final Dio dio;
  AuthRemoteDataSource(this.dio);

  /// FastAPI (OAuth2PasswordRequestForm) espera form-urlencoded con "username".
  Future<String> login(String email, String password) async {
    final r = await dio.post(
      ApiEndpoints.login,
      data: {'username': email, 'password': password},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    return r.data['access_token'] as String;
  }

  Future<String?> register({
    required String nombreCompleto,
    required String email,
    required String password,
    String? telefono,
  }) async {
    final response = await dio.post(
      ApiEndpoints.register,
      data: {
        'nombre_completo': nombreCompleto,
        'email': email,
        'password': password,
        'telefono': telefono,
      },
    );
    final data = response.data;
    return data is Map ? data['mensaje']?.toString() : null;
  }

  Future<String> verifyEmail(String token) async {
    final response = await dio.post(
      ApiEndpoints.verifyEmail,
      data: {'token': token},
    );
    final data = response.data;
    return data is Map
        ? data['mensaje']?.toString() ?? 'Correo verificado correctamente.'
        : 'Correo verificado correctamente.';
  }

  Future<String> resendVerification(String email) async {
    final response = await dio.post(
      ApiEndpoints.resendVerification,
      data: {'email': email},
    );
    final data = response.data;
    return data is Map
        ? data['mensaje']?.toString() ?? 'Solicitud procesada.'
        : 'Solicitud procesada.';
  }

  Future<UserModel> me() async {
    final r = await dio.get(ApiEndpoints.me);
    return UserModel.fromJson(r.data as Map<String, dynamic>);
  }
}
