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