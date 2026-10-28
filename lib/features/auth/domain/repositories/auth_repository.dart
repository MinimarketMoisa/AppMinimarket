import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login(String email, String password);
  Future<String?> register({
    required String nombreCompleto,
    required String email,
    required String password,
    String? telefono,
  });
  Future<String> verifyEmail(String token);
  Future<String> resendVerification(String email);
  Future<UserEntity?> currentUser();
  Future<void> logout();
}
