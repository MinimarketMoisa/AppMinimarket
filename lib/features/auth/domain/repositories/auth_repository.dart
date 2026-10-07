import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login(String email, String password);
  Future<UserEntity> register({
    required String nombreCompleto,
    required String email,
    required String password,
    String? telefono,
  });
  Future<UserEntity?> currentUser();
  Future<void> logout();
}