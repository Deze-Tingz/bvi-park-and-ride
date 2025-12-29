/// BVI Park & Ride - Driver Home Screen
///
/// Simplified single-screen interface matching rider app design.
/// Features:
/// - Start/End Shift with route/vehicle selection
/// - Map view showing other shuttles (up to 3)
/// - Quick driver-to-driver communication
/// - Stop checklist with Arrived/Departed buttons

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'home_logics.dart';
import 'home_providers.dart';
import '../../../../Container/services/socket_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  static const LatLng _defaultCenter = LatLng(18.4286, -64.6185);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HomeLogics().initialize(context, ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final shiftStatus = ref.watch(shiftStatusProvider);
    final isLoading = ref.watch(isLoadingProvider);
    final error = ref.watch(errorMessageProvider);
    final showMap = ref.watch(showMapViewProvider);
    final unreadCount = ref.watch(unreadMessageCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content based on shift status
            shiftStatus == ShiftStatus.active
                ? (showMap ? _buildMapView() : _buildActiveShiftView())
                : _buildOfflineView(),

            // View toggle and message button (only during active shift)
            if (shiftStatus == ShiftStatus.active)
              Positioned(
                top: 16,
                right: 16,
                child: Row(
                  children: [
                    // Message button with badge
                    Stack(
                      children: [
                        FloatingActionButton(
                          mini: true,
                          heroTag: 'messages',
                          backgroundColor: const Color(0xFF2A2A2A),
                          onPressed: () => _showMessagesSheet(),
                          child: const Icon(Icons.message, color: Colors.white, size: 20),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                unreadCount > 9 ? '9+' : '$unreadCount',
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    // Map/List toggle
                    FloatingActionButton(
                      mini: true,
                      heroTag: 'toggle',
                      backgroundColor: const Color(0xFF2A2A2A),
                      onPressed: () => HomeLogics().toggleMapView(ref),
                      child: Icon(
                        showMap ? Icons.list : Icons.map,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

            // Loading overlay
            if (isLoading || shiftStatus == ShiftStatus.starting || shiftStatus == ShiftStatus.ending)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 16),
                      Text(
                        shiftStatus == ShiftStatus.starting
                            ? 'Starting shift...'
                            : shiftStatus == ShiftStatus.ending
                                ? 'Ending shift...'
                                : 'Loading...',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

            // Error snackbar
            if (error != null)
              Positioned(
                bottom: 100,
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
                        child: Text(error, style: const TextStyle(color: Colors.white)),
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
          ],
        ),
      ),
    );
  }

  /// Build the offline/shift setup view
  Widget _buildOfflineView() {
    final routes = ref.watch(availableRoutesProvider);
    final vehicles = ref.watch(availableVehiclesProvider);
    final selectedRoute = ref.watch(selectedRouteProvider);
    final selectedVehicle = ref.watch(selectedVehicleProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'BVI Park & Ride',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Driver App',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 40),

          // Offline status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red.withOpacity(0.5)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: Colors.red, size: 12),
                SizedBox(width: 8),
                Text(
                  'OFFLINE',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Route Selection
          const Text(
            'Select Route',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...routes.map((route) => _buildRouteCard(route, selectedRoute)),
          const SizedBox(height: 24),

          // Vehicle Selection
          const Text(
            'Select Vehicle',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...vehicles.map((vehicle) => _buildVehicleCard(vehicle, selectedVehicle)),
          const SizedBox(height: 40),

          // Start Shift Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: selectedRoute != null && selectedVehicle != null
                  ? () => HomeLogics().startShift(ref)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                disabledBackgroundColor: Colors.grey.shade800,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'START SHIFT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
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

  Widget _buildRouteCard(RouteInfo route, RouteInfo? selected) {
    final isSelected = selected?.id == route.id;
    final color = _parseColor(route.color);

    return GestureDetector(
      onTap: () => HomeLogics().selectRoute(ref, route),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.route,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${route.stops.length} stops',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(VehicleInfo vehicle, VehicleInfo? selected) {
    final isSelected = selected?.id == vehicle.id;

    return GestureDetector(
      onTap: () => HomeLogics().selectVehicle(ref, vehicle),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue.shade800,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.directions_bus,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.plateNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Capacity: ${vehicle.capacity} passengers',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.blue),
          ],
        ),
      ),
    );
  }

  /// Build the active shift view
  Widget _buildActiveShiftView() {
    final selectedRoute = ref.watch(selectedRouteProvider);
    final vehicleStatus = ref.watch(vehicleStatusProvider);
    final stops = ref.watch(routeStopsProvider);
    final currentStopIndex = ref.watch(currentStopIndexProvider);
    final stopVisits = ref.watch(stopVisitsProvider);
    final completedLoops = ref.watch(completedLoopsProvider);
    final isConnected = ref.watch(connectionStatusProvider);

    return Column(
      children: [
        // Top bar with shift info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Route badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _parseColor(selectedRoute?.color ?? '#007AFF'),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      selectedRoute?.name ?? 'Unknown Route',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Connection status
                  Container(
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
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isConnected ? 'LIVE' : 'OFFLINE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Loops', '$completedLoops'),
                  _buildStatItem('Stops', '${currentStopIndex + 1}/${stops.length}'),
                  _buildStatItem('Status', vehicleStatus.name.toUpperCase()),
                ],
              ),
            ],
          ),
        ),

        // Vehicle status buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildStatusButton(
                  'Available',
                  Icons.check_circle,
                  Colors.green,
                  vehicleStatus == VehicleStatus.available,
                  () => HomeLogics().updateVehicleStatus(ref, VehicleStatus.available),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatusButton(
                  'Full',
                  Icons.people,
                  Colors.orange,
                  vehicleStatus == VehicleStatus.full,
                  () => HomeLogics().updateVehicleStatus(ref, VehicleStatus.full),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatusButton(
                  'Out of Service',
                  Icons.block,
                  Colors.red,
                  vehicleStatus == VehicleStatus.outOfService,
                  () => HomeLogics().updateVehicleStatus(ref, VehicleStatus.outOfService),
                ),
              ),
            ],
          ),
        ),

        // Stop checklist
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: stops.length,
            itemBuilder: (context, index) {
              final stop = stops[index];
              final visit = stopVisits[stop.id];
              final isCurrent = index == currentStopIndex;

              return _buildStopCard(stop, visit, isCurrent, index);
            },
          ),
        ),

        // End shift button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => _showEndShiftDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stop, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'END SHIFT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusButton(
    String label,
    IconData icon,
    Color color,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.2) : Colors.grey.shade900,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isActive ? color : Colors.grey, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? color : Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStopCard(StopInfo stop, StopVisit? visit, bool isCurrent, int index) {
    final hasArrived = visit?.hasArrived ?? false;
    final hasDeparted = visit?.hasDeparted ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrent
            ? Colors.blue.withOpacity(0.2)
            : hasDeparted
                ? Colors.green.withOpacity(0.1)
                : Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? Colors.blue : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Stop number
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: hasDeparted
                  ? Colors.green
                  : isCurrent
                      ? Colors.blue
                      : Colors.grey.shade700,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: hasDeparted
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          // Stop name
          Expanded(
            child: Text(
              stop.name,
              style: TextStyle(
                color: isCurrent ? Colors.white : Colors.grey.shade300,
                fontSize: 16,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          // Action buttons
          if (isCurrent && !hasDeparted) ...[
            if (!hasArrived)
              ElevatedButton(
                onPressed: () => HomeLogics().markArrival(ref, stop),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('ARRIVED', style: TextStyle(color: Colors.white)),
              )
            else
              ElevatedButton(
                onPressed: () => HomeLogics().markDeparture(ref, stop),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('DEPART', style: TextStyle(color: Colors.white)),
              ),
          ],
        ],
      ),
    );
  }

  void _showEndShiftDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'End Shift?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to end your shift? You will stop broadcasting your location.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              HomeLogics().endShift(ref);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('END SHIFT', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceFirst('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  /// Build the map view showing other shuttles
  Widget _buildMapView() {
    final otherVehicles = ref.watch(otherVehiclesProvider);
    final selectedRoute = ref.watch(selectedRouteProvider);
    final isConnected = ref.watch(connectionStatusProvider);

    // Create markers for other vehicles
    final markers = <Marker>{};
    for (final vehicle in otherVehicles.values) {
      markers.add(
        Marker(
          markerId: MarkerId('vehicle_${vehicle.vehicleId}'),
          position: LatLng(vehicle.latitude, vehicle.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          rotation: vehicle.heading ?? 0,
          anchor: const Offset(0.5, 0.5),
          infoWindow: InfoWindow(
            title: 'Shuttle ${vehicle.vehicleId}',
            snippet: vehicle.status,
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Full screen map
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _defaultCenter,
            zoom: 14.0,
          ),
          onMapCreated: (GoogleMapController controller) {
            if (!_mapController.isCompleted) {
              _mapController.complete(controller);
            }
            controller.setMapStyle(_darkMapStyle);
          },
          markers: markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
        ),

        // Route badge and connection status
        Positioned(
          top: 60,
          left: 16,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _parseColor(selectedRoute?.color ?? '#007AFF'),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  selectedRoute?.name ?? 'Unknown',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isConnected ? Colors.green : Colors.orange,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isConnected ? Colors.green : Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isConnected ? 'Live' : 'Offline',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Other vehicles count
        Positioned(
          bottom: 100,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.directions_bus, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                Text(
                  '${otherVehicles.length} other shuttle${otherVehicles.length == 1 ? '' : 's'} active',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ),

        // Quick message buttons
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Quick Message',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildQuickMessageChip('On my way!', QuickMessage.onMyWay),
                    _buildQuickMessageChip('At stop', QuickMessage.atStop),
                    _buildQuickMessageChip('Bus full', QuickMessage.busIsFull),
                    _buildQuickMessageChip('All clear', QuickMessage.allClear),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickMessageChip(String label, QuickMessage type) {
    return GestureDetector(
      onTap: () => HomeLogics().sendQuickMessage(ref, type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }

  void _showMessagesSheet() {
    HomeLogics().clearUnreadCount(ref);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _MessagesSheet(
          scrollController: scrollController,
        ),
      ),
    );
  }

  // Dark map style JSON
  static const String _darkMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#242f3e"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#242f3e"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#746855"}]},
  {"featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [{"color": "#d59563"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#38414e"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#212a37"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#9ca5b3"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#746855"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#17263c"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#515c6d"}]}
]
''';
}

/// Messages bottom sheet widget
class _MessagesSheet extends ConsumerStatefulWidget {
  final ScrollController scrollController;

  const _MessagesSheet({required this.scrollController});

  @override
  ConsumerState<_MessagesSheet> createState() => _MessagesSheetState();
}

class _MessagesSheetState extends ConsumerState<_MessagesSheet> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(driverMessagesProvider);

    return Column(
      children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade600,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Header
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Driver Chat',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Messages list
        Expanded(
          child: messages.isEmpty
              ? const Center(
                  child: Text(
                    'No messages yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return _buildMessageBubble(msg);
                  },
                ),
        ),

        // Quick messages row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickBtn('On my way!', QuickMessage.onMyWay),
                _buildQuickBtn('Running late', QuickMessage.runningLate),
                _buildQuickBtn('Need help', QuickMessage.needAssistance),
                _buildQuickBtn('All clear', QuickMessage.allClear),
              ],
            ),
          ),
        ),

        // Message input
        Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    filled: true,
                    fillColor: Colors.grey.shade900,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                mini: true,
                backgroundColor: Colors.green,
                onPressed: _sendMessage,
                child: const Icon(Icons.send, color: Colors.white, size: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isMe = msg.isFromMe;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? Colors.green.shade700 : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                msg.fromDriverName,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            Text(
              msg.message,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 2),
            Text(
              _formatTime(msg.timestamp),
              style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickBtn(String label, QuickMessage type) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        backgroundColor: Colors.grey.shade800,
        labelStyle: const TextStyle(color: Colors.white),
        onPressed: () {
          HomeLogics().sendQuickMessage(ref, type);
        },
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      HomeLogics().sendMessage(ref, text);
      _messageController.clear();
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
