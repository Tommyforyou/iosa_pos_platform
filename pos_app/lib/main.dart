import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'screens/auth/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/server_settings_screen.dart';

/*
|--------------------------------------------------------------------------
| Main Entry Point
|--------------------------------------------------------------------------
*/

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /*
  |--------------------------------------------------------------------------
  | Windows Window Settings
  |--------------------------------------------------------------------------
  */

  if (Platform.isWindows) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(1600, 950),
      minimumSize: Size(1200, 800),
      center: true,
      title: 'IOSA POS 2026 V1.0',
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const IOSAPOSApp());
}

/*
|--------------------------------------------------------------------------
| IOSA POS App
|--------------------------------------------------------------------------
*/

class IOSAPOSApp extends StatelessWidget {
  const IOSAPOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IOSA POS 2026 V1.0',
      theme: ThemeData(colorSchemeSeed: Colors.blueGrey, useMaterial3: true),
      home: const PlatformStartupScreen(),
    );
  }
}

/*
|--------------------------------------------------------------------------
| Platform Startup Screen
|--------------------------------------------------------------------------
| Windows:
| - Checks server_url
| - If missing, opens Server Settings
| - If configured, opens Windows POS Home
|
| Android:
| - Opens Waiter App Splash Screen
| - Splash handles QR server setup and login
*/

class PlatformStartupScreen extends StatefulWidget {
  const PlatformStartupScreen({super.key});

  @override
  State<PlatformStartupScreen> createState() => _PlatformStartupScreenState();
}

class _PlatformStartupScreenState extends State<PlatformStartupScreen> {
  Widget? nextScreen;

  @override
  void initState() {
    super.initState();

    checkStartupFlow();
  }

  /*
  |--------------------------------------------------------------------------
  | Check Startup Flow
  |--------------------------------------------------------------------------
  */

  Future<void> checkStartupFlow() async {
    /*
    |--------------------------------------------------------------------------
    | Android Waiter App
    |--------------------------------------------------------------------------
    */

    if (Platform.isAndroid) {
      if (!mounted) return;

      setState(() {
        nextScreen = const SplashScreen();
      });

      return;
    }

    /*
    |--------------------------------------------------------------------------
    | Windows POS App
    |--------------------------------------------------------------------------
    */

    if (Platform.isWindows) {
      final prefs = await SharedPreferences.getInstance();

      final serverUrl = prefs.getString('server_url');

      if (!mounted) return;

      setState(() {
        nextScreen = serverUrl == null || serverUrl.isEmpty
            ? const ServerSettingsScreen()
            : const HomeScreen();
      });

      return;
    }

    /*
    |--------------------------------------------------------------------------
    | Fallback
    |--------------------------------------------------------------------------
    */

    if (!mounted) return;

    setState(() {
      nextScreen = const HomeScreen();
    });
  }

  /*
  |--------------------------------------------------------------------------
  | Build
  |--------------------------------------------------------------------------
  */

  @override
  Widget build(BuildContext context) {
    if (nextScreen == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return nextScreen!;
  }
}
