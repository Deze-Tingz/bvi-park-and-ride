/// WebSocket Service for Driver App
///
/// Handles WebSocket connections for broadcasting
/// the driver's GPS location to the backend.
///
/// Key difference from rider app: This SENDS location
/// updates, while the rider app RECEIVES them.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_client.dart';

/// Provider for socket service
final socketServiceProvider = Provider<DriverSocketService>((ref) {
  return DriverSocketService();
});

/// Connection state provider
final connectionStateProvider = StateProvider<bool>((ref) => false);

/// Main driver socket service class
class DriverSocketService {
  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentVehicleId;
  String? _currentRouteId;

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
      print('Driver socket connected');
      _isConnected = true;

      // Re-register if we have vehicle info
      if (_currentVehicleId != null && _currentRouteId != null) {
        registerDriver(_currentVehicleId!, _currentRouteId!);
      }
    });

    _socket!.onDisconnect((_) {
      print('Driver socket disconnected');
      _isConnected = false;
    });

    _socket!.onConnectError((error) {
      print('Driver socket connection error: $error');
      _isConnected = false;
    });

    // Listen for any server responses
    _socket!.on('registered', (data) {
      print('Driver registered successfully: $data');
    });

    _socket!.on('error', (data) {
      print('Server error: $data');
    });
  }

  /// Register the driver with their vehicle and route
  void registerDriver(String vehicleId, String routeId) {
    _currentVehicleId = vehicleId;
    _currentRouteId = routeId;

    if (_socket != null && _isConnected) {
      _socket!.emit('driver:register', {
        'vehicleId': vehicleId,
        'routeId': routeId,
      });
      print('Driver registered: vehicle=$vehicleId, route=$routeId');
    }
  }

  /// Send location update to backend
  /// Call this every 1-3 seconds when moving
  void sendLocationUpdate({
    required String vehicleId,
    required double latitude,
    required double longitude,
    double? speed,
    double? heading,
    double? accuracy,
  }) {
    if (_socket != null && _isConnected) {
      _socket!.emit('driver:location', {
        'vehicleId': vehicleId,
        'latitude': latitude,
        'longitude': longitude,
        'speed': speed ?? 0,
        'heading': heading ?? 0,
        'accuracy': accuracy ?? 0,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Notify server of arrival at stop
  void sendStopArrival(String vehicleId, String stopId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('stop:arrived', {
        'vehicleId': vehicleId,
        'stopId': stopId,
      });
      print('Stop arrival sent: $stopId');
    }
  }

  /// Notify server of departure from stop
  void sendStopDeparture(String vehicleId, String stopId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('stop:departed', {
        'vehicleId': vehicleId,
        'stopId': stopId,
      });
      print('Stop departure sent: $stopId');
    }
  }

  /// Disconnect from the server
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      _currentVehicleId = null;
      _currentRouteId = null;
    }
  }

  /// Dispose the service
  void dispose() {
    disconnect();
  }
}
