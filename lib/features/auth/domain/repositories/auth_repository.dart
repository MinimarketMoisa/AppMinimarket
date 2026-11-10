import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login(String email, String password);
  Future<String?> register({
    required String nombreCompleto,
    required String email,
    required String password,
    required String telefono,
  });
  Future<String> applyAsCourier({
    required String nombreCompleto,
    required String email,
    required String password,
    required String telefono,
    String? placaVehiculo,
  });
  Future<String> verifyEmail(String token);
  Future<String> resendVerification(String email);
  Future<String> requestPasswordReset(String email);
  Future<String> resetPassword({
    required String token,
    required String password,
  });
  Future<UserEntity?> currentUser();
  Future<void> logout();
}
