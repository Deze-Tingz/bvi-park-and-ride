/// BVI Park & Ride - Rider Home Screen
///
/// Full-screen map showing real-time shuttle positions.
/// Features:
/// - Live shuttle tracking
/// - Route lines (Green/Yellow)
/// - Stop markers
/// - Bottom sheet with nearest stop + ETA

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'home_logics.dart';
import 'home_providers.dart';
import 'home_components.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  MapboxMap? _mapController;
  PointAnnotationManager? _stopAnnotationManager;
  PointAnnotationManager? _vehicleAnnotationManager;
  PolylineAnnotationManager? _routeAnnotationManager;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HomeScreenLogics().initialize(context, ref);
    });
  }

  @override
  void dispose() {
    HomeScreenLogics().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isLoading = ref.watch(isLoadingProvider);
    final error = ref.watch(errorMessageProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Full-screen Mapbox map
          _buildMap(),

          // Loading overlay
          if (isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Loading shuttles...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // Error banner
          if (error != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        ref.read(errorMessageProvider.notifier).state = null;
                      },
                    ),
                  ],
                ),
              ),
            ),

          // Route filter chips
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: const RouteFilterChips(),
          ),

          // My location button
          Positioned(
            right: 16,
            bottom: 200,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: () => _centerOnUser(),
              child: const Icon(Icons.my_location, color: Colors.black87),
            ),
          ),

          // Connection status indicator
          Positioned(
            left: 16,
            bottom: 200,
            child: Consumer(
              builder: (context, ref, child) {
                final isConnected = ref.watch(connectionStatusProvider);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isConnected ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isConnected ? Icons.wifi : Icons.wifi_off,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isConnected ? 'Live' : 'Connecting...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Bottom sheet with nearest stop and ETA
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: NearestStopSheet(),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    final mapCenter = ref.watch(mapCenterProvider);
    final mapZoom = ref.watch(mapZoomProvider);

    return MapWidget(
      key: const ValueKey('mapWidget'),
      cameraOptions: CameraOptions(
        center: Point(
          coordinates: Position(mapCenter.lng, mapCenter.lat),
        ),
        zoom: mapZoom,
      ),
      styleUri: MapboxStyles.DARK,
      onMapCreated: _onMapCreated,
    );
  }

  void _onMapCreated(MapboxMap mapController) async {
    _mapController = mapController;

    // Create annotation managers
    _stopAnnotationManager = await mapController.annotations
        .createPointAnnotationManager();
    _vehicleAnnotationManager = await mapController.annotations
        .createPointAnnotationManager();
    _routeAnnotationManager = await mapController.annotations
        .createPolylineAnnotationManager();

    // Listen for data changes
    ref.listen(stopsProvider, (_, stops) => _updateStopMarkers(stops));
    ref.listen(vehiclePositionsProvider, (_, vehicles) => _updateVehicleMarkers(vehicles));
    ref.listen(routesProvider, (_, routes) => _updateRouteLines(routes));
    ref.listen(mapCenterProvider, (_, center) => _animateToCenter(center));
  }

  void _updateStopMarkers(List<StopInfo> stops) async {
    if (_stopAnnotationManager == null) return;

    await _stopAnnotationManager!.deleteAll();

    for (final stop in stops) {
      final options = PointAnnotationOptions(
        geometry: Point(
          coordinates: Position(stop.longitude, stop.latitude),
        ),
        iconSize: 1.0,
        iconImage: 'marker-15', // Built-in Mapbox marker
        textField: stop.name,
        textSize: 10,
        textOffset: [0, 1.5],
        textColor: Colors.white.value,
      );
      await _stopAnnotationManager!.create(options);
    }
  }

  void _updateVehicleMarkers(Map<String, VehiclePosition> vehicles) async {
    if (_vehicleAnnotationManager == null) return;

    await _vehicleAnnotationManager!.deleteAll();

    for (final vehicle in vehicles.values) {
      final options = PointAnnotationOptions(
        geometry: Point(
          coordinates: Position(vehicle.longitude, vehicle.latitude),
        ),
        iconSize: 1.5,
        iconImage: 'bus-15', // Built-in Mapbox bus icon
        iconRotate: vehicle.heading ?? 0,
      );
      await _vehicleAnnotationManager!.create(options);
    }
  }

  void _updateRouteLines(List<RouteInfo> routes) async {
    if (_routeAnnotationManager == null) return;

    await _routeAnnotationManager!.deleteAll();

    for (final route in routes) {
      if (route.stops.isEmpty) continue;

      // Create polyline from stop coordinates
      final coordinates = route.stops
          .map((s) => Position(s.longitude, s.latitude))
          .toList();

      final color = _parseColor(route.color);

      final options = PolylineAnnotationOptions(
        geometry: LineString(coordinates: coordinates),
        lineWidth: 4.0,
        lineColor: color.value,
        lineOpacity: 0.8,
      );
      await _routeAnnotationManager!.create(options);
    }
  }

  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceFirst('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  void _animateToCenter(({double lat, double lng}) center) {
    _mapController?.flyTo(
      CameraOptions(
        center: Point(
          coordinates: Position(center.lng, center.lat),
        ),
        zoom: 15,
      ),
      MapAnimationOptions(duration: 1000),
    );
  }

  void _centerOnUser() {
    HomeScreenLogics().centerOnUser(ref);
  }
}
