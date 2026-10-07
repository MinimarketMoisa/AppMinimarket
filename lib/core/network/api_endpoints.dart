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