import 'package:flutter_test/flutter_test.dart';
import 'package:minimarket/features/addresses/data/models/direccion_models.dart';
import 'package:minimarket/features/catalog/data/models/catalogo_models.dart';
import 'package:minimarket/features/orders/data/models/pedido_models.dart';

void main() {
  test('parses the deployed order response and nested delivery fields', () {
    final order = Pedido.fromJson({
      'id_pedido': 12,
      'canal': 'APP',
      'estado': 'EN_RUTA',
      'tipo_entrega': 'DOMICILIO',
      'metodo_pago': 'CONTRA_ENTREGA',
      'estado_pago': 'PENDIENTE',
      'costo_envio': 1.5,
      'total': 5.5,
      'cliente': {'nombre_completo': 'Ana Pérez'},
      'destino': {'detalle_direccion': 'Colonia Centro'},
      'detalles': [
        {
          'id_producto': 3,
          'nombre_producto': 'Leche',
          'cantidad': 2,
          'precio_unitario': 2,
          'subtotal': 4,
        },
      ],
    });

    expect(order.id, 12);
    expect(order.estado, 'en_ruta');
    expect(order.clienteNombre, 'Ana Pérez');
    expect(order.direccion, 'Colonia Centro');
    expect(order.detalles.single.productoId, 3);
  });

  test('parses address coordinates and per-branch product availability', () {
    final address = Direccion.fromJson({
      'id_direccion': 8,
      'id_municipio': 2,
      'detalle_direccion': 'Colonia Centro',
      'latitud': 13.69,
      'longitud': -89.21,
    });
    final availability = Disponibilidad.fromJson({
      'id_sucursal': 4,
      'nombre_sucursal': 'Centro',
      'stock_disponible': 9,
    });

    expect(address.latitud, 13.69);
    expect(address.longitud, -89.21);
    expect(availability.sucursalId, 4);
    expect(availability.stockDisponible, 9);
  });
}
