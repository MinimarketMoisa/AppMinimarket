import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login(String email, String password);
  Future<String?> register({
    required String nombreCompleto,
    required String email,
    required String password,
    String? telefono,
  });
  Future<String> applyAsCourier({
    required String nombreCompleto,
    required String email,
    required String password,
    required String telefono,
    String? placaVehiculo,
  });
  Future<bool> isEmailVerified(String email);
  Future<String> resendVerification(String email);
  Future<String> requestPasswordReset(String email);
  Future<String> requestEmailChange({
    required String newEmail,
    required String password,
  });
  Future<String> confirmEmailChange(String token);
  Future<UserEntity?> currentUser();
  Future<void> logout();
}
