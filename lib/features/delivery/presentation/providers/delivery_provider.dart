import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../orders/data/models/pedido_models.dart';
import '../../data/repositories/delivery_repository.dart';

final deliveryRepositoryProvider =
    Provider<DeliveryRepository>((ref) => DeliveryRepository(ref.read(dioProvider)));

final pedidosAsignadosProvider = FutureProvider.autoDispose<List<Pedido>>(
    (ref) => ref.read(deliveryRepositoryProvider).asignados());