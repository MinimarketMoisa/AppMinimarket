import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/network/session_expiry.dart';
import '../../../../core/utils/helpers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../orders/presentation/widgets/pedido_card.dart';
import '../../../orders/presentation/widgets/tracking_map.dart';
import '../providers/delivery_provider.dart';

class DeliveryHomePage extends ConsumerStatefulWidget {
  const DeliveryHomePage({super.key});
  @override
  ConsumerState<DeliveryHomePage> createState() => _DeliveryHomePageState();
}

class _DeliveryHomePageState extends ConsumerState<DeliveryHomePage> {
  String _estado = 'LIBRE';
  StreamSubscription<Position>? _locationSubscription;
  Timer? _locationTimer;
  Position? _latestPosition;
  Map<String, dynamic>? _deliveryTracking;
  Object? _trackingError;
  int? _trackingOrderId;
  bool _trackingLoading = false;
  bool _sendingLocation = false;
  bool _startingLocationSharing = false;
  bool _sharingLocation = false;
  bool _changingAvailability = false;
  bool _hasActiveDelivery = false;
  int? _processingIncomingOrderId;
  bool _rejectingIncomingOrder = false;
  final Set<int> _processingOrderIds = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    final subscription = _locationSubscription;
    if (subscription != null) unawaited(subscription.cancel());
    super.dispose();
  }

  void _msg(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _cambiarEstado(String estadoUi) async {
    if (_changingAvailability) return;
    setState(() => _changingAvailability = true);
    try {
      final estadoApi = estadoUi == 'disponible' ? 'LIBRE' : 'PENDIENTE';
      await ref.read(deliveryRepositoryProvider).cambiarEstado(estadoApi);
      if (mounted) {
        setState(() => _estado = estadoApi);
        if (estadoApi == 'LIBRE') {
          if (_hasActiveDelivery) {
            await _startLocationSharing();
          } else {
            _stopLocationSharing();
          }
        } else if (!_hasActiveDelivery) {
          _stopLocationSharing();
        }
      }
    } catch (error) {
      _msg(errorMessage(error));
    } finally {
      if (mounted) setState(() => _changingAvailability = false);
    }
  }

  Future<void> _startLocationSharing() async {
    if (_sharingLocation || _startingLocationSharing || !mounted) return;
    _startingLocationSharing = true;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Activa los servicios de ubicación del dispositivo');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(
          'Permite el acceso a la ubicación para compartir tu posición',
        );
      }
      if (Platform.isIOS && permission != LocationPermission.always) {
        throw Exception(
          'Para compartir ubicación en segundo plano, permite el acceso '
          '"Siempre" en los ajustes de ubicación de la app.',
        );
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 20),
        ),
      );
      _updateLocalPosition(position);
      await _sendLocation(position);
      if (!mounted) return;
      setState(() => _sharingLocation = true);
      _locationSubscription =
          Geolocator.getPositionStream(
            locationSettings: _backgroundLocationSettings(),
          ).listen(
            _updateLocalPosition,
            onError: (Object error) {
              _stopLocationSharing();
              _msg(errorMessage(error));
            },
          );
      _locationTimer?.cancel();
      _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        final latestPosition = _latestPosition;
        if (latestPosition != null) unawaited(_sendLocation(latestPosition));
      });
    } catch (error) {
      _msg(errorMessage(error));
    } finally {
      _startingLocationSharing = false;
    }
  }

  void _updateLocalPosition(Position position) {
    _latestPosition = position;
    if (mounted) setState(() {});
  }

  Future<void> _loadDeliveryTracking(int pedidoId) async {
    if (_trackingOrderId == pedidoId &&
        (_deliveryTracking != null || _trackingLoading)) {
      return;
    }
    setState(() {
      _trackingOrderId = pedidoId;
      _deliveryTracking = null;
      _trackingError = null;
      _trackingLoading = true;
    });
    try {
      final tracking = await ref
          .read(deliveryRepositoryProvider)
          .seguimiento(pedidoId);
      if (!mounted || _trackingOrderId != pedidoId) return;
      setState(() {
        _deliveryTracking = tracking;
        _trackingLoading = false;
      });
    } catch (error) {
      if (!mounted || _trackingOrderId != pedidoId) return;
      setState(() {
        _trackingError = error;
        _trackingLoading = false;
      });
    }
  }

  Widget _deliveryRouteSection() {
    final tracking = _deliveryTracking;
    if (tracking != null) {
      final position = _latestPosition;
      final rider = tracking['repartidor'];
      final trackingWithMyPosition = position == null
          ? tracking
          : {
              ...tracking,
              'repartidor': {
                if (rider is Map) ...Map<String, dynamic>.from(rider),
                'latitud': position.latitude,
                'longitud': position.longitude,
                'rumbo': position.heading,
                'velocidad': position.speed,
              },
            };
      return TrackingMap(
        tracking: trackingWithMyPosition,
        title: 'Ruta de entrega',
        riderLabel: 'Tu ubicación',
        fitRoute: true,
      );
    }
    if (_trackingError != null) {
      return Card(
        child: ListTile(
          title: const Text('No se pudo cargar la ruta'),
          subtitle: Text(errorMessage(_trackingError!)),
          trailing: IconButton(
            tooltip: 'Reintentar',
            onPressed: _trackingOrderId == null || _trackingLoading
                ? null
                : () => _loadDeliveryTracking(_trackingOrderId!),
            icon: const Icon(Icons.refresh),
          ),
        ),
      );
    }
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(),
      ),
    );
  }

  LocationSettings _backgroundLocationSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 5),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Minimarket - ubicación activa',
          notificationText: 'Compartiendo ubicación para tus entregas',
          notificationChannelName: 'Ubicación del repartidor',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }
    if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );
  }

  Future<void> _sendLocation(Position position) async {
    if (_sendingLocation) return;
    _sendingLocation = true;
    try {
      await ref
          .read(deliveryRepositoryProvider)
          .actualizarUbicacion(
            latitud: position.latitude,
            longitud: position.longitude,
            rumbo: position.heading,
            velocidad: position.speed,
          );
    } catch (error) {
      _stopLocationSharing();
      _msg(errorMessage(error));
    } finally {
      _sendingLocation = false;
    }
  }

  void _stopLocationSharing() {
    _locationTimer?.cancel();
    _locationTimer = null;
    final subscription = _locationSubscription;
    _locationSubscription = null;
    if (subscription != null) unawaited(subscription.cancel());
    if (_sharingLocation && mounted) {
      setState(() => _sharingLocation = false);
    } else {
      _sharingLocation = false;
    }
  }

  Future<void> _toggleLocationSharing() async {
    if (_sharingLocation) {
      _stopLocationSharing();
    } else {
      await _startLocationSharing();
    }
  }

  Future<String?> _askRejectionReason() => showDialog<String>(
    context: context,
    builder: (context) {
      var reason = '';
      return StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Rechazar pedido'),
          content: TextField(
            autofocus: true,
            maxLength: 200,
            onChanged: (value) => setDialogState(() => reason = value),
            decoration: const InputDecoration(labelText: 'Motivo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: reason.trim().length < 3
                  ? null
                  : () => Navigator.pop(context, reason.trim()),
              child: const Text('Rechazar'),
            ),
          ],
        ),
      );
    },
  );

  Future<void> _accept(int pedidoId) async {
    if (_processingIncomingOrderId != null) return;
    setState(() => _processingIncomingOrderId = pedidoId);
    try {
      await ref.read(deliveryRepositoryProvider).aceptar(pedidoId);
      if (!mounted) return;
      setState(() => _hasActiveDelivery = true);
      unawaited(_loadDeliveryTracking(pedidoId));
      ref.invalidate(pedidoEntranteProvider);
      ref.invalidate(pedidosAsignadosProvider);
      _msg('Pedido aceptado');
      unawaited(_startLocationSharing());
    } catch (error) {
      if (mounted) {
        ref.invalidate(pedidoEntranteProvider);
        ref.invalidate(pedidosAsignadosProvider);
        _msg(errorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _processingIncomingOrderId = null);
    }
  }

  Future<void> _reject(int pedidoId) async {
    if (_processingIncomingOrderId != null) return;
    setState(() {
      _processingIncomingOrderId = pedidoId;
      _rejectingIncomingOrder = true;
    });
    try {
      final reason = await _askRejectionReason();
      if (reason == null || !mounted) return;
      await ref.read(deliveryRepositoryProvider).rechazar(pedidoId, reason);
      if (!mounted) return;
      ref.invalidate(pedidoEntranteProvider);
      ref.invalidate(pedidosAsignadosProvider);
      _msg('Pedido rechazado');
    } catch (error) {
      if (mounted) {
        ref.invalidate(pedidoEntranteProvider);
        ref.invalidate(pedidosAsignadosProvider);
        _msg(errorMessage(error));
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingIncomingOrderId = null;
          _rejectingIncomingOrder = false;
        });
      }
    }
  }

  Future<void> _changeOrderState(int id, String state) async {
    if (!_processingOrderIds.add(id)) return;
    setState(() {});
    try {
      await ref.read(deliveryRepositoryProvider).cambiarEstadoPedido(id, state);
      if (!mounted) return;
      ref.invalidate(pedidosAsignadosProvider);
      if (state == 'EN_RUTA') {
        unawaited(_startLocationSharing());
      }
      _msg(state == 'ENTREGADO' ? 'Entrega completada' : 'Ruta iniciada');
    } catch (error) {
      if (mounted) {
        ref.invalidate(pedidosAsignadosProvider);
        _msg(errorMessage(error));
      }
    } finally {
      if (mounted) {
        setState(() => _processingOrderIds.remove(id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sessionExpiryProvider, (previous, next) {
      if (previous != null && next > previous) {
        _stopLocationSharing();
        ref.invalidate(authProvider);
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
    ref.listen(pedidosAsignadosProvider, (_, next) {
      next.whenData((list) {
        final activeOrders = list
            .where(
              (pedido) =>
                  pedido.estado != 'entregado' && pedido.estado != 'cancelado',
            )
            .toList();
        _hasActiveDelivery = activeOrders.isNotEmpty;
        if (_hasActiveDelivery) {
          unawaited(_loadDeliveryTracking(activeOrders.first.id));
          _startLocationSharing();
        } else {
          _trackingOrderId = null;
          _deliveryTracking = null;
          _trackingError = null;
          _trackingLoading = false;
          _stopLocationSharing();
        }
      });
    });
    final user = ref.watch(authProvider).value;
    final pedidos = ref.watch(pedidosAsignadosProvider);
    final entrante = ref.watch(pedidoEntranteProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${user?.nombreCompleto.split(' ').first ?? ''}'),
        actions: [
          IconButton(
            tooltip: 'Ir a comprar',
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () => Navigator.of(context)
                .pushNamedAndRemoveUntil('/client', (route) => route.isFirst),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(_estado),
                    initialValue: _estado == 'LIBRE'
                        ? 'disponible'
                        : 'no_disponible',
                    decoration: const InputDecoration(
                      labelText: 'Mi estado',
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'disponible',
                        child: Text('Disponible'),
                      ),
                      DropdownMenuItem(
                        value: 'no_disponible',
                        child: Text('No disponible'),
                      ),
                    ],
                    onChanged: _changingAvailability
                        ? null
                        : (value) =>
                              value == null ? null : _cambiarEstado(value),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _hasActiveDelivery && _sharingLocation
                      ? null
                      : _toggleLocationSharing,
                  icon: Icon(
                    _sharingLocation ? Icons.location_off : Icons.my_location,
                  ),
                  label: Text(
                    _sharingLocation
                        ? 'Compartiendo'
                        : _hasActiveDelivery
                        ? 'Reintentar ubicación'
                        : 'Compartir',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(pedidosAsignadosProvider);
                ref.invalidate(pedidoEntranteProvider);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  entrante.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (error, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('Pedido entrante: ${errorMessage(error)}'),
                    ),
                    data: (pedido) => pedido == null
                        ? const SizedBox.shrink()
                        : PedidoCard(
                            pedido: pedido,
                            mostrarCliente: true,
                            actions: [
                              FilledButton.icon(
                                icon:
                                    _processingIncomingOrderId == pedido.id &&
                                        !_rejectingIncomingOrder
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.check),
                                label: Text(
                                  _processingIncomingOrderId == pedido.id &&
                                          !_rejectingIncomingOrder
                                      ? 'Aceptando...'
                                      : 'Aceptar',
                                ),
                                onPressed: _processingIncomingOrderId == null
                                    ? () => _accept(pedido.id)
                                    : null,
                              ),
                              OutlinedButton.icon(
                                icon:
                                    _processingIncomingOrderId == pedido.id &&
                                        _rejectingIncomingOrder
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.close),
                                label: Text(
                                  _processingIncomingOrderId == pedido.id &&
                                          _rejectingIncomingOrder
                                      ? 'Rechazando...'
                                      : 'Rechazar',
                                ),
                                onPressed: _processingIncomingOrderId == null
                                    ? () => _reject(pedido.id)
                                    : null,
                              ),
                            ],
                          ),
                  ),
                  if (_hasActiveDelivery) _deliveryRouteSection(),
                  pedidos.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(errorMessage(error)),
                    ),
                    data: (list) => list.isEmpty && entrante.value == null
                        ? const Padding(
                            padding: EdgeInsets.only(top: 120),
                            child: Center(
                              child: Text('No tienes entregas pendientes'),
                            ),
                          )
                        : Column(
                            children: [
                              for (final pedido in list)
                                PedidoCard(
                                  pedido: pedido,
                                  mostrarCliente: true,
                                  actions: [
                                    if (pedido.estado == 'preparado')
                                      FilledButton.icon(
                                        icon:
                                            _processingOrderIds.contains(
                                              pedido.id,
                                            )
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Icon(Icons.delivery_dining),
                                        label: Text(
                                          _processingOrderIds.contains(
                                                pedido.id,
                                              )
                                              ? 'Actualizando...'
                                              : 'Iniciar entrega',
                                        ),
                                        onPressed:
                                            _processingOrderIds.contains(
                                              pedido.id,
                                            )
                                            ? null
                                            : () => _changeOrderState(
                                                pedido.id,
                                                'EN_RUTA',
                                              ),
                                      ),
                                    if (pedido.estado == 'en_ruta')
                                      FilledButton.icon(
                                        icon:
                                            _processingOrderIds.contains(
                                              pedido.id,
                                            )
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.check_circle_outline,
                                              ),
                                        label: Text(
                                          _processingOrderIds.contains(
                                                pedido.id,
                                              )
                                              ? 'Actualizando...'
                                              : 'Completar entrega',
                                        ),
                                        onPressed:
                                            _processingOrderIds.contains(
                                              pedido.id,
                                            )
                                            ? null
                                            : () => _changeOrderState(
                                                pedido.id,
                                                'ENTREGADO',
                                              ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
