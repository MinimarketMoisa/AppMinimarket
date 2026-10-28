import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/utils/helpers.dart';
import '../providers/orders_provider.dart';

class TrackingPage extends ConsumerStatefulWidget {
  const TrackingPage({super.key, required this.pedidoId});

  final int pedidoId;

  @override
  ConsumerState<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends ConsumerState<TrackingPage> {
  Map<String, dynamic>? _tracking;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  String _connectionStatus = 'Conectando al seguimiento en vivo...';
  Object? _loadError;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTracking();
    _connectToLiveTracking();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  Future<void> _loadTracking() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final tracking = await ref
          .read(ordersRepositoryProvider)
          .seguimiento(widget.pedidoId);
      if (mounted) setState(() => _tracking = tracking);
    } catch (error) {
      if (mounted) setState(() => _loadError = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _connectToLiveTracking() async {
    try {
      if (AppConfig.useMock) {
        setState(
          () => _connectionStatus =
              'El seguimiento en vivo no está disponible en modo simulado',
        );
        return;
      }
      await _subscription?.cancel();
      await _channel?.sink.close();
      final token = await ref.read(tokenStorageProvider).read();
      if (token == null) {
        throw StateError('No se encontró una sesión activa');
      }
      final baseUri = Uri.parse(AppConfig.baseUrl);
      final socketUri = baseUri.replace(
        scheme: baseUri.scheme == 'https' ? 'wss' : 'ws',
        path: ApiEndpoints.seguimientoEnVivo(widget.pedidoId),
        queryParameters: {'token': token},
      );
      final channel = WebSocketChannel.connect(socketUri);
      _channel = channel;
      await channel.ready;
      if (!mounted) {
        await channel.sink.close();
        return;
      }
      setState(() => _connectionStatus = 'Seguimiento en vivo conectado');
      _subscription = channel.stream.listen(
        _onLiveUpdate,
        onError: (Object error, StackTrace stackTrace) {
          if (mounted) {
            setState(
              () => _connectionStatus =
                  'Seguimiento en vivo desconectado: ${errorMessage(error)}',
            );
          }
        },
        onDone: () {
          if (mounted) {
            setState(
              () => _connectionStatus = 'Seguimiento en vivo desconectado',
            );
          }
        },
      );
    } catch (error) {
      if (mounted) {
        setState(
          () => _connectionStatus =
              'No se pudo conectar al seguimiento en vivo: ${errorMessage(error)}',
        );
      }
    }
  }

  void _onLiveUpdate(dynamic message) {
    if (!mounted) return;
    Object? decoded;
    try {
      decoded = jsonDecode(message.toString());
    } on FormatException {
      decoded = {'mensaje': message.toString()};
    }
    final current = _tracking ?? <String, dynamic>{};
    if (decoded is Map<String, dynamic>) {
      final update = decoded;
      setState(() {
        _tracking = {...current, ...update};
      });
    } else {
      setState(() {
        _tracking = {...current, 'mensaje': decoded};
      });
    }
  }

  String _label(String key) => key
      .split('_')
      .map(
        (part) =>
            part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}',
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
    return Scaffold(
      appBar: AppBar(title: Text('Seguimiento #${widget.pedidoId}')),
      body: _loading && tracking == null
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null && tracking == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(errorMessage(_loadError!)),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _loadTracking,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadTracking,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.circle,
                      size: 12,
                      color: _connectionStatus.startsWith(
                        'Seguimiento en vivo conectado',
                      )
                          ? Colors.green
                          : Colors.orange,
                    ),
                    title: Text(_connectionStatus),
                    trailing: _connectionStatus.startsWith(
                      'Seguimiento en vivo conectado',
                    )
                        ? null
                        : IconButton(
                            tooltip: 'Reconectar',
                            onPressed: _connectToLiveTracking,
                            icon: const Icon(Icons.refresh),
                          ),
                    subtitle: tracking?['estado'] == null
                        ? null
                        : Text(
                            'Estado: ${estadoLabel(tracking!['estado'].toString().toLowerCase())}',
                          ),
                  ),
                  _section('Sucursal de origen', tracking?['sucursal']),
                  _section('Destino', tracking?['destino']),
                  _section('Repartidor', tracking?['repartidor']),
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
