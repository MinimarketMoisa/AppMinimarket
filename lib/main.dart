import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/catalog/presentation/pages/catalog_page.dart';

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

class _Root extends ConsumerWidget {
  const _Root();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(authProvider).when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, __) => const LoginPage(),
          data: (user) => user == null
              ? const LoginPage()
              : Scaffold(
                  body: const CatalogPage(),
                  floatingActionButton: FloatingActionButton.small(
                    onPressed: () => ref.read(authProvider.notifier).logout(),
                    child: const Icon(Icons.logout),
                  ),
                ),
        );
  }
}