class UserEntity {
  final int id;
  final String nombreCompleto;
  final String email;
  final String? telefono;
  final String rol; // cliente | repartidor

  const UserEntity({
    required this.id,
    required this.nombreCompleto,
    required this.email,
    this.telefono,
    required this.rol,
  });
}
