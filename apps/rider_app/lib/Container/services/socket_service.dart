/// WebSocket Service for Real-time Tracking
///
/// Handles WebSocket connections to receive live vehicle
/// position updates from the backend.
///
/// This is what makes the app feel "Uber-like" - vehicles
/// move smoothly on the map in real-time.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_client.dart';

/// Vehicle update model
class VehicleUpdate {
  final String vehicleId;
  final String routeId;
  final double latitude;
  final double longitude;
  final double? speed;
  final double? heading;
  final String status;
  final String? nextStopId;
  final int? nextStopEta; // seconds
  final DateTime timestamp;

  VehicleUpdate({
    required this.vehicleId,
    required this.routeId,
    required this.latitude,
    required this.longitude,
    this.speed,
    this.heading,
    required this.status,
    this.nextStopId,
    this.nextStopEta,
    required this.timestamp,
  });

  factory VehicleUpdate.fromJson(Map<String, dynamic> json) {
    return VehicleUpdate(
      vehicleId: json['vehicleId'] ?? '',
      routeId: json['routeId'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      speed: json['speed']?.toDouble(),
      heading: json['heading']?.toDouble(),
      status: json['status'] ?? 'unknown',
      nextStopId: json['nextStopId'],
      nextStopEta: json['nextStopEta'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

/// Stop arrival notification
class StopArrival {
  final String vehicleId;
  final String stopId;
  final String stopName;
  final DateTime timestamp;

  StopArrival({
    required this.vehicleId,
    required this.stopId,
    required this.stopName,
    required this.timestamp,
  });

  factory StopArrival.fromJson(Map<String, dynamic> json) {
    return StopArrival(
      vehicleId: json['vehicleId'] ?? '',
      stopId: json['stopId'] ?? '',
      stopName: json['stopName'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

/// Broadcast alert
class BroadcastAlert {
  final String type; // 'info' | 'warning' | 'emergency'
  final String title;
  final String message;
  final DateTime timestamp;

  BroadcastAlert({
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
  });

  factory BroadcastAlert.fromJson(Map<String, dynamic> json) {
    return BroadcastAlert(
      type: json['type'] ?? 'info',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

/// Provider for socket service
final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService();
});

/// Stream provider for vehicle updates
final vehicleUpdatesProvider = StreamProvider<VehicleUpdate>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return socketService.vehicleUpdates;
});

/// Stream provider for stop arrivals
final stopArrivalsProvider = StreamProvider<StopArrival>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return socketService.stopArrivals;
});

/// Stream provider for alerts
final alertsProvider = StreamProvider<BroadcastAlert>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return socketService.alerts;
});

/// Main socket service class
class SocketService {
  IO.Socket? _socket;
  bool _isConnected = false;

  // Stream controllers for different event types
  final _vehicleUpdateController = StreamController<VehicleUpdate>.broadcast();
  final _stopArrivalController = StreamController<StopArrival>.broadcast();
  final _alertController = StreamController<BroadcastAlert>.broadcast();

  // Expose streams
  Stream<VehicleUpdate> get vehicleUpdates => _vehicleUpdateController.stream;
  Stream<StopArrival> get stopArrivals => _stopArrivalController.stream;
  Stream<BroadcastAlert> get alerts => _alertController.stream;

  bool get isConnected => _isConnected;

  /// Connect to the WebSocket server
  void connect({String? authToken}) {
    if (_socket != null) {
      _socket!.dispose();
    }

    _socket = IO.io(
      '${ApiConfig.wsUrl}/tracking',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setAuth({'token': authToken ?? ''})
          .build(),
    );

    // Connection events
    _socket!.onConnect((_) {
      print('Socket connected');
      _isConnected = true;
    });

    _socket!.onDisconnect((_) {
      print('Socket disconnected');
      _isConnected = false;
    });

    _socket!.onConnectError((error) {
      print('Socket connection error: $error');
      _isConnected = false;
    });

    // Vehicle position updates
    _socket!.on('vehicle:update', (data) {
      try {
        final update = VehicleUpdate.fromJson(data as Map<String, dynamic>);
        _vehicleUpdateController.add(update);
      } catch (e) {
        print('Error parsing vehicle update: $e');
      }
    });

    // Stop arrival notifications
    _socket!.on('stop:arrival', (data) {
      try {
        final arrival = StopArrival.fromJson(data as Map<String, dynamic>);
        _stopArrivalController.add(arrival);
      } catch (e) {
        print('Error parsing stop arrival: $e');
      }
    });

    // Broadcast alerts
    _socket!.on('alert:broadcast', (data) {
      try {
        final alert = BroadcastAlert.fromJson(data as Map<String, dynamic>);
        _alertController.add(alert);
      } catch (e) {
        print('Error parsing alert: $e');
      }
    });
  }

  /// Subscribe to a specific route's updates
  void subscribeToRoute(String routeId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('subscribe:route', {'routeId': routeId});
      print('Subscribed to route: $routeId');
    }
  }

  /// Unsubscribe from a route
  void unsubscribeFromRoute(String routeId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('unsubscribe:route', {'routeId': routeId});
      print('Unsubscribed from route: $routeId');
    }
  }

  /// Disconnect from the server
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
    }
  }

  /// Dispose the service
  void dispose() {
    disconnect();
    _vehicleUpdateController.close();
    _stopArrivalController.close();
    _alertController.close();
  }
}
