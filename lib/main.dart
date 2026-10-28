import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/utils/helpers.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/delivery/presentation/pages/delivery_home_page.dart';
import 'features/shell/client_shell.dart';
import 'core/network/session_expiry.dart';

void main() => runApp(const ProviderScope(child: MinimarketApp()));

class MinimarketApp extends StatelessWidget {
  const MinimarketApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Minimarket',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: const _Root(),
    routes: {
      '/client': (_) => const ClientShell(),
      '/delivery': (_) => const DeliveryHomePage(),
    },
  );
}

/// Decide qué pantalla mostrar según la sesión y el rol del usuario.
class _Root extends ConsumerWidget {
  const _Root();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(sessionExpiryProvider, (previous, next) {
      if (previous != null && next > previous) ref.invalidate(authProvider);
    });
    return ref
        .watch(authProvider)
        .when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, _) => Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(errorMessage(error), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => ref.invalidate(authProvider),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
          data: (user) {
            if (user == null) return const LoginPage();
            switch (user.rol) {
              case 'repartidor':
                return const DeliveryHomePage();
              case 'cliente':
                return const ClientShell();
              default:
                return _UnsupportedRolePage(rol: user.rol);
            }
          },
        );
  }
}

class _UnsupportedRolePage extends ConsumerWidget {
  const _UnsupportedRolePage({required this.rol});

  final String rol;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_accounts_outlined, size: 48),
            const SizedBox(height: 12),
            Text('El rol "$rol" no está habilitado en esta aplicación.'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              child: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    ),
  );
}
