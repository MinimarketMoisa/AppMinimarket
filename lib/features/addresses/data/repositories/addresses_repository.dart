import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../models/direccion_models.dart';

class AddressesRepository {
  final Dio dio;
  AddressesRepository(this.dio);

  Future<List<Direccion>> listar() async {
    final r = await dio.get(ApiEndpoints.direcciones);
    return (r.data as List)
        .map((e) => Direccion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Municipio>> municipios() async {
    final r = await dio.get(ApiEndpoints.municipios);
    return (r.data as List)
        .map((e) => Municipio.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> crear({
    required String detalle,
    String? referencia,
    required int municipioId,
    double? latitud,
    double? longitud,
  }) async {
    await dio.post(
      ApiEndpoints.direcciones,
      data: {
        'detalle_direccion': detalle,
        'punto_referencia': referencia,
        'id_municipio': municipioId,
        'latitud': ?latitud,
        'longitud': ?longitud,
      },
    );
  }
}
