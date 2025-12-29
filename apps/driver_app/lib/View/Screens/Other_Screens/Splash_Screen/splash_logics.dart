import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../../Container/utils/error_notification.dart';
import '../../../Routes/routes.dart';

class SplashLogics {
  void initializeApp(BuildContext context) async {
    // Navigate to main screen after splash
    Timer(const Duration(seconds: 3), () {
      context.goNamed(Routes().home);
    });
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
          initializeApp(context);
        } else {
          if (context.mounted) {
            ErrorNotification().showError(
                context, "Location Access is required for BVI Park & Ride.");
          }
          await Future.delayed(const Duration(seconds: 2));
          SystemChannels.platform
              .invokeMethod("SystemNavigator.exitApplication");
        }
        return;
      } else if (context.mounted &&
          (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always)) {
        initializeApp(context);
        return;
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        if (context.mounted) {
          ErrorNotification().showError(
              context, "Location Access is required for BVI Park & Ride.");
          await Future.delayed(const Duration(seconds: 2));
          SystemChannels.platform
              .invokeMethod("SystemNavigator.exitApplication");
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