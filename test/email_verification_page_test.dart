import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimarket/features/auth/domain/entities/user_entity.dart';
import 'package:minimarket/features/auth/domain/repositories/auth_repository.dart';
import 'package:minimarket/features/auth/presentation/pages/email_verification_page.dart';
import 'package:minimarket/features/auth/presentation/providers/auth_provider.dart';

class _FakeAuthRepository implements AuthRepository {
  String? verifiedToken;
  String? resentEmail;

  @override
  Future<UserEntity?> currentUser() async => null;

  @override
  Future<UserEntity> login(String email, String password) async =>
      const UserEntity(
        id: 1,
        nombreCompleto: 'Cliente',
        email: 'cliente@example.com',
        rol: 'cliente',
      );

  @override
  Future<void> logout() async {}

  @override
  Future<String?> register({
    required String nombreCompleto,
    required String email,
    required String password,
    String? telefono,
  }) async => 'Revisa tu correo.';

  @override
  Future<String> resendVerification(String email) async {
    resentEmail = email;
    return 'Correo reenviado.';
  }

  @override
  Future<String> verifyEmail(String token) async {
    verifiedToken = token;
    return 'Correo verificado.';
  }
}

void main() {
  testWidgets('resends verification to the entered email', (tester) async {
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          home: EmailVerificationPage(initialEmail: 'cliente@example.com'),
        ),
      ),
    );

    await tester.tap(find.text('Reenviar correo de verificación'));
    await tester.pumpAndSettle();

    expect(repository.resentEmail, 'cliente@example.com');
    expect(find.text('Correo reenviado.'), findsOneWidget);
  });

  testWidgets('submits a verification token', (tester) async {
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          home: EmailVerificationPage(initialEmail: 'cliente@example.com'),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Token o enlace del correo'),
      'verification-token',
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(repository.verifiedToken, 'verification-token');
    expect(find.text('Correo verificado.'), findsAtLeastNWidgets(1));
  });
}
