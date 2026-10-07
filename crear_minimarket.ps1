$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)
# Ejecutar desde la raiz del proyecto Flutter (donde esta pubspec.yaml)
function W($p, $c) { $full = Join-Path (Get-Location) $p; New-Item -ItemType Directory -Force -Path (Split-Path $full) | Out-Null; [IO.File]::WriteAllText($full, $c, $utf8) }
W 'lib/main.dart' @'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/delivery/presentation/pages/delivery_home_page.dart';
import 'features/shell/client_shell.dart';
import 'features/staff/presentation/pages/staff_home_page.dart';

void main() => runApp(const ProviderScope(child: MinimarketApp()));

class MinimarketApp extends StatelessWidget {
  const MinimarketApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Minimarket',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _Root(),
      );
}

/// Decide qué pantalla mostrar según la sesión y el rol del usuario.
class _Root extends ConsumerWidget {
  const _Root();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(authProvider).when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, __) => const LoginPage(),
          data: (user) {
            if (user == null) return const LoginPage();
            switch (user.rol) {
              case 'repartidor':
                return const DeliveryHomePage();
              case 'empleado':
                return const StaffHomePage();
              default:
                return const ClientShell();
            }
          },
        );
  }
}
'@
W 'lib/core/config/app_config.dart' @'
class AppConfig {
  /// true  = la app usa datos simulados (no necesita API).
  /// false = la app se conecta a la API real en [baseUrl].
  static const bool useMock = true;

  /// 10.0.2.2 = localhost desde el emulador Android.
  /// En celular físico usa la IP de tu PC, ej: http://192.168.1.50:8000
  /// También: flutter run --dart-define=API_URL=https://mi-api.com
  static const String baseUrl =
      String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8000');
}
'@
W 'lib/core/network/api_endpoints.dart' @'
/// Todas las rutas de la API en un solo lugar.
/// Cuando tengas la API real, ajusta aquí los paths si difieren.
class ApiEndpoints {
  // auth.py
  static const login = '/auth/login'; // POST form: username(email), password
  static const register = '/auth/register'; // POST json
  static const me = '/auth/me'; // GET

  // catalogo.py
  static const categorias = '/catalogo/categorias'; // GET
  static const productos = '/catalogo/productos'; // GET ?categoria_id=&q=

  // direcciones.py
  static const municipios = '/direcciones/municipios'; // GET
  static const direcciones = '/direcciones'; // GET, POST

  // inventario.py
  static const inventario = '/inventario'; // GET
  static String stock(int id) => '/inventario/$id'; // PATCH {stock_disponible}

  // pedidos.py
  static const pedidos = '/pedidos'; // POST crear, GET todos (empleado)
  static const misPedidos = '/pedidos/mis-pedidos'; // GET
  static String cancelarPedido(int id) => '/pedidos/$id/cancelar'; // POST
  static String estadoPedido(int id) => '/pedidos/$id/estado'; // PATCH {estado}

  // repartidor.py
  static const repartidorPedidos = '/repartidor/pedidos'; // GET
  static const repartidorEstado = '/repartidor/estado'; // PATCH {estado_operativo}
  static const repartidorUbicacion = '/repartidor/ubicacion'; // POST {latitud, longitud}
  static String completarEntrega(int id) => '/repartidor/pedidos/$id/completar'; // POST
}
'@
W 'lib/core/network/dio_client.dart' @'
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'mock_api_interceptor.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));
  final storage = ref.read(tokenStorageProvider);

  // Agrega el token JWT a cada petición.
  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) async {
    final token = await storage.read();
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }));

  // Datos simulados mientras no exista la API.
  if (AppConfig.useMock) dio.interceptors.add(MockApiInterceptor());
  return dio;
});
'@
W 'lib/core/network/mock_api_interceptor.dart' @'
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
'@
W 'lib/core/storage/token_storage.dart' @'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _key = 'access_token';
  final _storage = const FlutterSecureStorage();

  Future<String?> read() async {
    try {
      return await _storage.read(key: _key);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(String token) async {
    try {
      await _storage.write(key: _key, value: token);
    } catch (_) {}
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {}
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());
'@
W 'lib/core/theme/app_theme.dart' @'
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2E9E5B),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      );
}
'@
W 'lib/core/utils/helpers.dart' @'
import 'package:dio/dio.dart';

