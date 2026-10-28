/// Rutas de la API móvil desplegada.
class ApiEndpoints {
  // Autenticación
  static const login = '/auth/login'; // POST form: username(email), password
  static const register = '/auth/registro'; // POST json
  static const me = '/auth/me'; // GET

  // Catálogo
  static const categorias = '/categorias'; // GET
  static const productos = '/productos'; // GET ?id_categoria=&q=
  static String disponibilidadProducto(int id) =>
      '/productos/$id/disponibilidad'; // GET por sucursal

  // Direcciones
  static const municipios = '/municipios'; // GET
  static const direcciones = '/direcciones'; // GET, POST
  static const sucursales = '/sucursales'; // GET

  // Pedidos de cliente
  static const pedidos = '/pedidos'; // POST
  static const misPedidos = '/pedidos/mis-pedidos'; // GET
  static String estadoPedido(int id) => '/pedidos/$id/estado'; // PATCH {estado}
  static String seguimientoPedido(int id) => '/pedidos/$id/seguimiento'; // GET
  static String seguimientoEnVivo(int id) =>
      '/pedidos/$id/ws/seguimiento'; // WebSocket
  static String enviarFactura(int id) => '/pedidos/$id/enviar-factura'; // POST
  static String denunciarRepartidor(int id) =>
      '/pedidos/$id/denunciar'; // POST {motivo}

  // Repartidor
  static const repartidorEntrante = '/repartidor/pedido-entrante'; // GET
  static const repartidorPedidos = '/repartidor/mis-entregas'; // GET
  static String aceptarPedidoRepartidor(int id) =>
      '/repartidor/pedidos/$id/aceptar'; // POST
  static String rechazarPedidoRepartidor(int id) =>
      '/repartidor/pedidos/$id/rechazar'; // POST {motivo}
  static const repartidorEstado = '/repartidor/estado'; // PATCH {estado}
  static const repartidorUbicacion =
      '/repartidor/ubicacion'; // PATCH {latitud, longitud}
}
