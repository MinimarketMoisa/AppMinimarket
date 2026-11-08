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

  Future<String> applyAsCourier({
    required String nombreCompleto,
    required String email,
    required String password,
    required String telefono,
    String? placaVehiculo,
  }) async {
    final response = await dio.post(
      ApiEndpoints.solicitudRepartidor,
      data: {
        'nombre_completo': nombreCompleto,
        'email': email,
        'password': password,
        'telefono': telefono,
        'placa_vehiculo': placaVehiculo,
      },
    );
    final data = response.data;
    return data is Map
        ? data['mensaje']?.toString() ??
              'Solicitud enviada para revisión.'
        : 'Solicitud enviada para revisión.';
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

  Future<String> requestPasswordReset(String email) async {
    final response = await dio.post(
      ApiEndpoints.forgotPassword,
      data: {'email': email},
    );
    final data = response.data;
    return data is Map
        ? data['mensaje']?.toString() ??
              'Si el correo está registrado, recibirás instrucciones para recuperar tu contraseña.'
        : 'Si el correo está registrado, recibirás instrucciones para recuperar tu contraseña.';
  }

  Future<String> resetPassword({
    required String token,
    required String password,
  }) async {
    final response = await dio.post(
      ApiEndpoints.resetPassword,
      data: {'token': token, 'password': password},
    );
    final data = response.data;
    return data is Map
        ? data['mensaje']?.toString() ?? 'Tu contraseña fue actualizada.'
        : 'Tu contraseña fue actualizada.';
  }

  Future<UserModel> me() async {
    final r = await dio.get(ApiEndpoints.me);
    return UserModel.fromJson(r.data as Map<String, dynamic>);
  }
}
