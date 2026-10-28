import 'package:dio/dio.dart';

import 'api_endpoints.dart';

/// Simula la API en memoria. Se activa con AppConfig.useMock = true.
/// Cuando la API real exista, pon useMock = false y listo.
class _MockError implements Exception {
  final int code;
  final String msg;
  _MockError(this.code, this.msg);
}

class MockApiInterceptor extends Interceptor {
  int _nextUser = 4, _nextDir = 3, _nextPedido = 1;
  String _estadoRepartidor = 'LIBRE';

  final List<Map<String, dynamic>> _users = [
    {
      'id': 1,
      'nombre_completo': 'Cliente Demo',
      'email': 'cliente@demo.com',
      'password': '123456',
      'telefono': '7000-0001',
      'rol': 'cliente',
    },
    {
      'id': 3,
      'nombre_completo': 'Repartidor Demo',
      'email': 'repartidor@demo.com',
      'password': '123456',
      'telefono': '7000-0003',
      'rol': 'repartidor',
    },
  ];

  final List<Map<String, dynamic>> _sucursales = [
    {'id_sucursal': 1, 'nombre': 'Minimarket San Miguel', 'direccion': 'San Miguel'},
    {'id_sucursal': 2, 'nombre': 'Minimarket Moncagua', 'direccion': 'Moncagua'},
  ];

  final List<Map<String, dynamic>> _categorias = [
    {'id': 1, 'nombre': 'Bebidas', 'descripcion': 'Gaseosas, jugos y agua'},
    {'id': 2, 'nombre': 'Lácteos', 'descripcion': 'Leche, queso y yogurt'},
    {'id': 3, 'nombre': 'Panadería', 'descripcion': 'Pan y repostería'},
    {'id': 4, 'nombre': 'Snacks', 'descripcion': 'Galletas y botanas'},
    {'id': 5, 'nombre': 'Limpieza', 'descripcion': 'Hogar y limpieza'},
  ];

  static Map<String, dynamic> _p(int id, String n, double precio, int cat) => {
    'id': id,
    'codigo_barras': '74100000$id',
    'nombre': n,
    'descripcion': n,
    'precio_base': precio,
    'imagen_url': null,
    'activo': true,
    'categoria_id': cat,
  };

  late final List<Map<String, dynamic>> _productos = [
    _p(1, 'Coca-Cola 600ml', 1.00, 1),
    _p(2, 'Agua purificada 1L', 0.75, 1),
    _p(3, 'Jugo de naranja 1L', 1.80, 1),
    _p(4, 'Leche entera 1L', 1.25, 2),
    _p(5, 'Queso fresco 250g', 2.10, 2),
    _p(6, 'Yogurt natural 500g', 1.60, 2),
    _p(7, 'Pan francés (6 uds)', 1.00, 3),
    _p(8, 'Galletas de chocolate', 0.90, 4),
    _p(9, 'Papas fritas 150g', 1.35, 4),
    _p(10, 'Detergente 1kg', 3.50, 5),
  ];

  late final List<Map<String, dynamic>> _inventario = [
    for (final p in _productos)
      {
        'id': p['id'],
        'id_sucursal': 1,
        'id_producto': p['id'],
        'nombre_producto': p['nombre'],
        'stock_disponible': 20 + (p['id'] as int) * 3,
        'fecha_vencimiento': '2026-12-31',
      },
  ];

  final List<Map<String, dynamic>> _municipios = [
    {'id': 1, 'nombre': 'San Miguel'},
    {'id': 2, 'nombre': 'Moncagua'},
    {'id': 3, 'nombre': 'Chinameca'},
  ];

  final List<Map<String, dynamic>> _direcciones = [
    {
      'id': 1,
      'cliente_id': 1,
      'detalle_direccion': 'Col. Centro, Calle Principal #12',
      'punto_referencia': 'Frente al parque',
      'municipio_id': 1,
    },
    {
      'id': 2,
      'cliente_id': 1,
      'detalle_direccion': 'Res. Los Pinos, Casa 8',
      'punto_referencia': 'Portón negro',
      'municipio_id': 2,
    },
  ];

  final List<Map<String, dynamic>> _pedidos = [];

