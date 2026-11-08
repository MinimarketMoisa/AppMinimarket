import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../providers/orders_provider.dart';
import '../widgets/tracking_map.dart';

class TrackingPage extends ConsumerStatefulWidget {
  const TrackingPage({super.key, required this.pedidoId});

  final int pedidoId;

  @override
  ConsumerState<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends ConsumerState<TrackingPage>
    with WidgetsBindingObserver {
  Map<String, dynamic>? _tracking;
  WebSocketChannel? _trackingChannel;
  StreamSubscription<dynamic>? _trackingSubscription;
  Timer? _reconnectTimer;
  Timer? _fallbackTimer;
  Map<String, dynamic> _latestSocketPosition = {};
  Object? _loadError;
  Object? _socketError;
  bool _loading = true;
  bool _requestInProgress = false;
  bool _socketActive = true;
  bool _socketConnecting = false;
  bool _socketConnected = false;
  int _reconnectAttempt = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTracking();
    _connectTrackingSocket();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadTracking(showLoading: false);
      _socketActive = true;
      _connectTrackingSocket();
    } else {
      _closeTrackingSocket();
    }
  }

  Future<void> _connectTrackingSocket() async {
    if (!mounted || !_socketActive || _socketConnecting || _socketConnected) {
      return;
    }
    _socketConnecting = true;
    _reconnectTimer?.cancel();
    WebSocketChannel? channel;
    try {
      final token = await ref.read(tokenStorageProvider).read();
      if (token == null || token.isEmpty) {
        throw StateError('No hay una sesión activa para el seguimiento.');
      }
      final baseUri = Uri.parse(AppConfig.baseUrl);
      final basePath = baseUri.path.endsWith('/')
          ? baseUri.path.substring(0, baseUri.path.length - 1)
          : baseUri.path;
      final uri = baseUri.replace(
        scheme: baseUri.scheme == 'http' || baseUri.scheme == 'ws'
            ? 'ws'
            : 'wss',
        path:
            '$basePath${ApiEndpoints.seguimientoWebSocketPedido(widget.pedidoId)}',
        queryParameters: {'token': token},
        fragment: '',
      );
      channel = WebSocketChannel.connect(uri);
      await channel.ready.timeout(const Duration(seconds: 15));
      if (!mounted || !_socketActive) {
        await channel.sink.close();
        return;
      }

      _trackingChannel = channel;
      _socketConnected = true;
      _socketError = null;
      _reconnectAttempt = 0;
      _fallbackTimer?.cancel();
      _fallbackTimer = null;
      setState(() {});
      _trackingSubscription = channel.stream.listen(
        _handleSocketMessage,
        onError: (Object error) => _handleSocketDisconnect(channel!, error),
        onDone: () => _handleSocketDisconnect(channel!),
      );
    } catch (error) {
      if (channel != null) {
        await channel.sink.close();
      }
      _scheduleReconnect(error);
    } finally {
      _socketConnecting = false;
    }
  }

  void _handleSocketMessage(dynamic rawMessage) {
    if (!mounted) return;
    try {
      final decoded = jsonDecode(rawMessage as String);
      if (decoded is! Map) {
        throw const FormatException('Evento de seguimiento inválido.');
      }
      final event = decoded['evento'];
      if (event == 'estado_inicial') {
        final data = decoded['datos'];
        if (data is! Map) {
          throw const FormatException(
            'El estado inicial del pedido es inválido.',
          );
        }
        final initialTracking = Map<String, dynamic>.from(data);
        final initialRider = initialTracking['repartidor'];
        initialTracking['repartidor'] = {
          if (initialRider is Map) ...initialRider,
          ..._latestSocketPosition,
        };
        setState(() {
          _tracking = initialTracking;
          _loadError = null;
          _socketError = null;
        });
        return;
      }

      final tracking = Map<String, dynamic>.from(_tracking ?? {});
      if (event == 'posicion_actualizada') {
        final latitude = decoded['latitud'];
        final longitude = decoded['longitud'];
        if (latitude is! num ||
            longitude is! num ||
            latitude < -90 ||
            latitude > 90 ||
            longitude < -180 ||
            longitude > 180) {
          throw const FormatException(
            'Las coordenadas recibidas no son válidas.',
          );
        }
        _latestSocketPosition = {
          'latitud': latitude,
          'longitud': longitude,
          if (decoded['rumbo'] is num) 'rumbo': decoded['rumbo'],
          if (decoded['velocidad'] is num)
            'velocidad': decoded['velocidad'],
          'ultima_actualizacion': decoded['ultima_actualizacion'],
        };
        final existingRider = tracking['repartidor'];
        tracking['repartidor'] = {
          if (existingRider is Map) ...existingRider,
          ..._latestSocketPosition,
        };
        tracking['ultima_actualizacion'] = decoded['ultima_actualizacion'];
      } else if (event == 'estado_pedido_actualizado') {
        if (decoded['estado'] is String) {
          tracking['estado'] = decoded['estado'];
        }
      } else if (event == 'pago_confirmado') {
        tracking['estado_pago'] = decoded['estado_pago'] ?? 'PAGADO';
        tracking['metodo_pago'] = decoded['metodo_pago'] ?? 'TARJETA';
        tracking['id_transaccion'] = decoded['id_transaccion'];
        tracking['monto'] = decoded['monto'];
      } else {
        return;
      }
      setState(() {
        _tracking = tracking;
        _loadError = null;
        _socketError = null;
      });
    } catch (error) {
      setState(() => _socketError = error);
    }
  }

  void _handleSocketDisconnect(WebSocketChannel channel, [Object? error]) {
    if (!identical(_trackingChannel, channel)) return;
    _trackingChannel = null;
    _trackingSubscription = null;
    _socketConnected = false;
    _scheduleReconnect(error);
  }

  void _scheduleReconnect([Object? error]) {
    if (!mounted) return;
    setState(() {
      _socketConnected = false;
      if (error != null) _socketError = error;
    });
    if (!_socketActive) return;
    _startFallbackPolling();
    _loadTracking(showLoading: false);
    _reconnectTimer?.cancel();
    final seconds = _reconnectAttempt < 4 ? 2 << _reconnectAttempt : 30;
    _reconnectAttempt++;
    _reconnectTimer = Timer(Duration(seconds: seconds), _connectTrackingSocket);
  }

  void _startFallbackPolling() {
    if (_fallbackTimer != null || !_socketActive) return;
    _fallbackTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_socketConnected) _loadTracking(showLoading: false);
    });
  }

  void _closeTrackingSocket() {
    _socketActive = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
    final subscription = _trackingSubscription;
    _trackingSubscription = null;
    if (subscription != null) unawaited(subscription.cancel());
    final channel = _trackingChannel;
    _trackingChannel = null;
    if (channel != null) unawaited(channel.sink.close());
    if (_socketConnected && mounted) {
      setState(() => _socketConnected = false);
    } else {
      _socketConnected = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _socketConnected = false;
    _closeTrackingSocket();
    super.dispose();
  }

  Future<void> _loadTracking({bool showLoading = true}) async {
    if (_requestInProgress) return;
    _requestInProgress = true;
    if (showLoading && mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    try {
      final tracking = await ref
          .read(ordersRepositoryProvider)
          .seguimiento(widget.pedidoId);
      if (mounted) {
        final refreshedTracking = Map<String, dynamic>.from(tracking);
        final refreshedRider = refreshedTracking['repartidor'];
        if (_latestSocketPosition.isNotEmpty) {
          refreshedTracking['repartidor'] = {
            if (refreshedRider is Map) ...refreshedRider,
            ..._latestSocketPosition,
          };
        }
        setState(() {
          _tracking = refreshedTracking;
          _loadError = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _loadError = error);
    } finally {
      _requestInProgress = false;
      if (mounted && showLoading) setState(() => _loading = false);
    }
  }

  String _label(String key) => key
      .split('_')
      .map(
        (part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');

  Widget _section(String title, dynamic value) {
    if (value is! Map || value.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            for (final entry in value.entries)
              if (entry.value != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 135,
                        child: Text(
                          _label(entry.key.toString()),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Expanded(child: Text(entry.value.toString())),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tracking = _tracking;
    final connectionDetails = <String>[
      if (tracking?['estado'] != null)
        'Estado: ${estadoLabel(tracking!['estado'].toString().toLowerCase())}',
      if (_socketError != null)
        'Error de conexión: ${errorMessage(_socketError!)}',
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Seguimiento ${tracking?['codigo_pedido'] ?? '#${widget.pedidoId}'}',
        ),
      ),
      body: _loading && tracking == null
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null && tracking == null
          ? AppErrorView(
              error: _loadError,
              title: 'No pudimos cargar el seguimiento',
              onRetry: _loadTracking,
            )
          : RefreshIndicator(
              onRefresh: _loadTracking,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                children: [
                  ListTile(
                    leading: Icon(
                      _socketConnected ? Icons.wifi : Icons.wifi_off,
                      color: _socketConnected ? Colors.green : Colors.orange,
                    ),
                    title: Text(
                      _socketConnected
                          ? 'Seguimiento en vivo'
                          : 'Reconectando al seguimiento...',
                    ),
                    subtitle: connectionDetails.isEmpty
                        ? null
                        : Text(connectionDetails.join('\n')),
                    trailing: IconButton(
                      tooltip: 'Actualizar ahora',
                      onPressed: _requestInProgress
                          ? null
                          : () => _loadTracking(showLoading: false),
                      icon: const Icon(Icons.refresh),
                    ),
                  ),
                  TrackingMap(tracking: tracking),
                  _section('Sucursal de origen', tracking?['sucursal']),
                  _section('Destino', tracking?['destino']),
                  _section('Repartidor', tracking?['repartidor']),
                  if (tracking?['estado_pago'] != null)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.credit_card),
                        title: Text(
                          'Pago: ${tracking!['estado_pago']}'
                          '${tracking['metodo_pago'] == null ? '' : ' · ${tracking['metodo_pago']}'}',
                        ),
                        subtitle: tracking['id_transaccion'] == null
                            ? null
                            : Text(
                                'Transacción: ${tracking['id_transaccion']}',
                              ),
                      ),
                    ),
                  if (tracking?['mensaje'] != null)
                    Card(
                      child: ListTile(
                        title: Text(tracking!['mensaje'].toString()),
                      ),
                    ),
                  if (_loadError != null)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'No se pudo actualizar el seguimiento: ${errorMessage(_loadError!)}',
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
