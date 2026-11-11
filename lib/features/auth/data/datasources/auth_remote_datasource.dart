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
    final requestData = <String, dynamic>{
      'nombre_completo': nombreCompleto,
      'email': email,
      'password': password,
    };
    if (telefono != null && telefono.trim().isNotEmpty) {
      requestData['telefono'] = telefono.trim();
    }
    final response = await dio.post(ApiEndpoints.register, data: requestData);
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
        ? data['mensaje']?.toString() ?? 'Solicitud enviada para revisión.'
        : 'Solicitud enviada para revisión.';
  }

  Future<bool> isEmailVerified(String email) async {
    final response = await dio.get(
      ApiEndpoints.verificationStatus,
      queryParameters: {'email': email},
    );
    final data = response.data;
    if (data is! Map || data['email_verificado'] is! bool) {
      throw const FormatException(
        'La respuesta de verificación del correo no es válida.',
      );
    }
    return data['email_verificado'] as bool;
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
        ? data['mensaje']?.toString() ?? 'Si el correo está registrado, recibirás instrucciones para recuperar tu contraseña.'
        : 'Si el correo está registrado, recibirás instrucciones para recuperar tu contraseña.';
  }

  Future<String> requestEmailChange({
    required String newEmail,
    required String password,
  }) async {
    final response = await dio.post(
      ApiEndpoints.requestEmailChange,
      data: {'nuevo_email': newEmail, 'password': password},
    );
    final data = response.data;
    return data is Map
        ? data['mensaje']?.toString() ?? 'Código enviado al nuevo correo.'
        : 'Código enviado al nuevo correo.';
  }

  Future<String> confirmEmailChange(String token) async {
    final response = await dio.post(
      ApiEndpoints.confirmEmailChange,
      data: {'token': token},
    );
    final data = response.data;
    return data is Map
        ? data['mensaje']?.toString() ?? 'Correo actualizado correctamente.'
        : 'Correo actualizado correctamente.';
  }

  Future<UserModel> me() async {
    final r = await dio.get(ApiEndpoints.me);
    return UserModel.fromJson(r.data as Map<String, dynamic>);
  }
}
