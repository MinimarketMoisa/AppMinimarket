import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/delivery/presentation/pages/delivery_home_page.dart';
import 'features/shell/client_shell.dart';
import 'features/staff/presentation/pages/staff_home_page.dart';

void main() => runApp(const ProviderScope(child: MinimarketApp()));

class MinimarketApp extends StatelessWidget {
  const MinimarketApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Minimarket',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _Root(),
      );
}

/// Decide qué pantalla mostrar según la sesión y el rol del usuario.
class _Root extends ConsumerWidget {
  const _Root();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(authProvider).when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, __) => const LoginPage(),
          data: (user) {
            if (user == null) return const LoginPage();
            switch (user.rol) {
              case 'repartidor':
                return const DeliveryHomePage();
              case 'empleado':
                return const StaffHomePage();
              default:
                return const ClientShell();
            }
          },
        );
  }
}