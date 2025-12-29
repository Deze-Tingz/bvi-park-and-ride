/// WebSocket Service for Driver App
///
/// Handles WebSocket connections for:
/// - Broadcasting driver's GPS location to backend
/// - Receiving other vehicle positions (monitor up to 3 shuttles)
/// - Driver-to-driver messaging

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_client.dart';

/// Vehicle update model (for receiving other drivers' positions)
class VehicleUpdate {
  final String vehicleId;
  final String routeId;
  final double latitude;
  final double longitude;
  final double? speed;
  final double? heading;
  final String status;
  final DateTime timestamp;

  VehicleUpdate({
    required this.vehicleId,
    required this.routeId,
    required this.latitude,
    required this.longitude,
    this.speed,
    this.heading,
    required this.status,
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
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

/// Driver message model
class DriverMessage {
  final String id;
  final String fromDriverId;
  final String fromDriverName;
  final String? toDriverId; // null = broadcast to all
  final String message;
  final DateTime timestamp;

  DriverMessage({
    required this.id,
    required this.fromDriverId,
    required this.fromDriverName,
    this.toDriverId,
    required this.message,
    required this.timestamp,
  });

  factory DriverMessage.fromJson(Map<String, dynamic> json) {
    return DriverMessage(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      fromDriverId: json['fromDriverId'] ?? '',
      fromDriverName: json['fromDriverName'] ?? 'Driver',
      toDriverId: json['toDriverId'],
      message: json['message'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

/// Provider for socket service
final socketServiceProvider = Provider<DriverSocketService>((ref) {
  return DriverSocketService();
});

/// Connection state provider
final connectionStateProvider = StateProvider<bool>((ref) => false);

/// Stream provider for vehicle updates
final vehicleUpdatesProvider = StreamProvider<VehicleUpdate>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return socketService.vehicleUpdates;
});

/// Stream provider for incoming driver messages
final incomingDriverMessagesProvider = StreamProvider<DriverMessage>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return socketService.driverMessages;
});

/// Main driver socket service class
class DriverSocketService {
  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentVehicleId;
  String? _currentRouteId;
  String? _currentDriverId;
  String? _currentDriverName;

  // Stream controllers
  final _vehicleUpdateController = StreamController<VehicleUpdate>.broadcast();
  final _driverMessageController = StreamController<DriverMessage>.broadcast();

  // Expose streams
  Stream<VehicleUpdate> get vehicleUpdates => _vehicleUpdateController.stream;
  Stream<DriverMessage> get driverMessages => _driverMessageController.stream;

  bool get isConnected => _isConnected;
  String? get currentVehicleId => _currentVehicleId;

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
      _isConnected = true;

      // Re-register if we have vehicle info
      if (_currentVehicleId != null && _currentRouteId != null) {
        registerDriver(_currentVehicleId!, _currentRouteId!);
      }
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
    });

    _socket!.onConnectError((error) {
      _isConnected = false;
    });

    // Listen for other vehicle updates
    _socket!.on('vehicle:update', (data) {
      try {
        final update = VehicleUpdate.fromJson(data as Map<String, dynamic>);
        // Don't add our own vehicle
        if (update.vehicleId != _currentVehicleId) {
          _vehicleUpdateController.add(update);
        }
      } catch (e) {
        // Silent fail
      }
    });

    // Listen for driver messages
    _socket!.on('driver:message', (data) {
      try {
        final message = DriverMessage.fromJson(data as Map<String, dynamic>);
        // Don't add our own messages
        if (message.fromDriverId != _currentDriverId) {
          _driverMessageController.add(message);
        }
      } catch (e) {
        // Silent fail
      }
    });

    // Listen for any server responses
    _socket!.on('registered', (data) {
      // Registration successful
    });

    _socket!.on('error', (data) {
      // Server error
    });
  }

  /// Register the driver with their vehicle and route
  void registerDriver(String vehicleId, String routeId, {String? driverId, String? driverName}) {
    _currentVehicleId = vehicleId;
    _currentRouteId = routeId;
    _currentDriverId = driverId;
    _currentDriverName = driverName;

    if (_socket != null && _isConnected) {
      _socket!.emit('driver:register', {
        'vehicleId': vehicleId,
        'routeId': routeId,
        'driverId': driverId,
        'driverName': driverName,
      });
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

  /// Send a message to other drivers
  void sendMessage(String message, {String? toDriverId}) {
    if (_socket != null && _isConnected && _currentDriverId != null) {
      _socket!.emit('driver:message', {
        'fromDriverId': _currentDriverId,
        'fromDriverName': _currentDriverName ?? 'Driver',
        'toDriverId': toDriverId, // null = broadcast to all
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Send a quick status message (predefined messages)
  void sendQuickMessage(QuickMessage type) {
    final messages = {
      QuickMessage.onMyWay: "On my way!",
      QuickMessage.runningLate: "Running a few minutes late",
      QuickMessage.atStop: "At the stop now",
      QuickMessage.busIsFull: "Bus is full",
      QuickMessage.needAssistance: "Need assistance",
      QuickMessage.allClear: "All clear",
    };
    sendMessage(messages[type] ?? "");
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
      _currentDriverId = null;
      _currentDriverName = null;
    }
  }

  /// Dispose the service
  void dispose() {
    disconnect();
    _vehicleUpdateController.close();
    _driverMessageController.close();
  }
}

/// Quick message types for driver communication
enum QuickMessage {
  onMyWay,
  runningLate,
  atStop,
  busIsFull,
  needAssistance,
  allClear,
}