  MockApiInterceptor() {
    _pedidos.add(
      _nuevoPedido(
        clienteId: 1,
        items: [
          {'producto_id': 1, 'cantidad': 2},
          {'producto_id': 7, 'cantidad': 1},
        ],
        direccionId: 1,
        tipoEntrega: 'domicilio',
        metodoPago: 'efectivo',
        estado: 'preparado',
      ),
    );
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    await Future.delayed(const Duration(milliseconds: 350));
    try {
      final data = _route(options);
      handler.resolve(
        Response(requestOptions: options, statusCode: 200, data: data),
      );
    } on _MockError catch (e) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: options,
            statusCode: e.code,
            data: {'detail': e.msg},
          ),
        ),
      );
    }
  }

  // ---------- helpers ----------
  Map<String, dynamic>? _currentUser(RequestOptions o) {
    final h = o.headers['Authorization']?.toString() ?? '';
    if (!h.startsWith('Bearer mock-')) return null;
    final id = int.tryParse(h.substring(12));
    for (final u in _users) {
      if (u['id'] == id) return u;
    }
    return null;
  }

  Map<String, dynamic> _publicUser(Map<String, dynamic> u) =>
      Map<String, dynamic>.from(u)..remove('password');

  String _municipio(int id) =>
      _municipios.firstWhere((m) => m['id'] == id)['nombre'] as String;

  Map<String, dynamic> _dirJson(Map<String, dynamic> d) => {
    ...d,
    'id_direccion': d['id'],
    'id_municipio': d['municipio_id'],
    'municipio_nombre': _municipio(d['municipio_id'] as int),
  };

  String? _direccionTexto(int? id) {
    if (id == null) return null;
    final d = _direcciones.firstWhere(
      (d) => d['id'] == id,
      orElse: () => throw _MockError(404, 'Dirección no encontrada'),
    );
    return '${d['detalle_direccion']}, ${_municipio(d['municipio_id'] as int)}';
  }

  Map<String, dynamic> _nuevoPedido({
    required int clienteId,
    required List items,
    int? direccionId,
    required String tipoEntrega,
    required String metodoPago,
    String estado = 'pendiente',
  }) {
    final detalles = <Map<String, dynamic>>[];
    var subtotal = 0.0;
    for (final it in items) {
      final p = _productos.firstWhere(
        (p) => p['id'] == (it['id_producto'] ?? it['producto_id']),
        orElse: () => throw _MockError(404, 'Producto no existe'),
      );
      final cant = it['cantidad'] as int;
      final inv = _inventario.firstWhere((i) => i['id_producto'] == p['id']);
      if ((inv['stock_disponible'] as int) < cant) {
        throw _MockError(400, 'Stock insuficiente de ${p['nombre']}');
      }
      inv['stock_disponible'] = (inv['stock_disponible'] as int) - cant;
      final st = (p['precio_base'] as double) * cant;
      subtotal += st;
      detalles.add({
        'producto_id': p['id'],
        'nombre_producto': p['nombre'],
        'cantidad': cant,
        'precio_unitario': p['precio_base'],
        'subtotal': st,
      });
    }
    final domicilio = tipoEntrega == 'domicilio';
    final envio = domicilio ? 2.0 : 0.0;
    final cliente = _users.firstWhere((u) => u['id'] == clienteId);
    return {
      'id': _nextPedido++,
      'cliente_id': clienteId,
      'cliente_nombre': cliente['nombre_completo'],
      'repartidor_id': domicilio ? 3 : null,
      'canal': 'app_movil',
      'fecha_creacion': DateTime.now().toIso8601String(),
      'estado': estado,
      'tipo_entrega': tipoEntrega,
      'metodo_pago': metodoPago,
      'estado_pago': metodoPago == 'tarjeta' ? 'pagado' : 'pendiente',
      'costo_envio': envio,
      'total': subtotal + envio,
      'direccion': domicilio ? _direccionTexto(direccionId) : null,
      'direccion_id': direccionId,
      'detalles': detalles,
    };
  }

  Map<String, dynamic> _pedido(int id) => _pedidos.firstWhere(
    (p) => p['id'] == id,
    orElse: () => throw _MockError(404, 'Pedido no encontrado'),
  );

  // ---------- rutas ----------
  dynamic _route(RequestOptions o) {
    final path = o.path;
    final m = o.method.toUpperCase();
    final body = o.data is Map
        ? Map<String, dynamic>.from(o.data as Map)
        : <String, dynamic>{};
    final q = o.queryParameters;

    if (path == ApiEndpoints.login && m == 'POST') {
      final found = _users.where(
        (u) =>
            u['email'] == body['username'] && u['password'] == body['password'],
      );
      if (found.isEmpty) {
        throw _MockError(401, 'Correo o contraseña incorrectos');
      }
      return {
        'access_token': 'mock-${found.first['id']}',
        'token_type': 'bearer',
      };
    }
    if (path == ApiEndpoints.register && m == 'POST') {
      if (_users.any((u) => u['email'] == body['email'])) {
        throw _MockError(400, 'El correo ya está registrado');
      }
      final u = {
        'id': _nextUser++,
        'nombre_completo': body['nombre_completo'],
        'email': body['email'],
        'password': body['password'],
        'telefono': body['telefono'],
        'rol': 'cliente',
      };
      _users.add(u);
      return _publicUser(u);
    }

    final me = _currentUser(o);
    if (me == null) throw _MockError(401, 'No autenticado');

    if (path == ApiEndpoints.me) return _publicUser(me);
    if (path == ApiEndpoints.categorias) return _categorias;
    if (path == ApiEndpoints.productos) {
      final cat = int.tryParse('${q['id_categoria'] ?? q['categoria_id'] ?? ''}');
      final txt = '${q['q'] ?? ''}'.toLowerCase();
      return _productos
          .where((p) => cat == null || p['categoria_id'] == cat)
          .where(
            (p) =>
                txt.isEmpty ||
                (p['nombre'] as String).toLowerCase().contains(txt),
          )
          .toList();
    }
    if (path == ApiEndpoints.municipios) return _municipios;
    if (path == ApiEndpoints.sucursales) return _sucursales;
    if (path == ApiEndpoints.direcciones) {
      if (m == 'POST') {
        final d = {
          'id': _nextDir++,
          'cliente_id': me['id'],
          'detalle_direccion': body['detalle_direccion'],
          'punto_referencia': body['punto_referencia'],
          'municipio_id': body['id_municipio'] ?? body['municipio_id'],
          'latitud': body['latitud'],
          'longitud': body['longitud'],
        };
        _direcciones.add(d);
        return _dirJson(d);
      }
      return _direcciones
          .where((d) => d['cliente_id'] == me['id'])
          .map(_dirJson)
          .toList();
    }

    if (path == ApiEndpoints.pedidos && m == 'POST') {
      final p = _nuevoPedido(
        clienteId: me['id'] as int,
        items: body['items'] as List,
        direccionId: body['id_direccion'] as int?,
        tipoEntrega: (body['tipo_entrega'] as String).toLowerCase(),
        metodoPago: (body['metodo_pago'] as String).toLowerCase(),
      );
      _pedidos.add(p);
      return p;
    }
    if (path == ApiEndpoints.misPedidos) {
      return _pedidos
          .where((p) => p['cliente_id'] == me['id'])
          .toList()
          .reversed
          .toList();
    }
    final ped = RegExp(r'^/pedidos/(\d+)/(cancelar|estado)$').firstMatch(path);
    if (ped != null) {
      final p = _pedido(int.parse(ped.group(1)!));
      if (ped.group(2) == 'cancelar') {
        if (p['estado'] != 'pendiente') {
          throw _MockError(400, 'Solo se pueden cancelar pedidos pendientes');
        }
        p['estado'] = 'cancelado';
      } else {
        p['estado'] = (body['estado'] as String).toLowerCase();
      }
      return p;
    }

    final tracking = RegExp(r'^/pedidos/(\d+)/seguimiento$').firstMatch(path);
    if (tracking != null) {
      final p = _pedido(int.parse(tracking.group(1)!));
      final direccion = _direcciones.where(
        (d) => d['id'] == p['direccion_id'],
      );
      final destino = direccion.isEmpty ? null : _dirJson(direccion.first);
      return {
        'id_pedido': p['id'],
        'estado': (p['estado'] as String).toUpperCase(),
        'estado_repartidor': 'EN_RUTA',
        'tipo_entrega': (p['tipo_entrega'] as String).toUpperCase(),
        'canal': p['canal'],
        'sucursal': {
          'id_sucursal': 1,
          'nombre': 'Minimarket San Miguel',
          'direccion': 'San Miguel',
          'latitud': 13.4833,
          'longitud': -88.1833,
        },
        'destino': destino == null
            ? null
            : {
                'id_direccion': destino['id'],
                'detalle_direccion': destino['detalle_direccion'],
                'punto_referencia': destino['punto_referencia'],
                'municipio': destino['municipio_nombre'],
                'latitud': destino['latitud'],
                'longitud': destino['longitud'],
              },
        'repartidor': {
          'id_repartidor': p['repartidor_id'],
          'nombre': 'Repartidor Demo',
          'telefono': '7000-0003',
          'latitud': 13.4840,
          'longitud': -88.1840,
          'ultima_actualizacion': DateTime.now().toIso8601String(),
        },
      };
    }
    final action = RegExp(
      r'^/pedidos/(\d+)/(enviar-factura|denunciar)$',
    ).firstMatch(path);
    if (action != null) {
      _pedido(int.parse(action.group(1)!));
      if (action.group(2) == 'denunciar' &&
          (body['motivo'] as String? ?? '').trim().length < 3) {
        throw _MockError(422, 'El motivo debe tener al menos 3 caracteres');
      }
      return {'mensaje': 'Solicitud procesada'};
    }

    if (path == ApiEndpoints.repartidorEntrante) return null;
    if (path == ApiEndpoints.repartidorPedidos) {
      return _pedidos
          .where(
            (p) =>
                p['repartidor_id'] == me['id'] &&
                p['estado'] != 'entregado' &&
                p['estado'] != 'cancelado',
          )
          .toList();
    }
    final riderAction = RegExp(
      r'^/repartidor/pedidos/(\d+)/(aceptar|rechazar)$',
    ).firstMatch(path);
    if (riderAction != null) {
      final p = _pedido(int.parse(riderAction.group(1)!));
      if (riderAction.group(2) == 'aceptar') {
        p['repartidor_id'] = me['id'];
        return p;
      }
      p['repartidor_id'] = null;
      p['estado_repartidor'] = 'LIBRE';
      return {'mensaje': 'Pedido rechazado'};
    }
    if (path == ApiEndpoints.repartidorEstado) {
      _estadoRepartidor = body['estado'] as String;
      return {'estado': _estadoRepartidor};
    }
    if (path == ApiEndpoints.repartidorUbicacion) return {'ok': true};

    throw _MockError(404, 'Ruta no encontrada: $m $path');
  }
}
