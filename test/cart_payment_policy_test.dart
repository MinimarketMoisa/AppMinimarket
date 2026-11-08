import 'package:flutter_test/flutter_test.dart';
import 'package:minimarket/features/cart/presentation/providers/cart_provider.dart';

void main() {
  test('card payment is required only when subtotal exceeds 50 dollars', () {
    expect(requierePagoConTarjeta(49.99), isFalse);
    expect(requierePagoConTarjeta(50), isFalse);
    expect(requierePagoConTarjeta(50.01), isTrue);
  });
}
