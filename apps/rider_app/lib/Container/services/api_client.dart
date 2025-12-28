/// API Client Service
///
/// Handles all HTTP requests to the NestJS backend.
/// Uses Dio for HTTP operations with interceptors for
/// authentication and error handling.

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
          // Add auth token to requests
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // Handle common errors
          if (error.response?.statusCode == 401) {
            // Token expired - clear storage and redirect to login
            _storage.delete(key: 'access_token');
          }
          return handler.next(error);
        },
      ),
    );
  }

  // ==================== AUTH ====================

  /// Register a new user
  Future<Map<String, dynamic>> register(String email, String password) async {
    final response = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
    });
    return response.data;
  }

  /// Login and get JWT token
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });

    // Store the token
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

  /// Logout - clear stored token
  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'access_token');
    return token != null;
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

  // ==================== STOPS ====================

  /// Get all stops
  Future<List<dynamic>> getStops() async {
    final response = await _dio.get('/stops');
    return response.data;
  }

  /// Get stop by ID
  Future<Map<String, dynamic>> getStop(String id) async {
    final response = await _dio.get('/stops/$id');
    return response.data;
  }

  /// Get nearest stop to coordinates
  Future<Map<String, dynamic>> getNearestStop(double lat, double lng) async {
    final response = await _dio.get('/stops/nearest', queryParameters: {
      'lat': lat,
      'lng': lng,
    });
    return response.data;
  }

  // ==================== VEHICLES ====================

  /// Get all vehicles
  Future<List<dynamic>> getVehicles() async {
    final response = await _dio.get('/vehicles');
    return response.data;
  }

  /// Get vehicle by ID
  Future<Map<String, dynamic>> getVehicle(String id) async {
    final response = await _dio.get('/vehicles/$id');
    return response.data;
  }

  // ==================== ETA ====================

  /// Get ETA to a specific stop
  Future<Map<String, dynamic>> getEta(String stopId) async {
    final response = await _dio.get('/eta/$stopId');
    return response.data;
  }

  /// Get ETAs for all stops on a route
  Future<List<dynamic>> getRouteEtas(String routeId) async {
    final response = await _dio.get('/eta/route/$routeId');
    return response.data;
  }
}
