/// Home Screen Providers
///
/// State management for the shuttle tracking home screen.
/// Uses Riverpod for reactive state updates.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../Container/services/socket_service.dart';
import '../../../../Container/services/api_client.dart';

/// Route model for display
class RouteInfo {
  final String id;
  final String name;
  final String color;
  final List<StopInfo> stops;

  RouteInfo({
    required this.id,
    required this.name,
    required this.color,
    required this.stops,
  });

  factory RouteInfo.fromJson(Map<String, dynamic> json) {
    return RouteInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      color: json['color'] ?? '#007AFF',
      stops: (json['stops'] as List<dynamic>?)
              ?.map((s) => StopInfo.fromJson(s))
              .toList() ??
          [],
    );
  }
}

/// Stop model for display
class StopInfo {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int? etaMinutes;

  StopInfo({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.etaMinutes,
  });

  factory StopInfo.fromJson(Map<String, dynamic> json) {
    return StopInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      etaMinutes: json['etaMinutes'],
    );
  }
}

/// Vehicle position for map display
class VehiclePosition {
  final String vehicleId;
  final String routeId;
  final double latitude;
  final double longitude;
  final double? heading;
  final double? speed;
  final String status;
  final DateTime lastUpdate;

  VehiclePosition({
    required this.vehicleId,
    required this.routeId,
    required this.latitude,
    required this.longitude,
    this.heading,
    this.speed,
    required this.status,
    required this.lastUpdate,
  });

  factory VehiclePosition.fromVehicleUpdate(VehicleUpdate update) {
    return VehiclePosition(
      vehicleId: update.vehicleId,
      routeId: update.routeId,
      latitude: update.latitude,
      longitude: update.longitude,
      heading: update.heading,
      speed: update.speed,
      status: update.status,
      lastUpdate: update.timestamp,
    );
  }
}

// ==================== PROVIDERS ====================

/// User's current location
final userLocationProvider = StateProvider<({double lat, double lng})?>((ref) {
  return null;
});

/// Selected route filter (null = show all)
final selectedRouteProvider = StateProvider<String?>((ref) {
  return null;
});

/// All available routes
final routesProvider = StateProvider<List<RouteInfo>>((ref) {
  return [];
});

/// All stops
final stopsProvider = StateProvider<List<StopInfo>>((ref) {
  return [];
});

/// Live vehicle positions (updated via WebSocket)
final vehiclePositionsProvider = StateProvider<Map<String, VehiclePosition>>((ref) {
  return {};
});

/// Nearest stop to user
final nearestStopProvider = StateProvider<StopInfo?>((ref) {
  return null;
});

/// ETA to nearest stop
final nearestStopEtaProvider = StateProvider<int?>((ref) {
  return null;
});

/// Map camera position
final mapCenterProvider = StateProvider<({double lat, double lng})>((ref) {
  // Default to Road Town, Tortola, BVI
  return (lat: 18.4286, lng: -64.6185);
});

/// Map zoom level
final mapZoomProvider = StateProvider<double>((ref) {
  return 14.0;
});

/// Bottom sheet expanded state
final bottomSheetExpandedProvider = StateProvider<bool>((ref) {
  return false;
});

/// Loading state
final isLoadingProvider = StateProvider<bool>((ref) {
  return true;
});

/// Error message
final errorMessageProvider = StateProvider<String?>((ref) {
  return null;
});

/// WebSocket connection status
final connectionStatusProvider = StateProvider<bool>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return socketService.isConnected;
});

/// Selected stop for details view
final selectedStopProvider = StateProvider<StopInfo?>((ref) {
  return null;
});

/// Vehicles on selected route
final filteredVehiclesProvider = Provider<List<VehiclePosition>>((ref) {
  final vehicles = ref.watch(vehiclePositionsProvider);
  final selectedRoute = ref.watch(selectedRouteProvider);

  if (selectedRoute == null) {
    return vehicles.values.toList();
  }

  return vehicles.values
      .where((v) => v.routeId == selectedRoute)
      .toList();
});
