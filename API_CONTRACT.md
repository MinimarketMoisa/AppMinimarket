# Integración móvil con Minimarket API

## Configuración

- API HTTPS: `https://minimarket-api.duckdns.org`
- WebSocket: `wss://minimarket-api.duckdns.org`
- JWT: `Authorization: Bearer <TOKEN_JWT>`
- JSON: `Content-Type: application/json`
- Inicio de sesión: `application/x-www-form-urlencoded`
- `flutter_secure_storage` almacena el token de sesión.

Para desarrollo, se puede cambiar el host con `--dart-define=API_URL=...`.
Las respuestas `401` de una petición autenticada limpian la sesión y retornan
al inicio de sesión.

## Funciones móviles y rutas

La app expone únicamente los flujos CLIENTE y REPARTIDOR. Un repartidor puede
alternar a catálogo, carrito, pedidos y perfil sin cerrar sesión; el backend
sigue siendo responsable de autorizar las operaciones del rol.

| Función | Método y ruta | Datos principales |
|---|---|---|
| Iniciar sesión | POST `/auth/login` | Form: `username`, `password` |
| Registrar cliente | POST `/auth/registro` | `nombre_completo`, `email`, `password`, `telefono` opcional; requiere verificación antes de iniciar sesión |
| Verificar correo | POST `/auth/verificar-correo` | JSON: `{"token":"..."}` |
| Reenviar verificación | POST `/auth/reenviar-verificacion` | JSON: `{"email":"..."}` |
| Usuario autenticado | GET `/auth/me` | `id_usuario`, `nombre_completo`, `email`, `rol` |
| Categorías / catálogo | GET `/categorias`, `/productos` | Filtros `id_categoria`, `q` |
| Stock por sucursal | GET `/productos/{id_producto}/disponibilidad` | `id_sucursal`, `nombre_sucursal`, `stock_disponible` |
| Direcciones | GET/POST `/direcciones` | `id_municipio`, `detalle_direccion`, referencia y coordenadas opcionales |
| Crear pedido | POST `/pedidos` | `items`, `tipo_entrega`, `metodo_pago`, `canal: "APP"` |
| Historial | GET `/pedidos/mis-pedidos` | Pedidos del cliente |
| Seguimiento REST | GET `/pedidos/{id}/seguimiento` | Sucursal, destino y repartidor |
| Seguimiento en vivo | WS `/pedidos/{id}/ws/seguimiento?token=...` | JWT en query; el servidor debe validar formato y mensajes |
| Reenviar factura | POST `/pedidos/{id}/enviar-factura` | Sin body |
| Denunciar repartidor | POST `/pedidos/{id}/denunciar` | `{"motivo":"..."}` |
| Pedido entrante | GET `/repartidor/pedido-entrante` | Pedido o `null` |
| Aceptar / rechazar | POST `/repartidor/pedidos/{id}/aceptar`, `/repartidor/pedidos/{id}/rechazar` | Rechazo: `motivo` |
| Entregas activas | GET `/repartidor/mis-entregas` | Pedidos asignados |
| Ubicación | PATCH `/repartidor/ubicacion` | `latitud`, `longitud`; la app envía cada 8 s mientras el repartidor lo activa |
| Disponibilidad | PATCH `/repartidor/estado` | `LIBRE` o `PENDIENTE` |
| Estado del pedido | PATCH `/pedidos/{id}/estado` | `EN_RUTA` o `ENTREGADO` |

El pedido se crea con `items: [{"id_producto": 1, "cantidad": 2}]`,
`tipo_entrega: "DOMICILIO"` o `"RETIRO"`, `metodo_pago:
"CONTRA_ENTREGA"` o `"TRANSFERENCIA"` y `canal: "APP"`. Domicilio usa
`id_direccion`; retiro usa `id_sucursal`.

## Validación contra la API desplegada

La app se ajusta al OpenAPI publicado por el host desplegado. El flujo de
registro muestra la pantalla de verificación y no inicia sesión automáticamente.
Si el correo no llega, se puede solicitar un reenvío desde esa pantalla. La
entrega efectiva del correo depende de la configuración SMTP/correo del backend.
`ProductoOut` no
declara stock; la app obtiene ese dato desde la ruta de disponibilidad por
sucursal. Las rutas WebSocket no aparecen en OpenAPI y deben probarse con el
backend, incluidos autenticación y formato de los mensajes. Durante la
comprobación de integración, las peticiones GET públicas a `/productos` y
`/categorias` respondieron HTTP 502; se requiere revalidarlas cuando el
servicio esté disponible.

## Desarrollo local

```powershell
flutter run --dart-define=API_URL=http://10.0.2.2:8000
```

En un dispositivo físico, sustituye la URL por una dirección LAN accesible.
No se deben registrar contraseñas, tokens ni secretos.