double toDouble(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

String money(num v) => '\$${v.toStringAsFixed(2)}';

String fechaCorta(DateTime? d) {
  if (d == null) return '';
  String t(int n) => n.toString().padLeft(2, '0');
  return '${t(d.day)}/${t(d.month)}/${d.year} ${t(d.hour)}:${t(d.minute)}';
}

String estadoLabel(String e) => const {
      'pendiente': 'Pendiente',
      'preparando': 'Preparando',
      'listo': 'Listo para retirar',
      'en_camino': 'En camino',
      'entregado': 'Entregado',
      'cancelado': 'Cancelado',
    }[e] ??
    e;

/// Convierte cualquier error en un mensaje legible para el usuario.
String errorMessage(Object e) {
  if (e is DioException) {
    final d = e.response?.data;
    if (d is Map && d['detail'] != null) {
      final det = d['detail'];
      if (det is String) return det;
      if (det is List && det.isNotEmpty) {
        final first = det.first;
        if (first is Map && first['msg'] != null) return first['msg'].toString();
      }
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'No se pudo conectar con el servidor';
    }
  }
  return 'Ocurrió un error inesperado';
}
'@
W 'lib/features/addresses/data/models/direccion_models.dart' @'
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
'@
W 'lib/features/addresses/data/repositories/addresses_repository.dart' @'
import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/direccion_models.dart';

class AddressesRepository {
  final Dio dio;
  AddressesRepository(this.dio);

  Future<List<Direccion>> listar() async {
    final r = await dio.get(ApiEndpoints.direcciones);
    return (r.data as List).map((e) => Direccion.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Municipio>> municipios() async {
    final r = await dio.get(ApiEndpoints.municipios);
    return (r.data as List).map((e) => Municipio.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> crear({
    required String detalle,
    String? referencia,
    required int municipioId,
  }) async {
    await dio.post(ApiEndpoints.direcciones, data: {
      'detalle_direccion': detalle,
      'punto_referencia': referencia,
      'municipio_id': municipioId,
    });
  }
}
'@
W 'lib/features/addresses/presentation/pages/addresses_page.dart' @'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/helpers.dart';
import '../providers/addresses_provider.dart';

class AddressesPage extends ConsumerWidget {
  const AddressesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dirs = ref.watch(direccionesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mis direcciones')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Agregar'),
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const _AddressForm(),
        ),
      ),
      body: dirs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(errorMessage(e))),
        data: (list) => list.isEmpty
            ? const Center(child: Text('Aún no tienes direcciones'))
            : ListView(
                padding: const EdgeInsets.only(bottom: 90),
                children: [
                  for (final d in list)
                    ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: Text(d.detalleDireccion),
                      subtitle: Text(
                          '${d.municipioNombre ?? ''}${d.puntoReferencia != null ? ' · ${d.puntoReferencia}' : ''}'),
                    ),
                ],
              ),
      ),
    );
  }
}

