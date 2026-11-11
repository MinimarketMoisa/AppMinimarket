import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../addresses/presentation/pages/addresses_page.dart';
import 'change_email_page.dart';
import 'driver_application_page.dart';
import 'login_page.dart';
import 'register_page.dart';
import '../providers/auth_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mi cuenta')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Compra como invitado',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Explora el catálogo y arma tu carrito. Inicia sesión o crea '
              'una cuenta para guardar direcciones y confirmar pedidos.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Iniciar sesión'),
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const LoginPage())),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Crear cuenta de cliente'),
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const RegisterPage())),
            ),
            const Divider(height: 36),
            Text(
              '¿Quieres repartir con nosotros?',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Las solicitudes se revisan antes de habilitar una cuenta de '
              'repartidor.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.delivery_dining),
              label: const Text('Solicitar acceso como repartidor'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const DriverApplicationPage(),
                ),
              ),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.badge_outlined),
              label: const Text('Ya tengo cuenta de repartidor'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LoginPage(driverLogin: true),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
          const SizedBox(height: 12),
          Center(
            child: Text(
              user.nombreCompleto,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Center(child: Text(user.email)),
          if (user.telefono != null) Center(child: Text(user.telefono!)),
          const SizedBox(height: 16),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.alternate_email),
            title: const Text('Cambiar correo electrónico'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ChangeEmailPage())),
          ),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Mis direcciones'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AddressesPage())),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delivery_dining_outlined),
            title: const Text('Solicitar acceso como repartidor'),
            subtitle: const Text(
              'Usa un correo sin cuenta; requiere aprobación de la empresa',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DriverApplicationPage()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Iniciar sesión como repartidor'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const LoginPage(driverLogin: true),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
        ],
      ),
    );
  }
}
