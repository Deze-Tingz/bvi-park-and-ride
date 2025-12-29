import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bvi_driver_app/Container/utils/error_notification.dart';
import 'package:bvi_driver_app/View/Routes/routes.dart';
import 'package:bvi_driver_app/View/Screens/Auth_Screens/Driver_config/driver_providers.dart';

class DriverLogics {
  /// Submit driver configuration
  /// For Park & Ride, driver configuration is typically done through admin dashboard.
  /// This is a simplified version that just navigates to the main screen.
  void sendDataToFirestore(
      BuildContext context,
      dynamic ref,
      TextEditingController carNameController,
      TextEditingController plateNumController) async {
    try {
      if (carNameController.text.isEmpty || plateNumController.text.isEmpty) {
        ErrorNotification()
            .showError(context, "Please Enter Vehicle Name and Plate Number");
        return;
      }
      ref
          .watch(driverConfigIsLoadingProvider.notifier)
          .update((state) => true);

      // TODO: Submit driver config to backend API
      // For now, just navigate to main screen
      await Future.delayed(const Duration(milliseconds: 500));

      ref
          .watch(driverConfigIsLoadingProvider.notifier)
          .update((state) => false);

      if (context.mounted) {
        context.goNamed(Routes().home);
      }
    } catch (e) {
      ref
          .watch(driverConfigIsLoadingProvider.notifier)
          .update((state) => false);
      ErrorNotification().showError(context, "An Error Occurred $e");
    }
  }
}
