import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bvi_driver_app/View/Routes/routes.dart';
import 'package:bvi_driver_app/View/Screens/Auth_Screens/Driver_config/driver_config.dart';
import 'package:bvi_driver_app/View/Screens/Auth_Screens/Login_Screen/login_screen.dart';
import 'package:bvi_driver_app/View/Screens/Auth_Screens/Register_Screen/register_screen.dart';
import 'package:bvi_driver_app/View/Screens/Main_Screens/Home_Screen/home_screen.dart';
import 'package:bvi_driver_app/View/Screens/Other_Screens/Splash_Screen/splash_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

final GoRouter router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/${Routes().splash}',
  routes: allRoutes,
);

final List<RouteBase> allRoutes = [
  // Splash Screen
  GoRoute(
    name: Routes().splash,
    path: '/${Routes().splash}',
    builder: (BuildContext context, GoRouterState state) {
      return const SplashScreen();
    },
  ),

  // Auth Routes
  GoRoute(
    name: Routes().login,
    path: '/${Routes().login}',
    builder: (BuildContext context, GoRouterState state) {
      return const LoginScreen();
    },
  ),
  GoRoute(
    name: Routes().register,
    path: '/${Routes().register}',
    builder: (BuildContext context, GoRouterState state) {
      return const RegisterScreen();
    },
  ),
  GoRoute(
    name: Routes().driverConfig,
    path: '/${Routes().driverConfig}',
    builder: (BuildContext context, GoRouterState state) {
      return const DriverConfigsScreen();
    },
  ),

  // Main Screen
  GoRoute(
    name: Routes().home,
    path: '/${Routes().home}',
    builder: (BuildContext context, GoRouterState state) {
      return const HomeScreen();
    },
  ),
];

