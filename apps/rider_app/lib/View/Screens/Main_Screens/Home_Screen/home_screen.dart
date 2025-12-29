/// BVI Park & Ride - Rider Home Screen
///
/// Full-screen Google Map showing real-time shuttle positions.
/// Features:
/// - Live shuttle tracking with vehicle markers
/// - Stop markers with Park & Ride green styling
/// - Bottom sheet with nearest stop + ETA
/// - Connection status indicator
/// - My location button

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'home_logics.dart';
import 'home_providers.dart';
import 'home_components.dart' show NearestStopSheet;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  Set<Marker> _stopMarkers = {};
  Set<Marker> _vehicleMarkers = {};

  // Road Town, Tortola, BVI - default center
  static const LatLng _defaultCenter = LatLng(18.4286, -64.6185);

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
    final isLoading = ref.watch(isLoadingProvider);
    final error = ref.watch(errorMessageProvider);
    final isConnected = ref.watch(connectionStatusProvider);

    // Watch for data changes and update markers
    final stops = ref.watch(stopsProvider);
    final vehicles = ref.watch(vehiclePositionsProvider);

    // Update markers when data changes
    _updateStopMarkers(stops);
    _updateVehicleMarkers(vehicles);

    return Scaffold(
      body: Stack(
        children: [
          // Full-screen Google Map
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

          // My location button - positioned above bottom sheet
          Positioned(
            right: 16,
            bottom: 195,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                shape: BoxShape.circle,
              ),
              child: FloatingActionButton(
                mini: true,
                backgroundColor: const Color(0xFF2A2A2A),
                elevation: 0,
                onPressed: () => _centerOnUser(),
                child: const Icon(Icons.my_location, color: Colors.white),
              ),
            ),
          ),

          // Connection status indicator - compact pill above bottom sheet
          Positioned(
            left: 16,
            bottom: 195,
            child: _buildConnectionStatus(isConnected),
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
    final userLocation = ref.watch(userLocationProvider);

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(mapCenter.lat, mapCenter.lng),
        zoom: 14.0,
      ),
      onMapCreated: (GoogleMapController controller) {
        _mapController.complete(controller);
        // Apply dark map style
        controller.setMapStyle(_darkMapStyle);
      },
      markers: {..._stopMarkers, ..._vehicleMarkers},
      myLocationEnabled: userLocation != null,
      myLocationButtonEnabled: false, // We have our own button
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
    );
  }

  void _updateStopMarkers(List<StopInfo> stops) {
    // Park & Ride official green color from flyer
    const stopColor = Color(0xFF0B9444);
    // Highlight color for start/end point
    const startEndColor = Color(0xFFFCD34D);

    final markers = <Marker>{};

    for (final stop in stops) {
      final isStartEnd = stop.isStartEnd;
      markers.add(
        Marker(
          markerId: MarkerId('stop_${stop.id}'),
          position: LatLng(stop.latitude, stop.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isStartEnd
                ? BitmapDescriptor.hueYellow
                : BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(
            title: stop.name,
            snippet: stop.type == 'parking' ? 'Parking Available' : 'Bus Stop',
          ),
          onTap: () {
            HomeScreenLogics().selectStop(ref, stop);
          },
        ),
      );
    }

    if (mounted) {
      setState(() {
        _stopMarkers = markers;
      });
    }
  }

  void _updateVehicleMarkers(Map<String, VehiclePosition> vehicles) {
    final markers = <Marker>{};

    for (final vehicle in vehicles.values) {
      markers.add(
        Marker(
          markerId: MarkerId('vehicle_${vehicle.vehicleId}'),
          position: LatLng(vehicle.latitude, vehicle.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          rotation: vehicle.heading ?? 0,
          anchor: const Offset(0.5, 0.5),
          infoWindow: InfoWindow(
            title: 'Shuttle ${vehicle.vehicleId}',
            snippet: 'Status: ${vehicle.status}',
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _vehicleMarkers = markers;
      });
    }
  }

  Widget _buildConnectionStatus(bool isConnected) {
    final statusColor = isConnected
        ? const Color(0xFF22C55E)
        : const Color(0xFFEAB308);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isConnected ? 'Live' : 'Connecting',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _centerOnUser() async {
    HomeScreenLogics().centerOnUser(ref);

    final userLoc = ref.read(userLocationProvider);
    if (userLoc != null) {
      final controller = await _mapController.future;
      controller.animateCamera(
        CameraUpdate.newLatLng(LatLng(userLoc.lat, userLoc.lng)),
      );
    }
  }

  // Dark map style JSON for Uber-like appearance
  static const String _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#242f3e"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#242f3e"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#746855"}]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#d59563"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#d59563"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [{"color": "#263c3f"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#6b9a76"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#38414e"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#212a37"}]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#9ca5b3"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#746855"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#1f2835"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#f3d19c"}]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [{"color": "#2f3948"}]
  },
  {
    "featureType": "transit.station",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#d59563"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#17263c"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#515c6d"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#17263c"}]
  }
]
''';
}
