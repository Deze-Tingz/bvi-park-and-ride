/// Driver Home Screen Business Logic
///
/// Handles shift management, GPS tracking, and
/// WebSocket communication for broadcasting location.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../Container/services/api_client.dart';
import '../../../../Container/services/socket_service.dart';
import '../../../../Container/services/location_service.dart';
import 'home_providers.dart';

class HomeLogics {
  static final HomeLogics _instance = HomeLogics._internal();
  factory HomeLogics() => _instance;
  HomeLogics._internal();

  /// Initialize the driver home screen
  Future<void> initialize(BuildContext context, WidgetRef ref) async {
    ref.read(isLoadingProvider.notifier).state = true;

    try {
      // Load available routes and vehicles
      await _loadRoutesAndVehicles(ref);

      ref.read(isLoadingProvider.notifier).state = false;
    } catch (e) {
      ref.read(errorMessageProvider.notifier).state = e.toString();
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  /// Load available routes and vehicles from API
  Future<void> _loadRoutesAndVehicles(WidgetRef ref) async {
    final apiClient = ref.read(apiClientProvider);

    try {
      // Load routes
      final routesData = await apiClient.getRoutes();
      final routes = routesData
          .map((r) => RouteInfo.fromJson(r as Map<String, dynamic>))
          .toList();
      ref.read(availableRoutesProvider.notifier).state = routes;

      // Load available vehicles
      final vehiclesData = await apiClient.getAvailableVehicles();
      final vehicles = vehiclesData
          .map((v) => VehicleInfo.fromJson(v as Map<String, dynamic>))
          .toList();
      ref.read(availableVehiclesProvider.notifier).state = vehicles;
    } catch (e) {
      print('Error loading data: $e');
      // Use fallback data
      _loadFallbackData(ref);
    }
  }

  /// Load fallback data when API is unavailable
  void _loadFallbackData(WidgetRef ref) {
    final greenStops = [
      StopInfo(id: 'stop-001', name: 'Festival Grounds Parking Lot', latitude: 18.4285, longitude: -64.6189, order: 1),
      StopInfo(id: 'stop-002', name: 'CCT / Eureka Parking', latitude: 18.4278, longitude: -64.6201, order: 2),
      StopInfo(id: 'stop-003', name: "Bobby's Supermarket", latitude: 18.4290, longitude: -64.6175, order: 3),
      StopInfo(id: 'stop-004', name: 'Mill Mall', latitude: 18.4275, longitude: -64.6165, order: 4),
      StopInfo(id: 'stop-005', name: 'Banco Popular', latitude: 18.4268, longitude: -64.6155, order: 5),
      StopInfo(id: 'stop-006', name: 'Tortola Pier Park', latitude: 18.4255, longitude: -64.6145, order: 6),
      StopInfo(id: 'stop-007', name: 'Ferry Terminal', latitude: 18.4248, longitude: -64.6135, order: 7),
    ];

    final yellowStops = [
      StopInfo(id: 'stop-008', name: 'RiteWay Road Reef', latitude: 18.4295, longitude: -64.6220, order: 1),
      StopInfo(id: 'stop-009', name: 'Slaney Hill Roundabout', latitude: 18.4310, longitude: -64.6245, order: 2),
      StopInfo(id: 'stop-010', name: 'Dr. D. Orlando Smith Hospital', latitude: 18.4325, longitude: -64.6260, order: 3),
      StopInfo(id: 'stop-012', name: 'Elmore Stoutt High School', latitude: 18.4335, longitude: -64.6280, order: 4),
      StopInfo(id: 'stop-017', name: 'Moorings', latitude: 18.4350, longitude: -64.6300, order: 5),
    ];

    final fallbackRoutes = [
      RouteInfo(id: 'green', name: 'Green Line', color: '#22C55E', stops: greenStops),
      RouteInfo(id: 'yellow', name: 'Yellow Line', color: '#EAB308', stops: yellowStops),
    ];

    final fallbackVehicles = [
      VehicleInfo(id: 'v001', plateNumber: 'BVI-001', type: 'shuttle', capacity: 14),
      VehicleInfo(id: 'v002', plateNumber: 'BVI-002', type: 'shuttle', capacity: 14),
      VehicleInfo(id: 'v003', plateNumber: 'BVI-003', type: 'shuttle', capacity: 20),
    ];

    ref.read(availableRoutesProvider.notifier).state = fallbackRoutes;
    ref.read(availableVehiclesProvider.notifier).state = fallbackVehicles;
  }

  /// Start a new shift
  Future<void> startShift(WidgetRef ref) async {
    final selectedRoute = ref.read(selectedRouteProvider);
    final selectedVehicle = ref.read(selectedVehicleProvider);

    if (selectedRoute == null || selectedVehicle == null) {
      ref.read(errorMessageProvider.notifier).state =
          'Please select a route and vehicle';
      return;
    }

    ref.read(shiftStatusProvider.notifier).state = ShiftStatus.starting;

    try {
      final apiClient = ref.read(apiClientProvider);
      final socketService = ref.read(socketServiceProvider);
      final locationService = ref.read(locationServiceProvider);

      // Start shift via API
      await apiClient.startShift(
        vehicleId: selectedVehicle.id,
        routeId: selectedRoute.id,
      );

      // Connect WebSocket and register
      final token = await apiClient.getToken();
      socketService.connect(authToken: token);
      socketService.registerDriver(selectedVehicle.id, selectedRoute.id);

      // Start GPS tracking
      await locationService.startTracking(selectedVehicle.id);

      // Set up route stops
      ref.read(routeStopsProvider.notifier).state = selectedRoute.stops;
      ref.read(currentStopIndexProvider.notifier).state = 0;

      // Initialize stop visits
      final visits = <String, StopVisit>{};
      for (final stop in selectedRoute.stops) {
        visits[stop.id] = StopVisit(stopId: stop.id, stopName: stop.name);
      }
      ref.read(stopVisitsProvider.notifier).state = visits;

      // Update state
      ref.read(shiftStatusProvider.notifier).state = ShiftStatus.active;
      ref.read(shiftStartTimeProvider.notifier).state = DateTime.now();

    } catch (e) {
      ref.read(shiftStatusProvider.notifier).state = ShiftStatus.offline;
      ref.read(errorMessageProvider.notifier).state = 'Failed to start shift: $e';
    }
  }

  /// End the current shift
  Future<void> endShift(WidgetRef ref) async {
    ref.read(shiftStatusProvider.notifier).state = ShiftStatus.ending;

    try {
      final apiClient = ref.read(apiClientProvider);
      final socketService = ref.read(socketServiceProvider);
      final locationService = ref.read(locationServiceProvider);

      // Stop GPS tracking
      locationService.stopTracking();

      // Disconnect WebSocket
      socketService.disconnect();

      // End shift via API
      await apiClient.endShift();

      // Reset state
      ref.read(shiftStatusProvider.notifier).state = ShiftStatus.offline;
      ref.read(selectedRouteProvider.notifier).state = null;
      ref.read(selectedVehicleProvider.notifier).state = null;
      ref.read(routeStopsProvider.notifier).state = [];
      ref.read(stopVisitsProvider.notifier).state = {};
      ref.read(currentStopIndexProvider.notifier).state = 0;
      ref.read(shiftStartTimeProvider.notifier).state = null;
      ref.read(completedLoopsProvider.notifier).state = 0;

    } catch (e) {
      ref.read(shiftStatusProvider.notifier).state = ShiftStatus.active;
      ref.read(errorMessageProvider.notifier).state = 'Failed to end shift: $e';
    }
  }

  /// Mark arrival at a stop
  void markArrival(WidgetRef ref, StopInfo stop) {
    final socketService = ref.read(socketServiceProvider);
    final vehicle = ref.read(selectedVehicleProvider);

    if (vehicle == null) return;

    // Update local state
    final visits = Map<String, StopVisit>.from(ref.read(stopVisitsProvider));
    visits[stop.id] = StopVisit(
      stopId: stop.id,
      stopName: stop.name,
      arrivedAt: DateTime.now(),
    );
    ref.read(stopVisitsProvider.notifier).state = visits;

    // Notify server
    socketService.sendStopArrival(vehicle.id, stop.id);

    // Also notify via API for persistence
    ref.read(apiClientProvider).markArrivedAtStop(stop.id);
  }

  /// Mark departure from a stop
  void markDeparture(WidgetRef ref, StopInfo stop) {
    final socketService = ref.read(socketServiceProvider);
    final vehicle = ref.read(selectedVehicleProvider);
    final stops = ref.read(routeStopsProvider);
    final currentIndex = ref.read(currentStopIndexProvider);

    if (vehicle == null) return;

    // Update local state
    final visits = Map<String, StopVisit>.from(ref.read(stopVisitsProvider));
    final existingVisit = visits[stop.id];
    visits[stop.id] = StopVisit(
      stopId: stop.id,
      stopName: stop.name,
      arrivedAt: existingVisit?.arrivedAt,
      departedAt: DateTime.now(),
    );
    ref.read(stopVisitsProvider.notifier).state = visits;

    // Move to next stop
    final nextIndex = currentIndex + 1;
    if (nextIndex >= stops.length) {
      // Completed a loop
      ref.read(currentStopIndexProvider.notifier).state = 0;
      ref.read(completedLoopsProvider.notifier).state =
          ref.read(completedLoopsProvider) + 1;

      // Reset visits for next loop
      final newVisits = <String, StopVisit>{};
      for (final s in stops) {
        newVisits[s.id] = StopVisit(stopId: s.id, stopName: s.name);
      }
      ref.read(stopVisitsProvider.notifier).state = newVisits;
    } else {
      ref.read(currentStopIndexProvider.notifier).state = nextIndex;
    }

    // Notify server
    socketService.sendStopDeparture(vehicle.id, stop.id);

    // Also notify via API for persistence
    ref.read(apiClientProvider).markDepartedFromStop(stop.id);
  }

  /// Update vehicle status
  Future<void> updateVehicleStatus(WidgetRef ref, VehicleStatus status) async {
    final previousStatus = ref.read(vehicleStatusProvider);
    ref.read(vehicleStatusProvider.notifier).state = status;

    try {
      final apiClient = ref.read(apiClientProvider);
      final statusString = switch (status) {
        VehicleStatus.available => 'available',
        VehicleStatus.full => 'full',
        VehicleStatus.outOfService => 'out_of_service',
      };
      await apiClient.updateStatus(statusString);
    } catch (e) {
      // Revert on failure
      ref.read(vehicleStatusProvider.notifier).state = previousStatus;
      ref.read(errorMessageProvider.notifier).state =
          'Failed to update status: $e';
    }
  }

  /// Select a route
  void selectRoute(WidgetRef ref, RouteInfo route) {
    ref.read(selectedRouteProvider.notifier).state = route;
  }

  /// Select a vehicle
  void selectVehicle(WidgetRef ref, VehicleInfo vehicle) {
    ref.read(selectedVehicleProvider.notifier).state = vehicle;
  }

  /// Get shift duration as formatted string
  String getShiftDuration(WidgetRef ref) {
    final startTime = ref.read(shiftStartTimeProvider);
    if (startTime == null) return '0:00';

    final duration = DateTime.now().difference(startTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '$hours:${minutes.toString().padLeft(2, '0')}';
  }
}
