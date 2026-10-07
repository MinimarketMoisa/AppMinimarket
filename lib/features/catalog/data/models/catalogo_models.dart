import '../../../../core/utils/helpers.dart';

class Categoria {
  final int id;
  final String nombre;
  final String? descripcion;
  const Categoria({required this.id, required this.nombre, this.descripcion});

  factory Categoria.fromJson(Map<String, dynamic> j) =>
      Categoria(id: j['id'], nombre: j['nombre'] ?? '', descripcion: j['descripcion']);
}

class Producto {
  final int id;
  final String? codigoBarras;
  final String nombre;
  final String? descripcion;
  final double precioBase;
  final String? imagenUrl;
  final bool activo;
  final int? categoriaId;

  const Producto({
    required this.id,
    this.codigoBarras,
    required this.nombre,
    this.descripcion,
    required this.precioBase,
    this.imagenUrl,
    this.activo = true,
    this.categoriaId,
  });

  factory Producto.fromJson(Map<String, dynamic> j) => Producto(
        id: j['id'],
        codigoBarras: j['codigo_barras'],
        nombre: j['nombre'] ?? '',
        descripcion: j['descripcion'],
        precioBase: toDouble(j['precio_base']),
        imagenUrl: j['imagen_url'],
        activo: j['activo'] ?? true,
        categoriaId: j['categoria_id'],
      );
}