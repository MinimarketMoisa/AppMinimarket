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

  Future<void> register({
    required String nombreCompleto,
    required String email,
    required String password,
    String? telefono,
  }) async {
    await dio.post(ApiEndpoints.register, data: {
      'nombre_completo': nombreCompleto,
      'email': email,
      'password': password,
      'telefono': telefono,
    });
  }

  Future<UserModel> me() async {
    final r = await dio.get(ApiEndpoints.me);
    return UserModel.fromJson(r.data as Map<String, dynamic>);
  }
}