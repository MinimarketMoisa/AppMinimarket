import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/models/pedido_models.dart';
import '../../data/repositories/orders_repository.dart';

final ordersRepositoryProvider =
    Provider<OrdersRepository>((ref) => OrdersRepository(ref.read(dioProvider)));

final misPedidosProvider = FutureProvider.autoDispose<List<Pedido>>(
    (ref) => ref.read(ordersRepositoryProvider).misPedidos());

final todosPedidosProvider = FutureProvider.autoDispose<List<Pedido>>(
    (ref) => ref.read(ordersRepositoryProvider).todos());