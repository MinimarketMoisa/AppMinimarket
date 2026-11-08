import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../catalog/presentation/providers/catalog_provider.dart';
import '../../../addresses/presentation/pages/addresses_page.dart';
import '../../../addresses/presentation/providers/addresses_provider.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../providers/cart_provider.dart';

class CartPage extends ConsumerStatefulWidget {
  final VoidCallback? onOrdered;
  const CartPage({super.key, this.onOrdered});
  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  String _entrega = 'domicilio';
  String _pago = 'contra_entrega';
  int? _dirId;
  int? _sucursalId;
  int? _pedidoTarjetaPendiente;
  bool _loading = false;
  final _numeroTarjeta = TextEditingController();
  final _nombreTitular = TextEditingController();
  final _mesExpiracion = TextEditingController();
  final _anioExpiracion = TextEditingController();
  final _cvv = TextEditingController();

  Widget _cartItemCard(CartItem item) {
    final theme = Theme.of(context);
    final product = item.producto;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 76,
                height: 76,
                child: product.imagenUrl == null || product.imagenUrl!.isEmpty
                    ? ColoredBox(
                        color: theme.colorScheme.primaryContainer,
                        child: Icon(
                          Icons.shopping_basket_outlined,
                          color: theme.colorScheme.primary,
                          size: 32,
                        ),
                      )
                    : Image.network(
                        product.imagenUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => ColoredBox(
                          color: theme.colorScheme.primaryContainer,
                          child: Icon(
                            Icons.shopping_basket_outlined,
                            color: theme.colorScheme.primary,
                            size: 32,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${money(product.precioBase)} por unidad',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _quantityButton(
                        icon: Icons.remove,
                        label: 'Quitar una unidad de ${product.nombre}',
                        onPressed: () =>
                            ref.read(cartProvider.notifier).decrement(product),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '${item.cantidad}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _quantityButton(
                        icon: Icons.add,
                        label: 'Agregar una unidad de ${product.nombre}',
                        onPressed: () =>
                            ref.read(cartProvider.notifier).add(product),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              money(item.subtotal),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quantityButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) => SizedBox(
    width: 32,
    height: 32,
    child: IconButton.filledTonal(
      padding: EdgeInsets.zero,
      tooltip: label,
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
    ),
  );

  @override
  void dispose() {
    _numeroTarjeta.dispose();
    _nombreTitular.dispose();
    _mesExpiracion.dispose();
    _anioExpiracion.dispose();
    _cvv.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    if (ref.read(authProvider).value == null) {
      await Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const LoginPage()));
      return;
    }
    final user = ref.read(authProvider).value;
    final items = ref.read(cartProvider);
    if (_entrega == 'domicilio' && _dirId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una dirección de entrega')),
      );
      return;
    }
    if (_entrega == 'retiro' && _sucursalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una sucursal para retirar')),
      );
      return;
    }
    if (_pago == 'tarjeta' && !_validarTarjeta()) return;
    setState(() => _loading = true);
    try {
      final repository = ref.read(ordersRepositoryProvider);
      if (_pago == 'tarjeta') {
        final pedidoId =
            _pedidoTarjetaPendiente ??
            (await repository.crear(
              items: [
                for (final i in items)
                  {'id_producto': i.producto.id, 'cantidad': i.cantidad},
              ],
              direccionId: _entrega == 'domicilio' ? _dirId : null,
              sucursalId: _entrega == 'retiro' ? _sucursalId : null,
              tipoEntrega: _entrega,
              metodoPago: _pago,
            )).id;
        _pedidoTarjetaPendiente = pedidoId;
        final result = await repository.simularPagoWompi(
          pedidoId: pedidoId,
          numeroTarjeta: _numeroTarjeta.text.replaceAll(RegExp(r'[\s-]'), ''),
          nombreTitular: _nombreTitular.text.trim().toUpperCase(),
          mesExpiracion: _mesExpiracion.text.trim().padLeft(2, '0'),
          anioExpiracion: _anioExpiracion.text.trim(),
          cvv: _cvv.text.trim(),
          emailPagador: user!.email,
        );
        final estado = (result['estado_transaccion'] ?? '')
            .toString()
            .toUpperCase();
        final mensaje = (result['mensaje'] ?? 'No se pudo procesar el pago')
            .toString();
        if (estado == 'APROBADA') {
          _pedidoTarjetaPendiente = null;
          ref.read(cartProvider.notifier).clear();
          ref.invalidate(misPedidosProvider);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '$mensaje${result['id_transaccion'] == null ? '' : ' Transacción: ${result['id_transaccion']}'}',
                ),
              ),
            );
            widget.onOrdered?.call();
          }
        } else if (estado == 'DECLINADA') {
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(mensaje)));
          }
        } else {
          throw StateError(
            'La API devolvió un estado de transacción no reconocido.',
          );
        }
      } else {
        await repository.crear(
          items: [
            for (final i in items)
              {'id_producto': i.producto.id, 'cantidad': i.cantidad},
          ],
          direccionId: _entrega == 'domicilio' ? _dirId : null,
          sucursalId: _entrega == 'retiro' ? _sucursalId : null,
          tipoEntrega: _entrega,
          metodoPago: _pago,
        );
        ref.read(cartProvider.notifier).clear();
        ref.invalidate(misPedidosProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Pedido realizado con éxito!')),
          );
          widget.onOrdered?.call();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _validarTarjeta() {
    final numero = _numeroTarjeta.text.replaceAll(RegExp(r'[\s-]'), '');
    final mes = int.tryParse(_mesExpiracion.text.trim());
    final anio = int.tryParse(_anioExpiracion.text.trim());
    final cvv = _cvv.text.trim();
    String? error;
    if (numero.length < 12 ||
        numero.length > 19 ||
        int.tryParse(numero) == null) {
      error = 'Ingresa un número de tarjeta válido';
    } else if (_nombreTitular.text.trim().isEmpty) {
      error = 'Ingresa el nombre del titular';
    } else if (mes == null || mes < 1 || mes > 12) {
      error = 'El mes de vencimiento debe estar entre 01 y 12';
    } else if (anio == null ||
        !{2, 4}.contains(_anioExpiracion.text.trim().length)) {
      error = 'Ingresa el año de vencimiento con dos o cuatro dígitos';
    } else if (cvv.length < 3 || cvv.length > 4 || int.tryParse(cvv) == null) {
      error = 'El CVV debe tener 3 o 4 dígitos';
    }
    if (error == null) return true;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    return false;
  }

  Future<void> _mostrarTarjetasPrueba() async {
    try {
      final cards = await ref
          .read(ordersRepositoryProvider)
          .tarjetasPruebaWompi();
      if (!mounted) return;
      if (cards is! List) {
        throw const FormatException(
          'El catálogo de tarjetas de prueba tiene un formato inválido.',
        );
      }
      final testCards = <Map<String, dynamic>>[];
      for (final entry in cards) {
        if (entry is! Map) {
          throw const FormatException(
            'Una tarjeta de prueba tiene un formato inválido.',
          );
        }
        testCards.add(Map<String, dynamic>.from(entry));
      }
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Tarjetas de prueba Wompi'),
          content: SizedBox(
            width: double.maxFinite,
            child: testCards.isEmpty
                ? const Text('No hay tarjetas de prueba disponibles.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: testCards.length * 2 - 1,
                    itemBuilder: (context, index) {
                      if (index.isOdd) return const Divider();
                      final card = testCards[index ~/ 2];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${card['tipo'] ?? 'Tarjeta'} · '
                          '${card['resultado'] ?? ''}',
                        ),
                        subtitle: Text(
                          '${card['descripcion'] ?? ''}\n'
                          '${card['numero'] ?? ''} · '
                          '${card['mes'] ?? ''}/${card['anio'] ?? ''} · '
                          'CVV ${card['cvv'] ?? ''}',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () {
                          _numeroTarjeta.text = (card['numero'] ?? '')
                              .toString();
                          _nombreTitular.text = (card['nombre_titular'] ?? '')
                              .toString();
                          _mesExpiracion.text = (card['mes'] ?? '').toString();
                          _anioExpiracion.text = (card['anio'] ?? '')
                              .toString();
                          _cvv.text = (card['cvv'] ?? '').toString();
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(cartProvider);
    final user = ref.watch(authProvider).value;
    if (items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Carrito')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primaryContainer,
                  child: Icon(
                    Icons.shopping_cart_outlined,
                    size: 42,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Tu carrito está esperando',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Explora el catálogo y agrega tus productos favoritos.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Carrito')),
        body: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 30),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tus productos están guardados en este dispositivo',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            for (final item in items) _cartItemCard(item),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Expanded(child: Text('Subtotal')),
                    Text(
                      money(ref.watch(cartTotalProvider)),
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tus productos permanecen en el carrito mientras sigues en la app. '
              'Inicia sesión o crea una cuenta para elegir la entrega y '
              'confirmar el pedido.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Iniciar sesión para continuar'),
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const LoginPage())),
            ),
          ],
        ),
      );
    }
    final subtotal = ref.watch(cartTotalProvider);
    final dirs = ref.watch(direccionesProvider);
    final sucursales = ref.watch(sucursalesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Carrito')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Text(
            'Revisa tu compra',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${items.fold<int>(0, (total, item) => total + item.cantidad)} productos en tu carrito',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          for (final i in items) _cartItemCard(i),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Entrega',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'domicilio',
                        label: Text('Domicilio'),
                        icon: Icon(Icons.delivery_dining),
                      ),
                      ButtonSegment(
                        value: 'retiro',
                        label: Text('Retiro'),
                        icon: Icon(Icons.store),
                      ),
                    ],
                    selected: {_entrega},
                    onSelectionChanged: (s) =>
                        setState(() => _entrega = s.first),
                  ),
                ],
              ),
            ),
          ),
          if (_entrega == 'domicilio') ...[
            const SizedBox(height: 12),
            dirs.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => AppErrorNotice(
                error: e,
                title: 'No pudimos cargar tus direcciones',
                onRetry: () => ref.invalidate(direccionesProvider),
              ),
              data: (list) => list.isEmpty
                  ? TextButton.icon(
                      icon: const Icon(Icons.add_location_alt),
                      label: const Text('Agrega una dirección para continuar'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AddressesPage(),
                        ),
                      ),
                    )
                  : DropdownButtonFormField<int>(
                      initialValue: list.any((d) => d.id == _dirId)
                          ? _dirId
                          : null,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Dirección de entrega',
                      ),
                      items: [
                        for (final d in list)
                          DropdownMenuItem(
                            value: d.id,
                            child: Text(
                              d.resumen,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (v) => setState(() => _dirId = v),
                    ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            sucursales.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => AppErrorNotice(
                error: e,
                title: 'No pudimos cargar las sucursales',
                onRetry: () => ref.invalidate(sucursalesProvider),
              ),
              data: (list) => DropdownButtonFormField<int>(
                initialValue: list.any((s) => s.id == _sucursalId)
                    ? _sucursalId
                    : null,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Sucursal de retiro',
                ),
                items: [
                  for (final s in list)
                    DropdownMenuItem(
                      value: s.id,
                      child: Text(
                        '${s.nombre} · ${s.direccion}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _sucursalId = v),
              ),
            ),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Método de pago',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'contra_entrega',
                        label: Text('Efectivo'),
                        icon: Icon(Icons.payments_outlined),
                      ),
                      ButtonSegment(
                        value: 'tarjeta',
                        label: Text('Crédito/débito'),
                        icon: Icon(Icons.credit_card),
                      ),
                    ],
                    selected: {_pago},
                    onSelectionChanged: _pedidoTarjetaPendiente == null
                        ? (s) => setState(() => _pago = s.first)
                        : null,
                  ),
                  if (_pago == 'tarjeta') ...[
                    const SizedBox(height: 12),
                    if (_pedidoTarjetaPendiente != null)
                      const Text(
                        'Este pedido ya fue creado. Puedes volver a intentar el pago '
                        'con tarjeta sin generar otro pedido.',
                      ),
                    TextFormField(
                      controller: _numeroTarjeta,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Número de tarjeta',
                        prefixIcon: Icon(Icons.credit_card),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nombreTitular,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del titular',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _mesExpiracion,
                            keyboardType: TextInputType.number,
                            maxLength: 2,
                            decoration: const InputDecoration(
                              labelText: 'Mes',
                              hintText: 'MM',
                              counterText: '',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _anioExpiracion,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            decoration: const InputDecoration(
                              labelText: 'Año',
                              hintText: 'AA / AAAA',
                              counterText: '',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _cvv,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            maxLength: 4,
                            decoration: const InputDecoration(
                              labelText: 'CVV',
                              counterText: '',
                            ),
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _loading ? null : _mostrarTarjetasPrueba,
                        icon: const Icon(Icons.info_outline),
                        label: const Text('Consultar tarjetas de prueba'),
                      ),
                    ),
                    const Text(
                      'Pago de prueba. Los datos de la tarjeta se envían directamente '
                      'a la API y no se guardan en la aplicación.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(child: Text('Subtotal')),
                      Text(money(subtotal)),
                    ],
                  ),
                  if (_entrega == 'domicilio') ...[
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Expanded(child: Text('Envío')),
                        Text('Se calcula al confirmar'),
                      ],
                    ),
                  ],
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _entrega == 'domicilio' ? 'Total estimado' : 'Total',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        money(subtotal),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loading ? null : _confirmar,
            icon: _loading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                _pedidoTarjetaPendiente != null
                    ? 'Reintentar pago'
                    : _pago == 'tarjeta'
                    ? 'Pagar con tarjeta'
                    : 'Confirmar pedido',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