class _AddressForm extends ConsumerStatefulWidget {
  const _AddressForm();
  @override
  ConsumerState<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends ConsumerState<_AddressForm> {
  final _form = GlobalKey<FormState>();
  final _detalle = TextEditingController();
  final _ref = TextEditingController();
  int? _municipio;
  bool _saving = false;

  @override
  void dispose() {
    _detalle.dispose();
    _ref.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(addressesRepositoryProvider).crear(
            detalle: _detalle.text.trim(),
            referencia: _ref.text.trim().isEmpty ? null : _ref.text.trim(),
            municipioId: _municipio!,
          );
      ref.invalidate(direccionesProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final municipios = ref.watch(municipiosProvider);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Nueva dirección', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            municipios.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(errorMessage(e)),
              data: (list) => DropdownButtonFormField<int>(
                value: _municipio,
                decoration: const InputDecoration(labelText: 'Municipio'),
                items: [for (final m in list) DropdownMenuItem(value: m.id, child: Text(m.nombre))],
                onChanged: (v) => setState(() => _municipio = v),
                validator: (v) => v == null ? 'Selecciona un municipio' : null,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _detalle,
              decoration: const InputDecoration(labelText: 'Dirección'),
              validator: (v) => (v == null || v.trim().length < 5) ? 'Ingresa la dirección' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ref,
              decoration: const InputDecoration(labelText: 'Punto de referencia (opcional)'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
'@
W 'lib/features/addresses/presentation/providers/addresses_provider.dart' @'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/models/direccion_models.dart';
import '../../data/repositories/addresses_repository.dart';

final addressesRepositoryProvider =
    Provider<AddressesRepository>((ref) => AddressesRepository(ref.read(dioProvider)));

final direccionesProvider = FutureProvider.autoDispose<List<Direccion>>(
    (ref) => ref.read(addressesRepositoryProvider).listar());

final municipiosProvider = FutureProvider.autoDispose<List<Municipio>>(
    (ref) => ref.read(addressesRepositoryProvider).municipios());
'@
W 'lib/features/auth/data/datasources/auth_remote_datasource.dart' @'
import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final Dio dio;
  AuthRemoteDataSource(this.dio);

  /// FastAPI (OAuth2PasswordRequestForm) espera form-urlencoded con "username".
  Future<String> login(String email, String password) async {
    final r = await dio.post(
      ApiEndpoints.login,
      data: {'username': email, 'password': password},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    return r.data['access_token'] as String;
  }

  Future<void> register({
    required String nombreCompleto,
    required String email,
    required String password,
    String? telefono,
  }) async {
    await dio.post(ApiEndpoints.register, data: {
      'nombre_completo': nombreCompleto,
      'email': email,
      'password': password,
      'telefono': telefono,
    });
  }

  Future<UserModel> me() async {
    final r = await dio.get(ApiEndpoints.me);
    return UserModel.fromJson(r.data as Map<String, dynamic>);
  }
}
'@
W 'lib/features/auth/data/models/user_model.dart' @'
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
'@
W 'lib/features/auth/data/repositories/auth_repository_impl.dart' @'
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final TokenStorage _storage;
  AuthRepositoryImpl(this._remote, this._storage);

  @override
  Future<UserEntity> login(String email, String password) async {
    final token = await _remote.login(email, password);
    await _storage.save(token);
    return _remote.me();
  }

  @override
  Future<UserEntity> register({
    required String nombreCompleto,
    required String email,
    required String password,
    String? telefono,
  }) async {
    await _remote.register(
        nombreCompleto: nombreCompleto, email: email, password: password, telefono: telefono);
    return login(email, password);
  }

  @override
  Future<UserEntity?> currentUser() async {
    final token = await _storage.read();
    if (token == null) return null;
    try {
      return await _remote.me();
    } catch (_) {
      await _storage.clear();
      return null;
    }
  }

  @override
  Future<void> logout() => _storage.clear();
}
'@
W 'lib/features/auth/domain/entities/user_entity.dart' @'
class UserEntity {
  final int id;
  final String nombreCompleto;
  final String email;
  final String? telefono;
  final String rol; // cliente | repartidor | empleado

  const UserEntity({
    required this.id,
    required this.nombreCompleto,
    required this.email,
    this.telefono,
    required this.rol,
  });
}
'@
W 'lib/features/auth/domain/repositories/auth_repository.dart' @'
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login(String email, String password);
  Future<UserEntity> register({
    required String nombreCompleto,
    required String email,
    required String password,
    String? telefono,
  });
  Future<UserEntity?> currentUser();
  Future<void> logout();
}
'@
W 'lib/features/auth/domain/usecases/auth_usecases.dart' @'
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _repo;
  LoginUseCase(this._repo);
  Future<UserEntity> call(String email, String password) => _repo.login(email, password);
}

class RegisterUseCase {
  final AuthRepository _repo;
  RegisterUseCase(this._repo);
  Future<UserEntity> call({
    required String nombreCompleto,
    required String email,
    required String password,
    String? telefono,
  }) =>
      _repo.register(
          nombreCompleto: nombreCompleto, email: email, password: password, telefono: telefono);
}

class GetCurrentUserUseCase {
  final AuthRepository _repo;
  GetCurrentUserUseCase(this._repo);
  Future<UserEntity?> call() => _repo.currentUser();
}

class LogoutUseCase {
  final AuthRepository _repo;
  LogoutUseCase(this._repo);
  Future<void> call() => _repo.logout();
}
'@
W 'lib/features/auth/presentation/pages/login_page.dart' @'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/utils/helpers.dart';
import '../providers/auth_provider.dart';
import 'register_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false, _hide = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).login(_email.text.trim(), _pass.text);
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.storefront, size: 72, color: cs.primary),
                    const SizedBox(height: 8),
                    Text('Minimarket',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                          labelText: 'Correo', prefixIcon: Icon(Icons.email_outlined)),
                      validator: (v) =>
                          (v == null || !v.contains('@')) ? 'Ingresa un correo válido' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _pass,
                      obscureText: _hide,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_hide ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _hide = !_hide),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 4) ? 'Mínimo 4 caracteres' : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: TextStyle(color: cs.error), textAlign: TextAlign.center),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Iniciar sesión'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const RegisterPage())),
                      child: const Text('¿No tienes cuenta? Regístrate'),
                    ),
                    if (AppConfig.useMock) ...[
                      const Divider(height: 32),
                      Text(
                        'Modo demo (sin API)\ncliente@demo.com · empleado@demo.com · repartidor@demo.com\nClave: 123456',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
'@
W 'lib/features/auth/presentation/pages/profile_page.dart' @'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../addresses/presentation/pages/addresses_page.dart';
import '../providers/auth_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
          const SizedBox(height: 12),
          Center(
              child: Text(user?.nombreCompleto ?? '',
                  style: Theme.of(context).textTheme.titleLarge)),
          Center(child: Text(user?.email ?? '')),
          if (user?.telefono != null) Center(child: Text(user!.telefono!)),
          const SizedBox(height: 16),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Mis direcciones'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AddressesPage())),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}
'@
W 'lib/features/auth/presentation/pages/register_page.dart' @'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/helpers.dart';
import '../providers/auth_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});
  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _email = TextEditingController();
  final _tel = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _email.dispose();
    _tel.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).register(
            nombreCompleto: _nombre.text.trim(),
            email: _email.text.trim(),
            password: _pass.text,
            telefono: _tel.text.trim().isEmpty ? null : _tel.text.trim(),
          );
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nombre,
                    decoration: const InputDecoration(labelText: 'Nombre completo'),
                    validator: (v) => (v == null || v.trim().length < 3) ? 'Ingresa tu nombre' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Correo'),
                    validator: (v) => (v == null || !v.contains('@')) ? 'Correo inválido' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _tel,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Teléfono (opcional)'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _pass,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                    validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                        textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Registrarme'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
'@
W 'lib/features/auth/presentation/providers/auth_provider.dart' @'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepositoryImpl(
      AuthRemoteDataSource(ref.read(dioProvider)),
      ref.read(tokenStorageProvider),
    ));

final authProvider = AsyncNotifierProvider<AuthNotifier, UserEntity?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<UserEntity?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<UserEntity?> build() => GetCurrentUserUseCase(_repo)();

  /// Lanza excepción si falla (la pantalla muestra el mensaje).
  Future<void> login(String email, String password) async {
    final user = await LoginUseCase(_repo)(email, password);
    state = AsyncData(user);
  }

  Future<void> register({
    required String nombreCompleto,
    required String email,
    required String password,
    String? telefono,
  }) async {
    final user = await RegisterUseCase(_repo)(
        nombreCompleto: nombreCompleto, email: email, password: password, telefono: telefono);
    state = AsyncData(user);
  }

  Future<void> logout() async {
    await LogoutUseCase(_repo)();
    ref.read(cartProvider.notifier).clear();
    state = const AsyncData(null);
  }
}
'@
W 'lib/features/cart/presentation/pages/cart_page.dart' @'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/helpers.dart';
import '../../../addresses/presentation/pages/addresses_page.dart';
import '../../../addresses/presentation/providers/addresses_provider.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../providers/cart_provider.dart';

class CartPage extends ConsumerStatefulWidget {
  final VoidCallback? onOrdered;
  const CartPage({super.key, this.onOrdered});
  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  String _entrega = 'domicilio';
  String _pago = 'efectivo';
  int? _dirId;
  bool _loading = false;

