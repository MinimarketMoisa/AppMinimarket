import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepositoryImpl(
      AuthRemoteDataSource(ref.read(dioProvider)),
      ref.read(tokenStorageProvider),
    ));

final authProvider = AsyncNotifierProvider<AuthNotifier, UserEntity?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<UserEntity?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<UserEntity?> build() => GetCurrentUserUseCase(_repo)();

  /// Lanza excepción si falla (la pantalla muestra el mensaje).
  Future<void> login(String email, String password) async {
    final user = await LoginUseCase(_repo)(email, password);
    state = AsyncData(user);
  }

  Future<void> register({
    required String nombreCompleto,
    required String email,
    required String password,
    String? telefono,
  }) async {
    final user = await RegisterUseCase(_repo)(
        nombreCompleto: nombreCompleto, email: email, password: password, telefono: telefono);
    state = AsyncData(user);
  }

  Future<void> logout() async {
    await LogoutUseCase(_repo)();
    ref.read(cartProvider.notifier).clear();
    state = const AsyncData(null);
  }
}