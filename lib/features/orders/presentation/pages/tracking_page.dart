import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/helpers.dart';
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
  Timer? _refreshTimer;
  Object? _loadError;
  bool _loading = true;
  bool _requestInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTracking();
    _startPeriodicRefresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadTracking(showLoading: false);
      _startPeriodicRefresh();
    } else {
      _refreshTimer?.cancel();
      _refreshTimer = null;
    }
  }

  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadTracking(showLoading: false),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
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
        setState(() {
          _tracking = tracking;
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
                      Icons.update,
                      size: 12,
                      color: _loadError == null ? Colors.green : Colors.orange,
                    ),
                    title: const Text('Actualización automática cada 5 s'),
                    subtitle: tracking?['estado'] == null
                        ? null
                        : Text(
                            'Estado: ${estadoLabel(tracking!['estado'].toString().toLowerCase())}',
                          ),
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
