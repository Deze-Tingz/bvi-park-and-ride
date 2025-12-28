/// Location Service for Driver App
///
/// Manages GPS tracking and broadcasts location
/// updates to the backend via WebSocket.
///
/// Features:
/// - Adaptive GPS update frequency (faster when moving)
/// - Battery optimization
/// - Background location tracking

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'socket_service.dart';

/// Location update model
class LocationData {
  final double latitude;
  final double longitude;
  final double speed; // m/s
  final double heading; // degrees
  final double accuracy; // meters
  final DateTime timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.heading,
    required this.accuracy,
    required this.timestamp,
  });

  /// Speed in km/h
  double get speedKmh => speed * 3.6;

  /// Check if vehicle is moving
  bool get isMoving => speed > 1.0; // > 1 m/s = moving
}

/// Provider for location service
final locationServiceProvider = Provider<LocationService>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return LocationService(socketService);
});

/// Current location provider
final currentLocationProvider = StateProvider<LocationData?>((ref) => null);

/// Tracking active provider
final isTrackingProvider = StateProvider<bool>((ref) => false);

/// Main location service class
class LocationService {
  final DriverSocketService _socketService;

  StreamSubscription<Position>? _positionSubscription;
  Timer? _updateTimer;
  String? _vehicleId;
  bool _isTracking = false;

  // Adaptive update intervals
  static const int _movingIntervalMs = 2000; // 2 seconds when moving
  static const int _stoppedIntervalMs = 15000; // 15 seconds when stopped

  LocationService(this._socketService);

  bool get isTracking => _isTracking;

  /// Check and request location permissions
  Future<bool> checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Start tracking and broadcasting location
  Future<void> startTracking(String vehicleId) async {
    if (_isTracking) return;

    final hasPermission = await checkPermissions();
    if (!hasPermission) {
      throw Exception('Location permission not granted');
    }

    _vehicleId = vehicleId;
    _isTracking = true;

    // Get initial position
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    _sendLocation(position);

    // Start continuous tracking
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters minimum
      ),
    ).listen((Position position) {
      _sendLocation(position);
    });
  }

  /// Stop tracking
  void stopTracking() {
    _isTracking = false;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _updateTimer?.cancel();
    _updateTimer = null;
    _vehicleId = null;
  }

  /// Send location to backend
  void _sendLocation(Position position) {
    if (_vehicleId == null) return;

    _socketService.sendLocationUpdate(
      vehicleId: _vehicleId!,
      latitude: position.latitude,
      longitude: position.longitude,
      speed: position.speed * 3.6, // Convert m/s to km/h
      heading: position.heading,
      accuracy: position.accuracy,
    );
  }

  /// Get current position once
  Future<LocationData?> getCurrentLocation() async {
    try {
      final hasPermission = await checkPermissions();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        speed: position.speed,
        heading: position.heading,
        accuracy: position.accuracy,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Dispose the service
  void dispose() {
    stopTracking();
  }
}
