import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimarket/features/orders/data/models/pedido_models.dart';
import 'package:minimarket/features/orders/presentation/widgets/pedido_card.dart';

void main() {
  testWidgets('shows a call action when a customer phone is available', (
    tester,
  ) async {
    final pedido = Pedido.fromJson({
      'id_pedido': 1,
      'canal': 'APP',
      'estado': 'PREPARADO',
      'tipo_entrega': 'DOMICILIO',
      'metodo_pago': 'CONTRA_ENTREGA',
      'estado_pago': 'PENDIENTE',
      'costo_envio': 1,
      'total': 10,
      'cliente': {
        'nombre_completo': 'Cliente Demo',
        'telefono': '+503 7000-0000',
      },
      'detalles': [],
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PedidoCard(
            pedido: pedido,
            mostrarCliente: true,
            actions: const [SizedBox.shrink()],
          ),
        ),
      ),
    );

    expect(find.text('Teléfono: +503 7000-0000'), findsOneWidget);
    expect(find.text('Llamar al cliente'), findsOneWidget);
  });
}