  Future<void> _confirmar() async {
    final items = ref.read(cartProvider);
    if (_entrega == 'domicilio' && _dirId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Selecciona una dirección de entrega')));
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(ordersRepositoryProvider).crear(
            items: [
              for (final i in items) {'producto_id': i.producto.id, 'cantidad': i.cantidad}
            ],
            direccionId: _entrega == 'domicilio' ? _dirId : null,
            tipoEntrega: _entrega,
            metodoPago: _pago,
          );
      ref.read(cartProvider.notifier).clear();
      ref.invalidate(misPedidosProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('¡Pedido realizado con éxito!')));
        widget.onOrdered?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(cartProvider);
    if (items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Carrito')),
        body: const Center(child: Text('Tu carrito está vacío')),
      );
    }
    final subtotal = ref.watch(cartTotalProvider);
    final envio = _entrega == 'domicilio' ? 2.0 : 0.0; // estimado; la API calcula el real
    final dirs = ref.watch(direccionesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Carrito')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final i in items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(i.producto.nombre),
              subtitle: Text('${money(i.producto.precioBase)} c/u · ${money(i.subtotal)}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => ref.read(cartProvider.notifier).decrement(i.producto)),
                Text('${i.cantidad}', style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => ref.read(cartProvider.notifier).add(i.producto)),
              ]),
            ),
          const Divider(),
          const SizedBox(height: 8),
          const Text('Tipo de entrega', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'domicilio', label: Text('Domicilio'), icon: Icon(Icons.delivery_dining)),
              ButtonSegment(value: 'retiro', label: Text('Retiro'), icon: Icon(Icons.store)),
            ],
            selected: {_entrega},
            onSelectionChanged: (s) => setState(() => _entrega = s.first),
          ),
          if (_entrega == 'domicilio') ...[
            const SizedBox(height: 12),
            dirs.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(errorMessage(e)),
              data: (list) => list.isEmpty
                  ? TextButton.icon(
                      icon: const Icon(Icons.add_location_alt),
                      label: const Text('Agrega una dirección para continuar'),
                      onPressed: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const AddressesPage())),
                    )
                  : DropdownButtonFormField<int>(
                      value: list.any((d) => d.id == _dirId) ? _dirId : null,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Dirección de entrega'),
                      items: [
                        for (final d in list)
                          DropdownMenuItem(
                              value: d.id,
                              child: Text(d.resumen, overflow: TextOverflow.ellipsis))
                      ],
                      onChanged: (v) => setState(() => _dirId = v),
                    ),
            ),
          ],
          const SizedBox(height: 16),
          const Text('Método de pago', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'efectivo', label: Text('Efectivo'), icon: Icon(Icons.payments_outlined)),
              ButtonSegment(value: 'tarjeta', label: Text('Tarjeta'), icon: Icon(Icons.credit_card)),
            ],
            selected: {_pago},
            onSelectionChanged: (s) => setState(() => _pago = s.first),
          ),
          const SizedBox(height: 20),
          Row(children: [const Expanded(child: Text('Subtotal')), Text(money(subtotal))]),
          Row(children: [const Expanded(child: Text('Envío (estimado)')), Text(money(envio))]),
          const SizedBox(height: 4),
          Row(children: [
            const Expanded(child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            Text(money(subtotal + envio),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loading ? null : _confirmar,
            icon: _loading
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            label: const Text('Confirmar pedido'),
          ),
        ],
      ),
    );
  }
}
'@
W 'lib/features/cart/presentation/providers/cart_provider.dart' @'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../catalog/data/models/catalogo_models.dart';

class CartItem {
  final Producto producto;
  final int cantidad;
  const CartItem(this.producto, this.cantidad);
  double get subtotal => producto.precioBase * cantidad;
}

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  void add(Producto p) {
    final i = state.indexWhere((e) => e.producto.id == p.id);
    if (i == -1) {
      state = [...state, CartItem(p, 1)];
    } else {
      state = [
        for (var k = 0; k < state.length; k++)
          if (k == i) CartItem(p, state[k].cantidad + 1) else state[k]
      ];
    }
  }

  void decrement(Producto p) {
    final i = state.indexWhere((e) => e.producto.id == p.id);
    if (i == -1) return;
    if (state[i].cantidad <= 1) {
      remove(p.id);
    } else {
      state = [
        for (var k = 0; k < state.length; k++)
          if (k == i) CartItem(p, state[k].cantidad - 1) else state[k]
      ];
    }
  }

  void remove(int productoId) =>
      state = state.where((e) => e.producto.id != productoId).toList();

  void clear() => state = [];
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);

final cartTotalProvider =
    Provider<double>((ref) => ref.watch(cartProvider).fold(0.0, (s, e) => s + e.subtotal));

final cartCountProvider =
    Provider<int>((ref) => ref.watch(cartProvider).fold(0, (s, e) => s + e.cantidad));
'@
W 'lib/features/catalog/data/models/catalogo_models.dart' @'
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
'@
W 'lib/features/catalog/data/repositories/catalog_repository.dart' @'
import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/catalogo_models.dart';

class CatalogRepository {
  final Dio dio;
  CatalogRepository(this.dio);

