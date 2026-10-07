import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.nombreCompleto,
    required super.email,
    super.telefono,
    required super.rol,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'],
        nombreCompleto: j['nombre_completo'] ?? '',
        email: j['email'] ?? '',
        telefono: j['telefono'],
        rol: j['rol'] ?? 'cliente',
      );
}