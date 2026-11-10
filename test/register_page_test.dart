import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimarket/features/auth/presentation/pages/register_page.dart';

void main() {
  testWidgets('requires a phone number to create a customer account', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: RegisterPage()),
      ),
    );

    await tester.ensureVisible(find.text('Registrarme'));
    await tester.tap(find.text('Registrarme'));
    await tester.pump();

    expect(find.text('Ingresa un teléfono válido'), findsOneWidget);
  });
}
