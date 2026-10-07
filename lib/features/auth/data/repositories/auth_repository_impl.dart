import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final TokenStorage _storage;
  AuthRepositoryImpl(this._remote, this._storage);

  @override
  Future<UserEntity> login(String email, String password) async {
    final token = await _remote.login(email, password);
    await _storage.save(token);
    return _remote.me();
  }

  @override
  Future<UserEntity> register({
    required String nombreCompleto,
    required String email,
    required String password,
    String? telefono,
  }) async {
    await _remote.register(
        nombreCompleto: nombreCompleto, email: email, password: password, telefono: telefono);
    return login(email, password);
  }

  @override
  Future<UserEntity?> currentUser() async {
    final token = await _storage.read();
    if (token == null) return null;
    try {
      return await _remote.me();
    } catch (_) {
      await _storage.clear();
      return null;
    }
  }

  @override
  Future<void> logout() => _storage.clear();
}