import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../waiter/waiter_home_screen.dart';

/*
|--------------------------------------------------------------------------
| Login Screen
|--------------------------------------------------------------------------
| Handles mobile waiter login using Laravel Sanctum.
|
| Flow:
| - User enters email and password
| - App calls /api/mobile/login
| - Laravel returns Sanctum token
| - Token and user details are saved locally
| - User is redirected to Waiter Home Screen
*/

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/*
|--------------------------------------------------------------------------
| Login Screen State
|--------------------------------------------------------------------------
*/

class _LoginScreenState extends State<LoginScreen> {
  /*
  |--------------------------------------------------------------------------
  | Form Controllers
  |--------------------------------------------------------------------------
  */

  final TextEditingController emailController = TextEditingController(text: 'admin@iosa.com');

  final TextEditingController passwordController = TextEditingController(text: '123456');

  /*
  |--------------------------------------------------------------------------
  | Services And State
  |--------------------------------------------------------------------------
  */

  final ApiService apiService = ApiService();

  bool isLoading = false;
  bool obscurePassword = true;

  /*
  |--------------------------------------------------------------------------
  | Dispose Controllers
  |--------------------------------------------------------------------------
  */

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /*
  |--------------------------------------------------------------------------
  | Login
  |--------------------------------------------------------------------------
  */

  Future<void> login() async {
    /*
    |--------------------------------------------------------------------------
    | Prevent Duplicate Submission
    |--------------------------------------------------------------------------
    */
    debugPrint('STEP 1 - Login button pressed');
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      /*
      |--------------------------------------------------------------------------
      | Call Login API
      |--------------------------------------------------------------------------
      */
      debugPrint('STEP 2 - Calling API');
      final result = await apiService.waiterLogin(email: emailController.text.trim(), password: passwordController.text.trim());

      debugPrint('STEP 3 - API returned');
      debugPrint(result.toString());
      /*
      |--------------------------------------------------------------------------
      | Save Token Locally
      |--------------------------------------------------------------------------
      */

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('auth_token', result['token']);
      await prefs.setInt('user_id', result['user']['id']);
      await prefs.setString('user_name', result['user']['name']);
      await prefs.setString('user_email', result['user']['email']);

      /*
      |--------------------------------------------------------------------------
      | Redirect To Waiter Home
      |--------------------------------------------------------------------------
      */

      if (!mounted) return;

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WaiterHomeScreen()));
    } catch (e) {
      debugPrint('STEP 4 - ERROR');
      debugPrint(e.toString());
      /*
      |--------------------------------------------------------------------------
      | Login Failed
      |--------------------------------------------------------------------------
      */

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      /*
      |--------------------------------------------------------------------------
      | Reset Loading State
      |--------------------------------------------------------------------------
      */

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Build Screen
  |--------------------------------------------------------------------------
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 6,
            margin: const EdgeInsets.all(20),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /*
                  |--------------------------------------------------------------------------
                  | Header
                  |--------------------------------------------------------------------------
                  */
                  const Icon(Icons.restaurant, size: 64),

                  const SizedBox(height: 16),

                  const Text('IOSA POS', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),

                  const SizedBox(height: 4),

                  const Text('Waiter Login', style: TextStyle(fontSize: 16)),

                  const SizedBox(height: 24),

                  /*
                  |--------------------------------------------------------------------------
                  | Email
                  |--------------------------------------------------------------------------
                  */
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email), border: OutlineInputBorder()),
                  ),

                  const SizedBox(height: 16),

                  /*
                  |--------------------------------------------------------------------------
                  | Password
                  |--------------------------------------------------------------------------
                  */
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                        icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  /*
                  |--------------------------------------------------------------------------
                  | Login Button
                  |--------------------------------------------------------------------------
                  */
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : login,
                      icon: isLoading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.login),
                      label: Text(isLoading ? 'Logging in...' : 'Login'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
