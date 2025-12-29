import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../../Container/utils/error_notification.dart';
import '../../../../Container/services/api_client.dart';
import '../../../Routes/routes.dart';

class SplashLogics {
  final ApiClient _apiClient = ApiClient();

  void initializeUser(BuildContext context) async {
    // Bypass login - go directly to home screen for testing
    Timer(
      const Duration(seconds: 2),
      () {
        if (context.mounted) {
          context.goNamed(Routes().home);
        }
      },
    );
  }

  /// [checkPermissions] checking the permission status
  void checkPermissions(BuildContext context) async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
        LocationPermission permission2 = await Geolocator.checkPermission();
        if (context.mounted &&
            (permission2 == LocationPermission.whileInUse ||
                permission2 == LocationPermission.always)) {
          initializeUser(context);
        } else {
          if (context.mounted) {
            ErrorNotification().showError(
                context, "Location Access is required to run BVI Park & Ride.");
          }
          await Future.delayed(const Duration(seconds: 2));
          SystemChannels.platform.invokeMethod("SystemNavigator.pop");
        }
        return;
      } else if (context.mounted &&
          (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always)) {
        initializeUser(context);
        return;
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        if (context.mounted) {
          ErrorNotification().showError(
              context, "Location Access is required to run BVI Park & Ride.");
          await Future.delayed(const Duration(seconds: 2));
          SystemChannels.platform.invokeMethod("SystemNavigator.pop");
        }
        return;
      }
    } catch (e) {
      if (context.mounted) {
        ErrorNotification().showError(context, "An Error Occurred $e");
      }
    }
  }
}
