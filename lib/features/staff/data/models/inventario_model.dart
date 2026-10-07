class Inventario {
  final int id;
  final int productoId;
  final String productoNombre;
  final int stockDisponible;
  final String? fechaVencimiento;

  const Inventario({
    required this.id,
    required this.productoId,
    required this.productoNombre,
    required this.stockDisponible,
    this.fechaVencimiento,
  });

  factory Inventario.fromJson(Map<String, dynamic> j) => Inventario(
        id: j['id'],
        productoId: j['producto_id'],
        productoNombre: j['producto_nombre'] ?? 'Producto ${j['producto_id']}',
        stockDisponible: j['stock_disponible'],
        fechaVencimiento: j['fecha_vencimiento'],
      );
}