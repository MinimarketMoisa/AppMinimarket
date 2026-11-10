import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimarket/core/theme/app_theme.dart';
import 'package:minimarket/features/addresses/data/models/direccion_models.dart';
import 'package:minimarket/features/addresses/presentation/providers/addresses_provider.dart';
import 'package:minimarket/features/auth/domain/entities/user_entity.dart';
import 'package:minimarket/features/auth/presentation/providers/auth_provider.dart';
import 'package:minimarket/features/cart/presentation/pages/cart_page.dart';
import 'package:minimarket/features/cart/presentation/providers/cart_provider.dart';
import 'package:minimarket/features/catalog/data/models/catalogo_models.dart';
import 'package:minimarket/features/catalog/presentation/providers/catalog_provider.dart';

class _SignedInNotifier extends AuthNotifier {
  @override
  Future<UserEntity?> build() async => const UserEntity(
    id: 1,
    nombreCompleto: 'Cliente de prueba',
    email: 'cliente@example.com',
    rol: 'cliente',
  );
}

class _CartWithItems extends CartNotifier {
  @override
  List<CartItem> build() => [
    for (var id = 1; id <= 6; id++)
      CartItem(
        Producto(id: id, nombre: 'Producto $id', precioBase: 5, activo: true),
        1,
      ),
  ];
}

void main() {
  testWidgets('keeps subtotal and order button visible while cart scrolls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_SignedInNotifier.new),
          cartProvider.overrideWith(_CartWithItems.new),
          direccionesProvider.overrideWith((ref) async => <Direccion>[]),
          sucursalesProvider.overrideWith((ref) async => <Sucursal>[]),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const CartPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Subtotal'), findsOneWidget);
    expect(find.text('Confirmar pedido'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('Subtotal'), findsOneWidget);
    expect(find.text('Confirmar pedido'), findsOneWidget);
  });
}
