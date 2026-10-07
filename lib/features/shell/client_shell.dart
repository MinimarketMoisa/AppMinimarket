import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/presentation/pages/profile_page.dart';
import '../cart/presentation/pages/cart_page.dart';
import '../cart/presentation/providers/cart_provider.dart';
import '../catalog/presentation/pages/catalog_page.dart';
import '../orders/presentation/pages/orders_page.dart';

class ClientShell extends ConsumerStatefulWidget {
  const ClientShell({super.key});
  @override
  ConsumerState<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends ConsumerState<ClientShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final count = ref.watch(cartCountProvider);
    return Scaffold(
      body: IndexedStack(index: _index, children: [
        const CatalogPage(),
        CartPage(onOrdered: () => setState(() => _index = 2)),
        const OrdersPage(),
        const ProfilePage(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.storefront_outlined), label: 'Catálogo'),
          NavigationDestination(
            icon: Badge(
                label: Text('$count'),
                isLabelVisible: count > 0,
                child: const Icon(Icons.shopping_cart_outlined)),
            label: 'Carrito',
          ),
          const NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Pedidos'),
          const NavigationDestination(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
    );
  }
}