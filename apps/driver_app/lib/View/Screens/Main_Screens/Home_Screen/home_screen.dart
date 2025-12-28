/// BVI Park & Ride - Driver Home Screen
///
/// Shift management interface for shuttle drivers.
/// Features:
/// - Start/End Shift
/// - Route and vehicle selection
/// - Stop checklist with Arrived/Departed buttons
/// - Vehicle status toggle (Full/Out of Service)
/// - Real-time GPS broadcasting

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'home_logics.dart';
import 'home_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  MapboxMap? _mapController;

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

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content based on shift status
            shiftStatus == ShiftStatus.active
                ? _buildActiveShiftView()
                : _buildOfflineView(),

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
}
