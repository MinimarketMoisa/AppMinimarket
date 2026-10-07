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
  String _estadoRepartidor = 'disponible';

  final List<Map<String, dynamic>> _users = [
    {'id': 1, 'nombre_completo': 'Cliente Demo', 'email': 'cliente@demo.com', 'password': '123456', 'telefono': '7000-0001', 'rol': 'cliente'},
    {'id': 2, 'nombre_completo': 'Empleado Demo', 'email': 'empleado@demo.com', 'password': '123456', 'telefono': '7000-0002', 'rol': 'empleado'},
    {'id': 3, 'nombre_completo': 'Repartidor Demo', 'email': 'repartidor@demo.com', 'password': '123456', 'telefono': '7000-0003', 'rol': 'repartidor'},
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
        'producto_id': p['id'],
        'producto_nombre': p['nombre'],
        'stock_disponible': 20 + (p['id'] as int) * 3,
        'fecha_vencimiento': '2026-12-31',
      }
  ];

  final List<Map<String, dynamic>> _municipios = [
    {'id': 1, 'nombre': 'San Miguel'},
    {'id': 2, 'nombre': 'Moncagua'},
    {'id': 3, 'nombre': 'Chinameca'},
  ];

  final List<Map<String, dynamic>> _direcciones = [
    {'id': 1, 'cliente_id': 1, 'detalle_direccion': 'Col. Centro, Calle Principal #12', 'punto_referencia': 'Frente al parque', 'municipio_id': 1},
    {'id': 2, 'cliente_id': 1, 'detalle_direccion': 'Res. Los Pinos, Casa 8', 'punto_referencia': 'Portón negro', 'municipio_id': 2},
  ];

  final List<Map<String, dynamic>> _pedidos = [];

  MockApiInterceptor() {
    _pedidos.add(_nuevoPedido(
      clienteId: 1,
      items: [
        {'producto_id': 1, 'cantidad': 2},
        {'producto_id': 7, 'cantidad': 1}
      ],
      direccionId: 1,
      tipoEntrega: 'domicilio',
      metodoPago: 'efectivo',
      estado: 'en_camino',
    ));
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    await Future.delayed(const Duration(milliseconds: 350));
    try {
      final data = _route(options);
      handler.resolve(Response(requestOptions: options, statusCode: 200, data: data));
    } on _MockError catch (e) {
      handler.reject(DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: options, statusCode: e.code, data: {'detail': e.msg}),
      ));
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

  Map<String, dynamic> _dirJson(Map<String, dynamic> d) =>
      {...d, 'municipio_nombre': _municipio(d['municipio_id'] as int)};

  String? _direccionTexto(int? id) {
    if (id == null) return null;
    final d = _direcciones.firstWhere((d) => d['id'] == id,
        orElse: () => throw _MockError(404, 'Dirección no encontrada'));
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
      final p = _productos.firstWhere((p) => p['id'] == it['producto_id'],
          orElse: () => throw _MockError(404, 'Producto no existe'));
      final cant = it['cantidad'] as int;
      final inv = _inventario.firstWhere((i) => i['producto_id'] == p['id']);
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
      'detalles': detalles,
    };
  }

  Map<String, dynamic> _pedido(int id) => _pedidos.firstWhere((p) => p['id'] == id,
      orElse: () => throw _MockError(404, 'Pedido no encontrado'));

  // ---------- rutas ----------
  dynamic _route(RequestOptions o) {
    final path = o.path;
    final m = o.method.toUpperCase();
    final body = o.data is Map ? Map<String, dynamic>.from(o.data as Map) : <String, dynamic>{};
    final q = o.queryParameters;

    if (path == ApiEndpoints.login && m == 'POST') {
      final found = _users.where((u) =>
          u['email'] == body['username'] && u['password'] == body['password']);
      if (found.isEmpty) throw _MockError(401, 'Correo o contraseña incorrectos');
      return {'access_token': 'mock-${found.first['id']}', 'token_type': 'bearer'};
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
      final cat = int.tryParse('${q['categoria_id'] ?? ''}');
      final txt = '${q['q'] ?? ''}'.toLowerCase();
      return _productos
          .where((p) => cat == null || p['categoria_id'] == cat)
          .where((p) => txt.isEmpty || (p['nombre'] as String).toLowerCase().contains(txt))
          .toList();
    }
    if (path == ApiEndpoints.municipios) return _municipios;
    if (path == ApiEndpoints.direcciones) {
      if (m == 'POST') {
        final d = {
          'id': _nextDir++,
          'cliente_id': me['id'],
          'detalle_direccion': body['detalle_direccion'],
          'punto_referencia': body['punto_referencia'],
          'municipio_id': body['municipio_id'],
        };
        _direcciones.add(d);
        return _dirJson(d);
      }
      return _direcciones.where((d) => d['cliente_id'] == me['id']).map(_dirJson).toList();
    }

    if (path == ApiEndpoints.inventario) return _inventario;
    final inv = RegExp(r'^/inventario/(\d+)$').firstMatch(path);
    if (inv != null && m == 'PATCH') {
      final row = _inventario.firstWhere((i) => i['id'] == int.parse(inv.group(1)!),
          orElse: () => throw _MockError(404, 'Inventario no encontrado'));
      row['stock_disponible'] = body['stock_disponible'];
      return row;
    }

    if (path == ApiEndpoints.pedidos && m == 'POST') {
      final p = _nuevoPedido(
        clienteId: me['id'] as int,
        items: body['items'] as List,
        direccionId: body['direccion_id'] as int?,
        tipoEntrega: body['tipo_entrega'] as String,
        metodoPago: body['metodo_pago'] as String,
      );
      _pedidos.add(p);
      return p;
    }
    if (path == ApiEndpoints.pedidos) return _pedidos.reversed.toList();
    if (path == ApiEndpoints.misPedidos) {
      return _pedidos.where((p) => p['cliente_id'] == me['id']).toList().reversed.toList();
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
        p['estado'] = body['estado'];
      }
      return p;
    }

    if (path == ApiEndpoints.repartidorPedidos) {
      return _pedidos
          .where((p) =>
              p['repartidor_id'] == me['id'] &&
              p['estado'] != 'entregado' &&
              p['estado'] != 'cancelado')
          .toList();
    }
    if (path == ApiEndpoints.repartidorEstado) {
      _estadoRepartidor = body['estado_operativo'] as String;
      return {'estado_operativo': _estadoRepartidor};
    }
    if (path == ApiEndpoints.repartidorUbicacion) return {'ok': true};
    final comp = RegExp(r'^/repartidor/pedidos/(\d+)/completar$').firstMatch(path);
    if (comp != null) {
      final p = _pedido(int.parse(comp.group(1)!));
      p['estado'] = 'entregado';
      p['estado_pago'] = 'pagado';
      return p;
    }

    throw _MockError(404, 'Ruta no encontrada: $m $path');
  }
}