import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../View/Routes/routes.dart';
import '../utils/error_notification.dart';
import '../services/api_client.dart';

/// [authRepoProvider] used to cache the [AuthRepo] class to prevent it from creating multiple instances
final globalAuthRepoProvider = Provider<AuthRepo>((ref) {
  return AuthRepo();
});

/// [AuthRepo] provides functions used for authentication purposes
class AuthRepo {
  final ApiClient _apiClient = ApiClient();

  void loginUser(String email, String password, BuildContext context) async {
    try {
      final result = await _apiClient.login(email, password);
      // Login successful if we get a response with access token
      if (result['accessToken'] != null && context.mounted) {
        context.goNamed(Routes().home);
      }
    } catch (e) {
      if (context.mounted) {
        ErrorNotification().showError(context, "Login failed: ${e.toString()}");
      }
    }
  }

  void registerUser(String email, String password, BuildContext context) async {
    try {
      await _apiClient.register(email, password);
      // After successful registration, login
      if (context.mounted) {
        loginUser(email, password, context);
      }
    } catch (e) {
      if (context.mounted) {
        ErrorNotification()
            .showError(context, "Registration failed: ${e.toString()}");
      }
    }
  }

  Future<void> logout(BuildContext context) async {
    try {
      await _apiClient.logout();
      if (context.mounted) {
        context.goNamed(Routes().login);
      }
    } catch (e) {
      if (context.mounted) {
        ErrorNotification().showError(context, "An Error Occurred: $e");
      }
    }
  }
}
