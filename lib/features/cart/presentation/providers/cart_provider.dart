import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../catalog/data/models/catalogo_models.dart';

class CartItem {
  final Producto producto;
  final int cantidad;
  const CartItem(this.producto, this.cantidad);
  double get subtotal => producto.precioBase * cantidad;
}

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  void add(Producto p) {
    final i = state.indexWhere((e) => e.producto.id == p.id);
    if (i == -1) {
      state = [...state, CartItem(p, 1)];
    } else {
      state = [
        for (var k = 0; k < state.length; k++)
          if (k == i) CartItem(p, state[k].cantidad + 1) else state[k]
      ];
    }
  }

  void decrement(Producto p) {
    final i = state.indexWhere((e) => e.producto.id == p.id);
    if (i == -1) return;
    if (state[i].cantidad <= 1) {
      remove(p.id);
    } else {
      state = [
        for (var k = 0; k < state.length; k++)
          if (k == i) CartItem(p, state[k].cantidad - 1) else state[k]
      ];
    }
  }

  void remove(int productoId) =>
      state = state.where((e) => e.producto.id != productoId).toList();

  void clear() => state = [];
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);

final cartTotalProvider =
    Provider<double>((ref) => ref.watch(cartProvider).fold(0.0, (s, e) => s + e.subtotal));

final cartCountProvider =
    Provider<int>((ref) => ref.watch(cartProvider).fold(0, (s, e) => s + e.cantidad));