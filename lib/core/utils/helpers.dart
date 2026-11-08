import 'package:dio/dio.dart';

double toDouble(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

String money(num v) => '\$${v.toStringAsFixed(2)}';

String fechaCorta(DateTime? d) {
  if (d == null) return '';
  String t(int n) => n.toString().padLeft(2, '0');
  return '${t(d.day)}/${t(d.month)}/${d.year} ${t(d.hour)}:${t(d.minute)}';
}

String estadoLabel(String e) =>
    const {
      'pendiente': 'Pendiente',
      'preparado': 'Preparando',
      'preparando': 'Preparando',
      'en_ruta': 'En camino',
      'listo': 'Listo para retirar',
      'en_camino': 'En camino',
      'entregado': 'Entregado',
      'cancelado': 'Cancelado',
      'contra_entrega': 'Efectivo contra entrega',
      'tarjeta': 'Tarjeta crédito/débito',
      'pagado': 'Pagado',
    }[e] ??
    e;

/// Convierte cualquier error en un mensaje legible para el usuario.
String errorMessage(Object e) {
  if (e is DioException) {
    final statusCode = e.response?.statusCode;
    switch (statusCode) {
      case 401:
        return 'No pudimos validar tus datos. Revisa tu correo y contraseña e inténtalo de nuevo.';
      case 403:
        return 'Tu cuenta necesita una verificación adicional para continuar.';
      case 404:
        return 'No encontramos lo que buscabas. Actualiza la pantalla e inténtalo otra vez.';
      case 400:
        return 'No pudimos completar la solicitud. Revisa la información e inténtalo de nuevo.';
      case 409:
        return 'Esta acción ya no está disponible. Actualiza la pantalla e inténtalo de nuevo.';
      case 422:
        return 'Algunos datos no son válidos. Revísalos e inténtalo de nuevo.';
      case 429:
        return 'Estamos recibiendo muchas solicitudes. Espera un momento e inténtalo de nuevo.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'Tuvimos un problema temporal con el servicio. Inténtalo de nuevo en unos minutos.';
    }

    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'No pudimos conectar con Minimarket. Comprueba tu conexión a internet e inténtalo de nuevo.';
    }
    if (e.type == DioExceptionType.cancel) {
      return 'La solicitud se canceló. Puedes intentarlo de nuevo cuando quieras.';
    }
    return 'Ocurrió un problema inesperado. Inténtalo de nuevo.';
  }
  if (e is FormatException) {
    return 'La información recibida no tiene el formato esperado. Inténtalo de nuevo.';
  }
  if (e is StateError) return e.message;
  return 'Ocurrió un problema inesperado. Inténtalo de nuevo.';
}
