import 'package:flutter/material.dart';

/*
|--------------------------------------------------------------------------
| Kiosk Success Screen
|--------------------------------------------------------------------------
*/

class KioskSuccessScreen extends StatelessWidget {
  final dynamic orderId;

  const KioskSuccessScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),

          child: Card(
            elevation: 8,

            child: Padding(
              padding: const EdgeInsets.all(50),

              child: Column(
                mainAxisSize: MainAxisSize.min,

                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 120,
                    color: Colors.green,
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    'THANK YOU',
                    style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Order #$orderId',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    'Your order has been sent successfully.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Please proceed to the cashier for payment.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20),
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: 300,
                    height: 70,

                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },

                      child: const Text(
                        'START NEW ORDER',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
