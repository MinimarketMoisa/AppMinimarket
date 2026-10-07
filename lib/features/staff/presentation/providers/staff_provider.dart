import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/models/inventario_model.dart';
import '../../data/repositories/inventory_repository.dart';

final inventoryRepositoryProvider =
    Provider<InventoryRepository>((ref) => InventoryRepository(ref.read(dioProvider)));

final inventarioProvider = FutureProvider.autoDispose<List<Inventario>>(
    (ref) => ref.read(inventoryRepositoryProvider).listar());