/// Driver Home Screen Providers
///
/// State management for the driver shift and tracking interface.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../Container/services/socket_service.dart';
import '../../../../Container/services/location_service.dart';

/// Shift state enum
enum ShiftStatus {
  offline,
  starting,
  active,
  ending,
}

/// Vehicle status for passengers
enum VehicleStatus {
  available, // Normal operation
  full, // No more passengers
  outOfService, // Not accepting passengers
}

/// Route model
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

/// Stop model
class StopInfo {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int order;

  StopInfo({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.order,
  });

  factory StopInfo.fromJson(Map<String, dynamic> json) {
    return StopInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      order: json['order'] ?? 0,
    );
  }
}

/// Vehicle model
class VehicleInfo {
  final String id;
  final String plateNumber;
  final String type;
  final int capacity;

  VehicleInfo({
    required this.id,
    required this.plateNumber,
    required this.type,
    required this.capacity,
  });

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    return VehicleInfo(
      id: json['id'] ?? '',
      plateNumber: json['plateNumber'] ?? '',
      type: json['type'] ?? 'shuttle',
      capacity: json['capacity'] ?? 14,
    );
  }
}

/// Stop visit status
class StopVisit {
  final String stopId;
  final String stopName;
  final DateTime? arrivedAt;
  final DateTime? departedAt;

  StopVisit({
    required this.stopId,
    required this.stopName,
    this.arrivedAt,
    this.departedAt,
  });

  bool get hasArrived => arrivedAt != null;
  bool get hasDeparted => departedAt != null;
  bool get isComplete => hasArrived && hasDeparted;
}

// ==================== PROVIDERS ====================

/// Current shift status
final shiftStatusProvider = StateProvider<ShiftStatus>((ref) {
  return ShiftStatus.offline;
});

/// Vehicle status (available, full, out of service)
final vehicleStatusProvider = StateProvider<VehicleStatus>((ref) {
  return VehicleStatus.available;
});

/// Available routes
final availableRoutesProvider = StateProvider<List<RouteInfo>>((ref) {
  return [];
});

/// Selected route for shift
final selectedRouteProvider = StateProvider<RouteInfo?>((ref) {
  return null;
});

/// Available vehicles
final availableVehiclesProvider = StateProvider<List<VehicleInfo>>((ref) {
  return [];
});

/// Selected vehicle for shift
final selectedVehicleProvider = StateProvider<VehicleInfo?>((ref) {
  return null;
});

/// Current route stops
final routeStopsProvider = StateProvider<List<StopInfo>>((ref) {
  return [];
});

/// Stop visit tracking
final stopVisitsProvider = StateProvider<Map<String, StopVisit>>((ref) {
  return {};
});

/// Current stop index (which stop driver is at or heading to)
final currentStopIndexProvider = StateProvider<int>((ref) {
  return 0;
});

/// Driver's current location
final driverLocationProvider = StateProvider<LocationData?>((ref) {
  return null;
});

/// Map center position
final mapCenterProvider = StateProvider<({double lat, double lng})>((ref) {
  // Default to Road Town, Tortola, BVI
  return (lat: 18.4286, lng: -64.6185);
});

/// Map zoom level
final mapZoomProvider = StateProvider<double>((ref) {
  return 14.0;
});

/// Loading state
final isLoadingProvider = StateProvider<bool>((ref) {
  return false;
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

/// Shift start time
final shiftStartTimeProvider = StateProvider<DateTime?>((ref) {
  return null;
});

/// Number of completed route loops
final completedLoopsProvider = StateProvider<int>((ref) {
  return 0;
});

/// Other vehicles on the map (up to 3)
class OtherVehicle {
  final String vehicleId;
  final String routeId;
  final double latitude;
  final double longitude;
  final double? heading;
  final String status;
  final DateTime lastUpdate;

  OtherVehicle({
    required this.vehicleId,
    required this.routeId,
    required this.latitude,
    required this.longitude,
    this.heading,
    required this.status,
    required this.lastUpdate,
  });
}

final otherVehiclesProvider = StateProvider<Map<String, OtherVehicle>>((ref) {
  return {};
});

/// Driver messages (recent messages from other drivers)
class ChatMessage {
  final String id;
  final String fromDriverId;
  final String fromDriverName;
  final String message;
  final DateTime timestamp;
  final bool isFromMe;

  ChatMessage({
    required this.id,
    required this.fromDriverId,
    required this.fromDriverName,
    required this.message,
    required this.timestamp,
    this.isFromMe = false,
  });
}

final driverMessagesProvider = StateProvider<List<ChatMessage>>((ref) {
  return [];
});

/// Unread message count
final unreadMessageCountProvider = StateProvider<int>((ref) {
  return 0;
});

/// Show map view during shift
final showMapViewProvider = StateProvider<bool>((ref) {
  return false;
});