  Future<List<Categoria>> categorias() async {
    final r = await dio.get(ApiEndpoints.categorias);
    return (r.data as List).map((e) => Categoria.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Producto>> productos({int? categoriaId, String? q}) async {
    final r = await dio.get(ApiEndpoints.productos, queryParameters: {
      if (categoriaId != null) 'categoria_id': categoriaId,
      if (q != null && q.isNotEmpty) 'q': q,
    });
    return (r.data as List).map((e) => Producto.fromJson(e as Map<String, dynamic>)).toList();
  }
}
'@
W 'lib/features/catalog/presentation/pages/catalog_page.dart' @'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/helpers.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../providers/catalog_provider.dart';
import '../widgets/product_card.dart';

class CatalogPage extends ConsumerWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categorias = ref.watch(categoriasProvider);
    final productos = ref.watch(productosProvider);
    final selected = ref.watch(selectedCategoriaProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onSubmitted: (v) => ref.read(searchProvider.notifier).state = v.trim(),
            ),
          ),
          SizedBox(
            height: 48,
            child: categorias.when(
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
              data: (cats) => ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('Todos'),
                      selected: selected == null,
                      onSelected: (_) => ref.read(selectedCategoriaProvider.notifier).state = null,
                    ),
                  ),
                  for (final c in cats)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(c.nombre),
                        selected: selected == c.id,
                        onSelected: (_) =>
                            ref.read(selectedCategoriaProvider.notifier).state = c.id,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: productos.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(errorMessage(e)),
                  TextButton(
                      onPressed: () => ref.invalidate(productosProvider),
                      child: const Text('Reintentar')),
                ]),
              ),
              data: (list) => list.isEmpty
                  ? const Center(child: Text('No se encontraron productos'))
                  : RefreshIndicator(
                      onRefresh: () async => ref.invalidate(productosProvider),
                      child: GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: list.length,
                        itemBuilder: (_, i) => ProductCard(
                          producto: list[i],
                          onAdd: () {
                            ref.read(cartProvider.notifier).add(list[i]);
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(SnackBar(
                                  duration: const Duration(seconds: 1),
                                  content: Text('${list[i].nombre} agregado')));
                          },
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
'@
W 'lib/features/catalog/presentation/providers/catalog_provider.dart' @'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/models/catalogo_models.dart';
import '../../data/repositories/catalog_repository.dart';

final catalogRepositoryProvider =
    Provider<CatalogRepository>((ref) => CatalogRepository(ref.read(dioProvider)));

final categoriasProvider = FutureProvider.autoDispose<List<Categoria>>(
    (ref) => ref.read(catalogRepositoryProvider).categorias());

final selectedCategoriaProvider = StateProvider<int?>((ref) => null);
final searchProvider = StateProvider<String>((ref) => '');

final productosProvider = FutureProvider.autoDispose<List<Producto>>((ref) {
  final cat = ref.watch(selectedCategoriaProvider);
  final q = ref.watch(searchProvider);
  return ref.read(catalogRepositoryProvider).productos(categoriaId: cat, q: q);
});
'@
W 'lib/features/catalog/presentation/widgets/product_card.dart' @'
import 'package:flutter/material.dart';
import '../../../../core/utils/helpers.dart';
import '../../data/models/catalogo_models.dart';

class ProductCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback onAdd;
  const ProductCard({super.key, required this.producto, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                    color: cs.primaryContainer, borderRadius: BorderRadius.circular(10)),
                child: producto.imagenUrl != null
                    ? Image.network(producto.imagenUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.shopping_basket, size: 40))
                    : Icon(Icons.shopping_basket, size: 40, color: cs.primary),
              ),
            ),
            const SizedBox(height: 8),
            Text(producto.nombre, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(money(producto.precioBase),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton.filled(
                  visualDensity: VisualDensity.compact,
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  tooltip: 'Agregar',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
'@
W 'lib/features/delivery/data/repositories/delivery_repository.dart' @'
import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../orders/data/models/pedido_models.dart';

class DeliveryRepository {
  final Dio dio;
  DeliveryRepository(this.dio);

  Future<List<Pedido>> asignados() async {
    final r = await dio.get(ApiEndpoints.repartidorPedidos);
    return (r.data as List).map((e) => Pedido.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> completar(int pedidoId) => dio.post(ApiEndpoints.completarEntrega(pedidoId));

  Future<void> cambiarEstado(String estadoOperativo) =>
      dio.patch(ApiEndpoints.repartidorEstado, data: {'estado_operativo': estadoOperativo});

  Future<void> actualizarUbicacion(double lat, double lng) =>
      dio.post(ApiEndpoints.repartidorUbicacion, data: {'latitud': lat, 'longitud': lng});
}
'@
W 'lib/features/delivery/presentation/pages/delivery_home_page.dart' @'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/helpers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../orders/presentation/widgets/pedido_card.dart';
import '../providers/delivery_provider.dart';

class DeliveryHomePage extends ConsumerStatefulWidget {
  const DeliveryHomePage({super.key});
  @override
  ConsumerState<DeliveryHomePage> createState() => _DeliveryHomePageState();
}

class _DeliveryHomePageState extends ConsumerState<DeliveryHomePage> {
  String _estado = 'disponible';

  void _msg(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _cambiarEstado(String e) async {
    try {
      await ref.read(deliveryRepositoryProvider).cambiarEstado(e);
      setState(() => _estado = e);
    } catch (err) {
      _msg(errorMessage(err));
    }
  }

  Future<void> _enviarUbicacion() async {
    try {
      // TODO: reemplazar por GPS real con el paquete `geolocator`.
      await ref.read(deliveryRepositoryProvider).actualizarUbicacion(13.4833, -88.1833);
      _msg('Ubicación enviada');
    } catch (err) {
      _msg(errorMessage(err));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).valueOrNull;
    final pedidos = ref.watch(pedidosAsignadosProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${user?.nombreCompleto.split(' ').first ?? ''}'),
        actions: [
          IconButton(
              tooltip: 'Cerrar sesión',
              icon: const Icon(Icons.logout),
              onPressed: () => ref.read(authProvider.notifier).logout()),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _estado,
                  decoration: const InputDecoration(labelText: 'Mi estado', isDense: true),
                  items: const [
                    DropdownMenuItem(value: 'disponible', child: Text('Disponible')),
                    DropdownMenuItem(value: 'en_ruta', child: Text('En ruta')),
                    DropdownMenuItem(value: 'descanso', child: Text('En descanso')),
                  ],
                  onChanged: (v) => v == null ? null : _cambiarEstado(v),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.tonalIcon(
                onPressed: _enviarUbicacion,
                icon: const Icon(Icons.my_location),
                label: const Text('Ubicación'),
              ),
            ]),
          ),
          Expanded(
            child: pedidos.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(errorMessage(e))),
              data: (list) => RefreshIndicator(
                onRefresh: () async => ref.invalidate(pedidosAsignadosProvider),
                child: list.isEmpty
                    ? ListView(children: const [
                        SizedBox(height: 160),
                        Center(child: Text('No tienes entregas pendientes')),
                      ])
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          for (final p in list)
                            PedidoCard(
                              pedido: p,
                              mostrarCliente: true,
                              actions: [
                                FilledButton.icon(
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text('Completar entrega'),
                                  onPressed: () async {
                                    try {
                                      await ref.read(deliveryRepositoryProvider).completar(p.id);
                                      ref.invalidate(pedidosAsignadosProvider);
                                      _msg('Entrega completada');
                                    } catch (err) {
                                      _msg(errorMessage(err));
                                    }
                                  },
                                ),
                              ],
                            ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
'@
W 'lib/features/delivery/presentation/providers/delivery_provider.dart' @'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../orders/data/models/pedido_models.dart';
import '../../data/repositories/delivery_repository.dart';

final deliveryRepositoryProvider =
    Provider<DeliveryRepository>((ref) => DeliveryRepository(ref.read(dioProvider)));

final pedidosAsignadosProvider = FutureProvider.autoDispose<List<Pedido>>(
    (ref) => ref.read(deliveryRepositoryProvider).asignados());
'@
W 'lib/features/orders/data/models/pedido_models.dart' @'
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
        productoId: j['producto_id'],
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
        id: j['id'],
        canal: j['canal'] ?? '',
        fechaCreacion: DateTime.tryParse('${j['fecha_creacion']}'),
        estado: j['estado'] ?? 'pendiente',
        tipoEntrega: j['tipo_entrega'] ?? '',
        metodoPago: j['metodo_pago'] ?? '',
        estadoPago: j['estado_pago'] ?? '',
        costoEnvio: toDouble(j['costo_envio']),
        total: toDouble(j['total']),
        direccion: j['direccion'],
        clienteNombre: j['cliente_nombre'],
        detalles: ((j['detalles'] ?? []) as List)
            .map((e) => DetallePedido.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
'@
W 'lib/features/orders/data/repositories/orders_repository.dart' @'
import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/pedido_models.dart';

class OrdersRepository {
  final Dio dio;
  OrdersRepository(this.dio);

  List<Pedido> _list(dynamic data) =>
      (data as List).map((e) => Pedido.fromJson(e as Map<String, dynamic>)).toList();

  Future<Pedido> crear({
    required List<Map<String, int>> items, // [{producto_id, cantidad}]
    int? direccionId,
    required String tipoEntrega, // domicilio | retiro
    required String metodoPago, // efectivo | tarjeta
  }) async {
    final r = await dio.post(ApiEndpoints.pedidos, data: {
      'items': items,
      'direccion_id': direccionId,
      'tipo_entrega': tipoEntrega,
      'metodo_pago': metodoPago,
      'canal': 'app_movil',
    });
    return Pedido.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<Pedido>> misPedidos() async =>
      _list((await dio.get(ApiEndpoints.misPedidos)).data);

  Future<List<Pedido>> todos() async => _list((await dio.get(ApiEndpoints.pedidos)).data);

  Future<void> cancelar(int id) => dio.post(ApiEndpoints.cancelarPedido(id));

  Future<void> cambiarEstado(int id, String estado) =>
      dio.patch(ApiEndpoints.estadoPedido(id), data: {'estado': estado});
}
'@
W 'lib/features/orders/presentation/pages/orders_page.dart' @'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/helpers.dart';
import '../providers/orders_provider.dart';
import '../widgets/pedido_card.dart';

class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pedidos = ref.watch(misPedidosProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mis pedidos')),
      body: pedidos.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(errorMessage(e))),
        data: (list) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(misPedidosProvider),
          child: list.isEmpty
              ? ListView(children: const [
                  SizedBox(height: 200),
                  Center(child: Text('Todavía no has hecho pedidos')),
                ])
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (final p in list)
                      PedidoCard(
                        pedido: p,
                        actions: [
                          if (p.estado == 'pendiente')
                            OutlinedButton.icon(
                              icon: const Icon(Icons.cancel_outlined),
                              label: const Text('Cancelar pedido'),
                              onPressed: () async {
                                try {
                                  await ref.read(ordersRepositoryProvider).cancelar(p.id);
                                  ref.invalidate(misPedidosProvider);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(content: Text(errorMessage(e))));
                                  }
                                }
                              },
                            ),
                        ],
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
'@
W 'lib/features/orders/presentation/providers/orders_provider.dart' @'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/models/pedido_models.dart';
import '../../data/repositories/orders_repository.dart';

final ordersRepositoryProvider =
    Provider<OrdersRepository>((ref) => OrdersRepository(ref.read(dioProvider)));

final misPedidosProvider = FutureProvider.autoDispose<List<Pedido>>(
    (ref) => ref.read(ordersRepositoryProvider).misPedidos());

final todosPedidosProvider = FutureProvider.autoDispose<List<Pedido>>(
    (ref) => ref.read(ordersRepositoryProvider).todos());
'@
W 'lib/features/orders/presentation/widgets/pedido_card.dart' @'
import 'package:flutter/material.dart';
import '../../../../core/utils/helpers.dart';
import '../../data/models/pedido_models.dart';

class PedidoCard extends StatelessWidget {
  final Pedido pedido;
  final List<Widget> actions;
  final bool mostrarCliente;
  const PedidoCard({
    super.key,
    required this.pedido,
    this.actions = const [],
    this.mostrarCliente = false,
  });

  Color _color(String e) => switch (e) {
        'pendiente' => Colors.orange,
        'preparando' => Colors.blue,
        'listo' => Colors.teal,
        'en_camino' => Colors.indigo,
        'entregado' => Colors.green,
        'cancelado' => Colors.red,
        _ => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = _color(pedido.estado);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('Pedido #${pedido.id}',
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              Chip(
                label: Text(estadoLabel(pedido.estado), style: TextStyle(color: c)),
                backgroundColor: c.withAlpha(35),
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
              ),
            ]),
            Text(fechaCorta(pedido.fechaCreacion), style: t.bodySmall),
            if (mostrarCliente && pedido.clienteNombre != null)
              Text('Cliente: ${pedido.clienteNombre}'),
            Text(pedido.tipoEntrega == 'domicilio' ? 'A domicilio' : 'Retiro en tienda'),
            if (pedido.direccion != null) Text('Entrega: ${pedido.direccion}'),
            Text('Pago: ${pedido.metodoPago} (${pedido.estadoPago})'),
            const Divider(),
            for (final d in pedido.detalles)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(children: [
                  Expanded(child: Text('${d.cantidad} x ${d.nombreProducto}')),
                  Text(money(d.subtotal)),
                ]),
              ),
            if (pedido.costoEnvio > 0)
              Row(children: [
                const Expanded(child: Text('Envío')),
                Text(money(pedido.costoEnvio)),
              ]),
            const Divider(),
            Row(children: [
              const Expanded(child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
              Text(money(pedido.total), style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 4, children: actions),
            ],
          ],
        ),
      ),
    );
  }
}
'@
W 'lib/features/shell/client_shell.dart' @'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/presentation/pages/profile_page.dart';
import '../cart/presentation/pages/cart_page.dart';
import '../cart/presentation/providers/cart_provider.dart';
import '../catalog/presentation/pages/catalog_page.dart';
import '../orders/presentation/pages/orders_page.dart';

class ClientShell extends ConsumerStatefulWidget {
  const ClientShell({super.key});
  @override
  ConsumerState<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends ConsumerState<ClientShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final count = ref.watch(cartCountProvider);
    return Scaffold(
      body: IndexedStack(index: _index, children: [
        const CatalogPage(),
        CartPage(onOrdered: () => setState(() => _index = 2)),
        const OrdersPage(),
        const ProfilePage(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.storefront_outlined), label: 'Catálogo'),
          NavigationDestination(
            icon: Badge(
                label: Text('$count'),
                isLabelVisible: count > 0,
                child: const Icon(Icons.shopping_cart_outlined)),
            label: 'Carrito',
          ),
          const NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Pedidos'),
          const NavigationDestination(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
    );
  }
}
'@
W 'lib/features/staff/data/models/inventario_model.dart' @'
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
'@
W 'lib/features/staff/data/repositories/inventory_repository.dart' @'
import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/inventario_model.dart';

class InventoryRepository {
  final Dio dio;
  InventoryRepository(this.dio);

  Future<List<Inventario>> listar() async {
    final r = await dio.get(ApiEndpoints.inventario);
    return (r.data as List).map((e) => Inventario.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> fijarStock(int id, int cantidad) =>
      dio.patch(ApiEndpoints.stock(id), data: {'stock_disponible': cantidad});
}
'@
W 'lib/features/staff/presentation/pages/staff_home_page.dart' @'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/helpers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../../orders/presentation/widgets/pedido_card.dart';
import '../providers/staff_provider.dart';

const _estados = ['pendiente', 'preparando', 'listo', 'en_camino', 'entregado', 'cancelado'];

class StaffHomePage extends ConsumerWidget {
  const StaffHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel de empleado'),
          actions: [
            IconButton(
                tooltip: 'Cerrar sesión',
                icon: const Icon(Icons.logout),
                onPressed: () => ref.read(authProvider.notifier).logout()),
          ],
          bottom: const TabBar(tabs: [
            Tab(icon: Icon(Icons.receipt_long), text: 'Pedidos'),
            Tab(icon: Icon(Icons.inventory_2), text: 'Inventario'),
          ]),
        ),
        body: const TabBarView(children: [_PedidosTab(), _InventarioTab()]),
      ),
    );
  }
}

class _PedidosTab extends ConsumerWidget {
  const _PedidosTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pedidos = ref.watch(todosPedidosProvider);
    return pedidos.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(errorMessage(e))),
      data: (list) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(todosPedidosProvider),
        child: list.isEmpty
            ? ListView(children: const [SizedBox(height: 160), Center(child: Text('Sin pedidos'))])
            : ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  for (final p in list)
                    PedidoCard(
                      pedido: p,
                      mostrarCliente: true,
                      actions: [
                        DropdownButton<String>(
                          value: _estados.contains(p.estado) ? p.estado : null,
                          hint: const Text('Cambiar estado'),
                          items: [
                            for (final e in _estados)
                              DropdownMenuItem(value: e, child: Text(estadoLabel(e)))
                          ],
                          onChanged: (v) async {
                            if (v == null || v == p.estado) return;
                            try {
                              await ref.read(ordersRepositoryProvider).cambiarEstado(p.id, v);
                              ref.invalidate(todosPedidosProvider);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(content: Text(errorMessage(e))));
                              }
                            }
                          },
                        ),
                      ],
                    ),
                ],
              ),
      ),
    );
  }
}

