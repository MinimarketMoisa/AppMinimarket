import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimarket/features/auth/domain/entities/user_entity.dart';
import 'package:minimarket/features/auth/domain/repositories/auth_repository.dart';
import 'package:minimarket/features/auth/presentation/pages/change_email_page.dart';
import 'package:minimarket/features/auth/presentation/pages/driver_application_page.dart';
import 'package:minimarket/features/auth/presentation/pages/email_verification_page.dart';
import 'package:minimarket/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:minimarket/features/auth/presentation/pages/login_page.dart';
import 'package:minimarket/features/auth/presentation/pages/profile_page.dart';
import 'package:minimarket/features/auth/presentation/providers/auth_provider.dart';

class _FakeAuthRepository implements AuthRepository {
  String? resentEmail;
  String? applicantEmail;
  String? resetRequestEmail;
  String? verificationStatusEmail;
  String? newEmailRequested;
  String? emailChangePassword;
  String? emailChangeToken;
  bool emailVerified = false;
  Object? loginFailure;

  @override
  Future<UserEntity?> currentUser() async => null;

  @override
  Future<UserEntity> login(String email, String password) async {
    if (loginFailure != null) throw loginFailure!;
    return const UserEntity(
      id: 1,
      nombreCompleto: 'Cliente',
      email: 'cliente@example.com',
      rol: 'cliente',
    );
  }

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
  Future<String> applyAsCourier({
    required String nombreCompleto,
    required String email,
    required String password,
    required String telefono,
    String? placaVehiculo,
  }) async {
    applicantEmail = email;
    return 'Solicitud recibida.';
  }

  @override
  Future<String> resendVerification(String email) async {
    resentEmail = email;
    return 'Correo reenviado.';
  }

  @override
  Future<String> requestPasswordReset(String email) async {
    resetRequestEmail = email;
    return 'Si el correo está registrado, recibirás instrucciones.';
  }

  @override
  @override
  Future<bool> isEmailVerified(String email) async {
    verificationStatusEmail = email;
    return emailVerified;
  }

  @override
  Future<String> requestEmailChange({
    required String newEmail,
    required String password,
  }) async {
    newEmailRequested = newEmail;
    emailChangePassword = password;
    return 'Código enviado al nuevo correo.';
  }

  @override
  Future<String> confirmEmailChange(String token) async {
    emailChangeToken = token;
    return 'Correo actualizado.';
  }
}

void main() {
  testWidgets('guest account offers customer and courier access', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
        child: const MaterialApp(home: ProfilePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Compra como invitado'), findsOneWidget);
    expect(find.text('Crear cuenta de cliente'), findsOneWidget);
    expect(find.text('Solicitar acceso como repartidor'), findsOneWidget);
    expect(find.text('Ya tengo cuenta de repartidor'), findsOneWidget);
  });

  testWidgets('courier application submits and waits for approval', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          home: const DriverApplicationPage(),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre completo'),
      'Persona Repartidora',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo electrónico'),
      'persona@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Teléfono'),
      '70000000',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña para tu cuenta'),
      'ClaveSegura123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirmar contraseña'),
      'ClaveSegura123',
    );
    await tester.ensureVisible(find.text('Enviar solicitud'));
    await tester.tap(find.text('Enviar solicitud'));
    await tester.pumpAndSettle();

    expect(repository.applicantEmail, 'persona@example.com');
    expect(find.text('Solicitud enviada'), findsOneWidget);
    expect(find.textContaining('administrador apruebe'), findsOneWidget);
  });

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

    await tester.tap(find.text('Reenviar correo'));
    await tester.pumpAndSettle();

    expect(repository.resentEmail, 'cliente@example.com');
    expect(find.text('Correo reenviado.'), findsOneWidget);
  });

  testWidgets('checks the verification status for the entered email', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          home: EmailVerificationPage(initialEmail: 'cliente@example.com'),
        ),
      ),
    );

    await tester.tap(find.text('Ya verifiqué mi correo'));
    await tester.pumpAndSettle();

    expect(repository.verificationStatusEmail, 'cliente@example.com');
    expect(
      find.textContaining('Aún no aparece la verificación'),
      findsOneWidget,
    );
  });

  testWidgets('requests a password reset for completion in the browser', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          home: ForgotPasswordPage(initialEmail: 'cliente@example.com'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar instrucciones'));
    await tester.pumpAndSettle();

    expect(repository.resetRequestEmail, 'cliente@example.com');
    expect(find.text('Revisa tu correo'), findsOneWidget);
    expect(
      find.textContaining(
        'Ábrelo desde tu correo para continuar en el navegador',
      ),
      findsOneWidget,
    );
    expect(find.text('Token o enlace de recuperación'), findsNothing);
    expect(find.text('Nueva contraseña'), findsNothing);
  });

  testWidgets('submits the long email-change code and returns to login', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: ChangeEmailPage()),
      ),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nuevo correo'),
      'nuevo@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña actual'),
      'ClaveActual123',
    );
    await tester.tap(find.text('Enviar código'));
    await tester.pumpAndSettle();

    expect(repository.newEmailRequested, 'nuevo@example.com');
    expect(repository.emailChangePassword, 'ClaveActual123');
    expect(find.text('Código de confirmación'), findsOneWidget);

    const longJwt = 'header.payload.signature-that-is-not-six-digits';
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Código de confirmación'),
      longJwt,
    );
    await tester.tap(find.text('Confirmar cambio'));
    await tester.pumpAndSettle();

    expect(repository.emailChangeToken, longJwt);
    expect(find.text('Iniciar sesión'), findsNWidgets(2));
  });

  testWidgets('only offers verification for an unverified-email 403', (
    tester,
  ) async {
    final repository = _FakeAuthRepository()
      ..loginFailure = DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 403,
          data: {'detail': 'Debes verificar tu correo electrónico.'},
        ),
      );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: LoginPage()),
      ),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo'),
      'cliente@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'Clave123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Verificar o reenviar correo'), findsOneWidget);
  });

  testWidgets('does not send a disabled-account 403 to email verification', (
    tester,
  ) async {
    final repository = _FakeAuthRepository()
      ..loginFailure = DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 403,
          data: {'detail': 'La cuenta está desactivada.'},
        ),
      );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: LoginPage()),
      ),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo'),
      'cliente@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'Clave123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Verificar o reenviar correo'), findsNothing);
  });
}
