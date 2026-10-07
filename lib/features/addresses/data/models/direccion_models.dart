class Municipio {
  final int id;
  final String nombre;
  const Municipio({required this.id, required this.nombre});
  factory Municipio.fromJson(Map<String, dynamic> j) =>
      Municipio(id: j['id'], nombre: j['nombre'] ?? '');
}

class Direccion {
  final int id;
  final String detalleDireccion;
  final String? puntoReferencia;
  final int municipioId;
  final String? municipioNombre;

  const Direccion({
    required this.id,
    required this.detalleDireccion,
    this.puntoReferencia,
    required this.municipioId,
    this.municipioNombre,
  });

  factory Direccion.fromJson(Map<String, dynamic> j) => Direccion(
        id: j['id'],
        detalleDireccion: j['detalle_direccion'] ?? '',
        puntoReferencia: j['punto_referencia'],
        municipioId: j['municipio_id'],
        municipioNombre: j['municipio_nombre'],
      );

  String get resumen => '$detalleDireccion${municipioNombre != null ? ', $municipioNombre' : ''}';
}