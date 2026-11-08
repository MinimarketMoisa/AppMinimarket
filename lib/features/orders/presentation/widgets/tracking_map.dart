import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class TrackingMapPoint {
  const TrackingMapPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  static TrackingMapPoint? fromPlace(dynamic place) {
    if (place is! Map) return null;
    final latitude = double.tryParse('${place['latitud']}');
    final longitude = double.tryParse('${place['longitud']}');
    if (latitude == null ||
        longitude == null ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return null;
    }
    return TrackingMapPoint(latitude: latitude, longitude: longitude);
  }

  LatLng get latLng => LatLng(latitude, longitude);

  @override
  bool operator ==(Object other) =>
      other is TrackingMapPoint &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

class TrackingMap extends StatefulWidget {
  const TrackingMap({super.key, required this.tracking});

  final Map<String, dynamic>? tracking;

  @override
  State<TrackingMap> createState() => _TrackingMapState();
}

class _TrackingMapState extends State<TrackingMap> {
  static const _initialZoom = 15.0;
  final MapController _mapController = MapController();
  bool _mapReady = false;
  bool _followRider = true;
  double _zoom = _initialZoom;

  TrackingMapPoint? get _rider =>
      TrackingMapPoint.fromPlace(widget.tracking?['repartidor']);

  TrackingMapPoint? get _destination =>
      TrackingMapPoint.fromPlace(widget.tracking?['destino']);

  TrackingMapPoint? get _branch =>
      TrackingMapPoint.fromPlace(widget.tracking?['sucursal']);

  double? get _riderHeading {
    final heading = widget.tracking?['repartidor'] is Map
        ? (widget.tracking!['repartidor'] as Map)['rumbo']
        : null;
    return heading is num ? heading.toDouble() : null;
  }

  LatLng? get _initialCenter => (_rider ?? _destination ?? _branch)?.latLng;

  @override
  void didUpdateWidget(covariant TrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldRider = TrackingMapPoint.fromPlace(
      oldWidget.tracking?['repartidor'],
    );
    final newRider = _rider;
    if (_mapReady && _followRider && newRider != null && newRider != oldRider) {
      _mapController.move(newRider.latLng, _zoom);
    }
  }

  void _centerOnRider() {
    final rider = _rider;
    if (rider == null) return;
    setState(() => _followRider = true);
    _mapController.move(rider.latLng, _zoom);
  }

  @override
  Widget build(BuildContext context) {
    final rider = _rider;
    final destination = _destination;
    final branch = _branch;
    final center = _initialCenter;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ubicación del repartidor',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (rider == null)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('Aún no se recibe la ubicación del repartidor.'),
              ),
            if (center == null)
              const SizedBox(
                height: 220,
                child: Center(
                  child: Text('No hay coordenadas disponibles para mostrar.'),
                ),
              )
            else
              SizedBox(
                height: 280,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: _initialZoom,
                    onMapReady: () {
                      _mapReady = true;
                      if (_followRider && rider != null) {
                        _mapController.move(rider.latLng, _zoom);
                      }
                    },
                    onPositionChanged: (camera, hasGesture) {
                      _zoom = camera.zoom;
                      if (hasGesture && _followRider) {
                        setState(() => _followRider = false);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.minimarket',
                    ),
                    MarkerLayer(
                      markers: [
                        if (rider != null)
                          Marker(
                            point: rider.latLng,
                            width: 48,
                            height: 48,
                            child: Transform.rotate(
                              angle: (_riderHeading ?? 0) * math.pi / 180,
                              child: const Icon(
                                Icons.navigation,
                                color: Colors.deepPurple,
                                size: 38,
                              ),
                            ),
                          ),
                        if (destination != null)
                          Marker(
                            point: destination.latLng,
                            width: 44,
                            height: 44,
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        if (branch != null)
                          Marker(
                            point: branch.latLng,
                            width: 44,
                            height: 44,
                            child: const Icon(
                              Icons.store,
                              color: Colors.blueGrey,
                              size: 34,
                            ),
                          ),
                      ],
                    ),
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution('© OpenStreetMap contributors'),
                      ],
                    ),
                    if (rider != null)
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: IconButton.filledTonal(
                            tooltip: _followRider
                                ? 'Siguiendo al repartidor'
                                : 'Centrar en el repartidor',
                            onPressed: _centerOnRider,
                            icon: Icon(
                              _followRider
                                  ? Icons.my_location
                                  : Icons.location_searching,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                if (rider != null)
                  const _MapLegend(
                    icon: Icons.delivery_dining,
                    color: Colors.deepPurple,
                    label: 'Repartidor',
                  ),
                if (destination != null)
                  const _MapLegend(
                    icon: Icons.location_pin,
                    color: Colors.red,
                    label: 'Destino',
                  ),
                if (branch != null)
                  const _MapLegend(
                    icon: Icons.store,
                    color: Colors.blueGrey,
                    label: 'Sucursal',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 4),
      Text(label),
    ],
  );
}