class _InventarioTab extends ConsumerWidget {
  const _InventarioTab();

  Future<void> _editar(BuildContext context, WidgetRef ref, int id, String nombre, int actual) async {
    final ctrl = TextEditingController(text: '$actual');
    final nuevo = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(nombre),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nuevo stock'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, int.tryParse(ctrl.text.trim())),
              child: const Text('Guardar')),
        ],
      ),
    );
    ctrl.dispose();
    if (nuevo == null || nuevo < 0) return;
    try {
      await ref.read(inventoryRepositoryProvider).fijarStock(id, nuevo);
      ref.invalidate(inventarioProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inv = ref.watch(inventarioProvider);
    return inv.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(errorMessage(e))),
      data: (list) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(inventarioProvider),
        child: ListView(
          children: [
            for (final i in list)
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(i.productoNombre),
                subtitle: Text(i.fechaVencimiento != null ? 'Vence: ${i.fechaVencimiento}' : ''),
                trailing: Text('${i.stockDisponible}',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: i.stockDisponible < 10 ? Colors.red : null)),
                onTap: () => _editar(context, ref, i.id, i.productoNombre, i.stockDisponible),
              ),
          ],
        ),
      ),
    );
  }
}
'@
W 'lib/features/staff/presentation/providers/staff_provider.dart' @'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/models/inventario_model.dart';
import '../../data/repositories/inventory_repository.dart';

