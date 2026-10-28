import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _repo;
  LoginUseCase(this._repo);
  Future<UserEntity> call(String email, String password) =>
      _repo.login(email, password);
}

class RegisterUseCase {
  final AuthRepository _repo;
  RegisterUseCase(this._repo);
  Future<String?> call({
    required String nombreCompleto,
    required String email,
    required String password,
    String? telefono,
  }) => _repo.register(
    nombreCompleto: nombreCompleto,
    email: email,
    password: password,
    telefono: telefono,
  );
}

class VerifyEmailUseCase {
  final AuthRepository _repo;
  VerifyEmailUseCase(this._repo);

  Future<String> call(String token) => _repo.verifyEmail(token);
}

class ResendVerificationUseCase {
  final AuthRepository _repo;
  ResendVerificationUseCase(this._repo);

  Future<String> call(String email) => _repo.resendVerification(email);
}

class GetCurrentUserUseCase {
  final AuthRepository _repo;
  GetCurrentUserUseCase(this._repo);
  Future<UserEntity?> call() => _repo.currentUser();
}

class LogoutUseCase {
  final AuthRepository _repo;
  LogoutUseCase(this._repo);
  Future<void> call() => _repo.logout();
}
