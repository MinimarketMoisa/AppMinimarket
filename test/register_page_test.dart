import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimarket/features/auth/presentation/pages/register_page.dart';

void main() {
  testWidgets('allows registration without a phone number', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: RegisterPage())),
    );

    final phoneField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Teléfono'),
    );
    expect(phoneField.validator, isNull);
  });
}
