import 'package:flutter/material.dart';

import 'kiosk_order_screen.dart';

/*
|--------------------------------------------------------------------------
| Kiosk Home Screen
|--------------------------------------------------------------------------
| Touch-friendly self-ordering start screen.
*/

class KioskHomeScreen extends StatelessWidget {
  const KioskHomeScreen({super.key});

  /*
  |--------------------------------------------------------------------------
  | Open Kiosk Order
  |--------------------------------------------------------------------------
  */

  void openKioskOrder(BuildContext context, String orderType) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => KioskOrderScreen(orderType: orderType)),
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Build Screen
  |--------------------------------------------------------------------------
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Self Ordering Kiosk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Exit Kiosk',
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.restaurant_menu,
                  size: 90,
                  color: Colors.orange,
                ),

                const SizedBox(height: 20),

                const Text(
                  'IOSA RESTAURANT',
                  style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Please choose how you would like to order',
                  style: TextStyle(fontSize: 22, color: Colors.grey),
                ),

                const SizedBox(height: 60),

                Row(
                  children: [
                    Expanded(
                      child: _KioskOptionCard(
                        title: 'DINE IN',
                        subtitle: 'Eat at restaurant',
                        icon: Icons.table_restaurant,
                        color: Colors.orange,
                        onTap: () => openKioskOrder(context, 'dine_in'),
                      ),
                    ),

                    const SizedBox(width: 32),

                    Expanded(
                      child: _KioskOptionCard(
                        title: 'TAKEAWAY',
                        subtitle: 'Collect at counter',
                        icon: Icons.shopping_bag,
                        color: Colors.green,
                        onTap: () => openKioskOrder(context, 'takeaway'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/*
|--------------------------------------------------------------------------
| Kiosk Option Card
|--------------------------------------------------------------------------
*/

class _KioskOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _KioskOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  /*
  |--------------------------------------------------------------------------
  | Build Card
  |--------------------------------------------------------------------------
  */

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Container(
        height: 380,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withOpacity(0.30), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 120, color: color),

            const SizedBox(height: 24),

            Text(
              title,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              subtitle,
              style: const TextStyle(fontSize: 20, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
