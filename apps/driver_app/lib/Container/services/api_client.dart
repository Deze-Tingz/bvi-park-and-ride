/// API Client Service for Driver App
///
/// Handles all HTTP requests to the NestJS backend.
/// Includes driver-specific endpoints for shift management.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// API configuration
class ApiConfig {
  // Change this to your backend URL
  static const String baseUrl = 'http://localhost:3000';
  static const String wsUrl = 'ws://localhost:3000';

  // For production, use:
  // static const String baseUrl = 'https://api.bviparkandride.com';
  // static const String wsUrl = 'wss://api.bviparkandride.com';
}

/// Provider for the API client
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// Main API client class
class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors for auth and error handling
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            _storage.delete(key: 'access_token');
          }
          return handler.next(error);
        },
      ),
    );
  }

  // ==================== AUTH ====================

  /// Register as a driver
  Future<Map<String, dynamic>> registerDriver({
    required String email,
    required String password,
    required String name,
    String? phone,
    required String licenseNumber,
  }) async {
    final response = await _dio.post('/auth/register-driver', data: {
      'email': email,
      'password': password,
      'name': name,
      'phone': phone,
      'licenseNumber': licenseNumber,
    });
    return response.data;
  }

  /// Login and get JWT token
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });

    if (response.data['accessToken'] != null) {
      await _storage.write(
        key: 'access_token',
        value: response.data['accessToken'],
      );
    }

    return response.data;
  }

  /// Get current user profile
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get('/auth/profile');
    return response.data;
  }

  /// Logout
  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
  }

  /// Check if logged in
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'access_token');
    return token != null;
  }

  /// Get stored token
  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }

  // ==================== DRIVER SHIFT ====================

  /// Start a shift
  Future<Map<String, dynamic>> startShift({
    required String vehicleId,
    required String routeId,
  }) async {
    final response = await _dio.post('/driver/shift/start', data: {
      'vehicleId': vehicleId,
      'routeId': routeId,
    });
    return response.data;
  }

  /// End current shift
  Future<Map<String, dynamic>> endShift() async {
    final response = await _dio.post('/driver/shift/end');
    return response.data;
  }

  /// Update driver status (full, out of service, etc.)
  Future<Map<String, dynamic>> updateStatus(String status) async {
    final response = await _dio.post('/driver/status', data: {
      'status': status,
    });
    return response.data;
  }

  /// Mark arrived at stop
  Future<Map<String, dynamic>> markArrivedAtStop(String stopId) async {
    final response = await _dio.post('/driver/stop/arrived', data: {
      'stopId': stopId,
    });
    return response.data;
  }

  /// Mark departed from stop
  Future<Map<String, dynamic>> markDepartedFromStop(String stopId) async {
    final response = await _dio.post('/driver/stop/departed', data: {
      'stopId': stopId,
    });
    return response.data;
  }

  // ==================== ROUTES ====================

  /// Get all routes
  Future<List<dynamic>> getRoutes() async {
    final response = await _dio.get('/routes');
    return response.data;
  }

  /// Get route by ID
  Future<Map<String, dynamic>> getRoute(String id) async {
    final response = await _dio.get('/routes/$id');
    return response.data;
  }

  /// Get stops for a route
  Future<List<dynamic>> getRouteStops(String routeId) async {
    final response = await _dio.get('/routes/$routeId/stops');
    return response.data;
  }

  // ==================== VEHICLES ====================

  /// Get available vehicles
  Future<List<dynamic>> getAvailableVehicles() async {
    final response = await _dio.get('/vehicles', queryParameters: {
      'status': 'available',
    });
    return response.data;
  }

  /// Get vehicle by ID
  Future<Map<String, dynamic>> getVehicle(String id) async {
    final response = await _dio.get('/vehicles/$id');
    return response.data;
  }
}
