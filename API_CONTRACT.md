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