import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';
import '../waiter/waiter_home_screen.dart';

/*
|--------------------------------------------------------------------------
| Splash Screen
|--------------------------------------------------------------------------
| Determines whether the user is already authenticated.
*/

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  /*
  |--------------------------------------------------------------------------
  | Initial Load
  |--------------------------------------------------------------------------
  */

  @override
  void initState() {
    super.initState();

    checkAuthentication();
  }

  /*
  |--------------------------------------------------------------------------
  | Check Authentication
  |--------------------------------------------------------------------------
  */

  Future<void> checkAuthentication() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('auth_token');

    /*
    |--------------------------------------------------------------------------
    | Token Found
    |--------------------------------------------------------------------------
    */

    if (token != null && token.isNotEmpty) {
      if (!mounted) return;

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WaiterHomeScreen()));

      return;
    }

    /*
    |--------------------------------------------------------------------------
    | No Token Found
    |--------------------------------------------------------------------------
    */

    if (!mounted) return;

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  /*
  |--------------------------------------------------------------------------
  | Build Screen
  |--------------------------------------------------------------------------
  */

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
