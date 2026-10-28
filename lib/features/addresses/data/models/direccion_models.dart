class Municipio {
  final int id;
  final String nombre;
  const Municipio({required this.id, required this.nombre});
  factory Municipio.fromJson(Map<String, dynamic> j) =>
      Municipio(id: j['id_municipio'] ?? j['id'], nombre: j['nombre'] ?? '');
}

class Direccion {
  final int id;
  final String detalleDireccion;
  final String? puntoReferencia;
  final int municipioId;
  final String? municipioNombre;
  final double? latitud;
  final double? longitud;

  const Direccion({
    required this.id,
    required this.detalleDireccion,
    this.puntoReferencia,
    required this.municipioId,
    this.municipioNombre,
    this.latitud,
    this.longitud,
  });

  factory Direccion.fromJson(Map<String, dynamic> j) => Direccion(
    id: j['id_direccion'] ?? j['id'],
    detalleDireccion: j['detalle_direccion'] ?? '',
    puntoReferencia: j['punto_referencia'],
    municipioId: j['id_municipio'] ?? j['municipio_id'],
    municipioNombre: j['municipio_nombre'],
    latitud: j['latitud'] == null ? null : double.tryParse('${j['latitud']}'),
    longitud: j['longitud'] == null
        ? null
        : double.tryParse('${j['longitud']}'),
  );

  String get resumen =>
      '$detalleDireccion${municipioNombre != null ? ', $municipioNombre' : ''}';
}