final inventoryRepositoryProvider =
    Provider<InventoryRepository>((ref) => InventoryRepository(ref.read(dioProvider)));

final inventarioProvider = FutureProvider.autoDispose<List<Inventario>>(
    (ref) => ref.read(inventoryRepositoryProvider).listar());
'@
W 'API_CONTRACT.md' @'
# Contrato esperado de la API (ajústalo en `lib/core/network/api_endpoints.dart`)

Para usar la API real: `lib/core/config/app_config.dart` → `useMock = false` y configura `baseUrl`.
Todos los JSON usan snake_case. Las rutas (excepto login/register) llevan `Authorization: Bearer <token>`.

| Router | Método y ruta | Body / Query | Respuesta |
|---|---|---|---|
| auth | POST `/auth/login` | form: `username` (email), `password` | `{access_token, token_type}` |
| auth | POST `/auth/register` | `{nombre_completo, email, password, telefono}` | usuario |
| auth | GET `/auth/me` | – | `{id, nombre_completo, email, telefono, rol}` (rol: cliente / repartidor / empleado) |
| catalogo | GET `/catalogo/categorias` | – | `[{id, nombre, descripcion}]` |
| catalogo | GET `/catalogo/productos` | `?categoria_id=&q=` | `[{id, codigo_barras, nombre, descripcion, precio_base, imagen_url, activo, categoria_id}]` |
| direcciones | GET `/direcciones/municipios` | – | `[{id, nombre}]` |
| direcciones | GET `/direcciones` | – | `[{id, detalle_direccion, punto_referencia, municipio_id, municipio_nombre}]` |
| direcciones | POST `/direcciones` | `{detalle_direccion, punto_referencia, municipio_id}` | dirección |
| inventario | GET `/inventario` | – | `[{id, producto_id, producto_nombre, stock_disponible, fecha_vencimiento}]` |
| inventario | PATCH `/inventario/{id}` | `{stock_disponible}` | inventario |
| pedidos | POST `/pedidos` | `{items:[{producto_id,cantidad}], direccion_id, tipo_entrega (domicilio/retiro), metodo_pago (efectivo/tarjeta), canal}` | pedido |
| pedidos | GET `/pedidos/mis-pedidos` | – | `[pedido]` |
| pedidos | GET `/pedidos` | – (empleado) | `[pedido]` |
| pedidos | POST `/pedidos/{id}/cancelar` | – | pedido |
| pedidos | PATCH `/pedidos/{id}/estado` | `{estado}` (pendiente, preparando, listo, en_camino, entregado, cancelado) | pedido |
| repartidor | GET `/repartidor/pedidos` | – | `[pedido]` asignados |
| repartidor | PATCH `/repartidor/estado` | `{estado_operativo}` (disponible, en_ruta, descanso) | – |
| repartidor | POST `/repartidor/ubicacion` | `{latitud, longitud}` | – |
| repartidor | POST `/repartidor/pedidos/{id}/completar` | – | pedido |

`pedido` = `{id, canal, fecha_creacion, estado, tipo_entrega, metodo_pago, estado_pago, costo_envio, total, direccion, cliente_nombre, detalles:[{producto_id, nombre_producto, cantidad, precio_unitario, subtotal}]}`

Errores: `{"detail": "mensaje"}` (la app lo muestra tal cual).
'@
Write-Host 'Listo. Ahora ejecuta: flutter pub add flutter_riverpod dio flutter_secure_storage'