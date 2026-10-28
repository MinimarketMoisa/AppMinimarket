import '../../../../core/utils/helpers.dart';

class DetallePedido {
  final int productoId;
  final String nombreProducto;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  const DetallePedido({
    required this.productoId,
    required this.nombreProducto,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory DetallePedido.fromJson(Map<String, dynamic> j) => DetallePedido(
    productoId: j['id_producto'] ?? j['producto_id'],
    nombreProducto: j['nombre_producto'] ?? '',
    cantidad: j['cantidad'],
    precioUnitario: toDouble(j['precio_unitario']),
    subtotal: toDouble(j['subtotal']),
  );
}

class Pedido {
  final int id;
  final String canal;
  final DateTime? fechaCreacion;
  final String estado;
  final String tipoEntrega;
  final String metodoPago;
  final String estadoPago;
  final double costoEnvio;
  final double total;
  final String? direccion;
  final String? clienteNombre;
  final List<DetallePedido> detalles;

  const Pedido({
    required this.id,
    required this.canal,
    this.fechaCreacion,
    required this.estado,
    required this.tipoEntrega,
    required this.metodoPago,
    required this.estadoPago,
    required this.costoEnvio,
    required this.total,
    this.direccion,
    this.clienteNombre,
    required this.detalles,
  });

  factory Pedido.fromJson(Map<String, dynamic> j) => Pedido(
    id: j['id_pedido'] ?? j['id'],
    canal: j['canal'] ?? '',
    fechaCreacion: DateTime.tryParse('${j['fecha_creacion']}'),
    estado: (j['estado'] ?? 'pendiente').toString().toLowerCase(),
    tipoEntrega: (j['tipo_entrega'] ?? '').toString().toLowerCase(),
    metodoPago: (j['metodo_pago'] ?? '').toString().toLowerCase(),
    estadoPago: (j['estado_pago'] ?? '').toString().toLowerCase(),
    costoEnvio: toDouble(j['costo_envio']),
    total: toDouble(j['total']),
    direccion:
        j['direccion'] ??
        (j['destino'] is Map<String, dynamic>
            ? (j['destino'] as Map<String, dynamic>)['detalle_direccion']
            : null),
    clienteNombre:
        j['cliente_nombre'] ??
        (j['cliente'] is Map<String, dynamic>
            ? (j['cliente'] as Map<String, dynamic>)['nombre_completo']
            : null),
    detalles: ((j['detalles'] ?? []) as List)
        .map((e) => DetallePedido.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
