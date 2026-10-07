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