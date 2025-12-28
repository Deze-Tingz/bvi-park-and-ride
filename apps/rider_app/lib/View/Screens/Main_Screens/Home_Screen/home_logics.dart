/// Home Screen Business Logic
///
/// Handles data fetching, location tracking, and
/// WebSocket subscription for real-time shuttle updates.

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../Container/services/api_client.dart';
import '../../../../Container/services/socket_service.dart';
import 'home_providers.dart';

class HomeScreenLogics {
  static final HomeScreenLogics _instance = HomeScreenLogics._internal();
  factory HomeScreenLogics() => _instance;
  HomeScreenLogics._internal();

  StreamSubscription<VehicleUpdate>? _vehicleSubscription;
  StreamSubscription<Position>? _locationSubscription;

  /// Initialize the home screen
  Future<void> initialize(BuildContext context, WidgetRef ref) async {
    ref.read(isLoadingProvider.notifier).state = true;

    try {
      // Start location tracking
      await _startLocationTracking(ref);

      // Load routes and stops
      await _loadRoutesAndStops(ref);

      // Connect to WebSocket
      _connectWebSocket(ref);

      ref.read(isLoadingProvider.notifier).state = false;
    } catch (e) {
      ref.read(errorMessageProvider.notifier).state = e.toString();
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  /// Start tracking user's location
  Future<void> _startLocationTracking(WidgetRef ref) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied');
    }

    // Get initial position
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    ref.read(userLocationProvider.notifier).state = (
      lat: position.latitude,
      lng: position.longitude,
    );

    ref.read(mapCenterProvider.notifier).state = (
      lat: position.latitude,
      lng: position.longitude,
    );

    // Start continuous tracking
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20, // Update every 20 meters
      ),
    ).listen((Position position) {
      ref.read(userLocationProvider.notifier).state = (
        lat: position.latitude,
        lng: position.longitude,
      );
      _updateNearestStop(ref);
    });
  }

  /// Load routes and stops from API
  Future<void> _loadRoutesAndStops(WidgetRef ref) async {
    final apiClient = ref.read(apiClientProvider);

    try {
      // Load routes
      final routesData = await apiClient.getRoutes();
      final routes = routesData
          .map((r) => RouteInfo.fromJson(r as Map<String, dynamic>))
          .toList();
      ref.read(routesProvider.notifier).state = routes;

      // Load stops
      final stopsData = await apiClient.getStops();
      final stops = stopsData
          .map((s) => StopInfo.fromJson(s as Map<String, dynamic>))
          .toList();
      ref.read(stopsProvider.notifier).state = stops;

      // Calculate nearest stop
      _updateNearestStop(ref);
    } catch (e) {
      print('Error loading routes/stops: $e');
      // Use hardcoded BVI stops as fallback
      _loadFallbackData(ref);
    }
  }

  /// Load fallback data when API is unavailable
  void _loadFallbackData(WidgetRef ref) {
    final fallbackStops = [
      StopInfo(id: 'stop-001', name: 'Festival Grounds Parking Lot', latitude: 18.4285, longitude: -64.6189),
      StopInfo(id: 'stop-002', name: 'CCT / Eureka Parking', latitude: 18.4278, longitude: -64.6201),
      StopInfo(id: 'stop-003', name: "Bobby's Supermarket", latitude: 18.4290, longitude: -64.6175),
      StopInfo(id: 'stop-004', name: 'Mill Mall', latitude: 18.4275, longitude: -64.6165),
      StopInfo(id: 'stop-005', name: 'Banco Popular', latitude: 18.4268, longitude: -64.6155),
      StopInfo(id: 'stop-006', name: 'Tortola Pier Park', latitude: 18.4255, longitude: -64.6145),
      StopInfo(id: 'stop-007', name: 'Ferry Terminal', latitude: 18.4248, longitude: -64.6135),
      StopInfo(id: 'stop-008', name: 'RiteWay Road Reef', latitude: 18.4295, longitude: -64.6220),
      StopInfo(id: 'stop-009', name: 'Slaney Hill Roundabout', latitude: 18.4310, longitude: -64.6245),
      StopInfo(id: 'stop-010', name: 'Dr. D. Orlando Smith Hospital', latitude: 18.4325, longitude: -64.6260),
      StopInfo(id: 'stop-011', name: "Pusser's Parking", latitude: 18.4240, longitude: -64.6150),
      StopInfo(id: 'stop-012', name: 'Elmore Stoutt High School', latitude: 18.4335, longitude: -64.6280),
      StopInfo(id: 'stop-013', name: 'Road Town Police Station', latitude: 18.4265, longitude: -64.6170),
      StopInfo(id: 'stop-014', name: 'Althea Scatliffe Primary', latitude: 18.4300, longitude: -64.6195),
      StopInfo(id: 'stop-015', name: 'OneMart Parking Lot', latitude: 18.4320, longitude: -64.6235),
      StopInfo(id: 'stop-016', name: 'Delta / Golden Hind', latitude: 18.4305, longitude: -64.6210),
      StopInfo(id: 'stop-017', name: 'Moorings', latitude: 18.4350, longitude: -64.6300),
    ];

    final fallbackRoutes = [
      RouteInfo(id: 'green', name: 'Green Line', color: '#22C55E', stops: fallbackStops.sublist(0, 10)),
      RouteInfo(id: 'yellow', name: 'Yellow Line', color: '#EAB308', stops: fallbackStops.sublist(5, 17)),
    ];

    ref.read(stopsProvider.notifier).state = fallbackStops;
    ref.read(routesProvider.notifier).state = fallbackRoutes;
    _updateNearestStop(ref);
  }

  /// Connect to WebSocket for live updates
  void _connectWebSocket(WidgetRef ref) {
    final socketService = ref.read(socketServiceProvider);

    // Connect
    socketService.connect();

    // Subscribe to all routes
    final routes = ref.read(routesProvider);
    for (final route in routes) {
      socketService.subscribeToRoute(route.id);
    }

    // Listen for vehicle updates
    _vehicleSubscription = socketService.vehicleUpdates.listen((update) {
      final vehicles = Map<String, VehiclePosition>.from(
        ref.read(vehiclePositionsProvider),
      );
      vehicles[update.vehicleId] = VehiclePosition.fromVehicleUpdate(update);
      ref.read(vehiclePositionsProvider.notifier).state = vehicles;

      // Update nearest stop ETA
      _updateNearestStopEta(ref);
    });
  }

  /// Calculate and update nearest stop
  void _updateNearestStop(WidgetRef ref) {
    final userLoc = ref.read(userLocationProvider);
    final stops = ref.read(stopsProvider);

    if (userLoc == null || stops.isEmpty) return;

    StopInfo? nearest;
    double minDistance = double.infinity;

    for (final stop in stops) {
      final distance = _calculateDistance(
        userLoc.lat,
        userLoc.lng,
        stop.latitude,
        stop.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
        nearest = stop;
      }
    }

    ref.read(nearestStopProvider.notifier).state = nearest;
  }

  /// Update ETA to nearest stop based on vehicle positions
  void _updateNearestStopEta(WidgetRef ref) {
    final nearestStop = ref.read(nearestStopProvider);
    final vehicles = ref.read(vehiclePositionsProvider);

    if (nearestStop == null || vehicles.isEmpty) return;

    // Find closest vehicle heading to this stop
    int? minEta;
    for (final vehicle in vehicles.values) {
      if (vehicle.status != 'active') continue;

      final distanceToStop = _calculateDistance(
        vehicle.latitude,
        vehicle.longitude,
        nearestStop.latitude,
        nearestStop.longitude,
      );

      // Estimate ETA: assume average speed of 25 km/h in town
      final etaMinutes = (distanceToStop / 25 * 60).round();
      if (minEta == null || etaMinutes < minEta) {
        minEta = etaMinutes;
      }
    }

    ref.read(nearestStopEtaProvider.notifier).state = minEta;
  }

  /// Calculate distance between two points in km (Haversine formula)
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0; // Earth's radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180;

  /// Select a route to filter
  void selectRoute(WidgetRef ref, String? routeId) {
    ref.read(selectedRouteProvider.notifier).state = routeId;

    // Subscribe/unsubscribe from routes
    final socketService = ref.read(socketServiceProvider);
    if (routeId != null) {
      socketService.subscribeToRoute(routeId);
    }
  }

  /// Select a stop for details
  void selectStop(WidgetRef ref, StopInfo stop) {
    ref.read(selectedStopProvider.notifier).state = stop;
    ref.read(bottomSheetExpandedProvider.notifier).state = true;
  }

  /// Center map on user location
  void centerOnUser(WidgetRef ref) {
    final userLoc = ref.read(userLocationProvider);
    if (userLoc != null) {
      ref.read(mapCenterProvider.notifier).state = userLoc;
    }
  }

  /// Clean up subscriptions
  void dispose() {
    _vehicleSubscription?.cancel();
    _locationSubscription?.cancel();
  }
}
