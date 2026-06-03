import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'order_screen.dart';

/*
|--------------------------------------------------------------------------
| Table Screen
|--------------------------------------------------------------------------
| This screen displays all restaurant tables for dine-in service.
|
| Main responsibilities:
| - Load restaurant tables from Laravel API
| - Display table statuses
| - Open dine-in order screen
|
| Table statuses:
| - available
| - occupied
| - reserved (future)
| - cleaning (future)
|
| This screen is mainly used by:
| - waiters
| - cashiers
| - floor managers
*/

class TableScreen extends StatefulWidget {
  const TableScreen({super.key});

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  /*
  |--------------------------------------------------------------------------
  | API Service
  |--------------------------------------------------------------------------
  | Handles communication with Laravel backend.
  */
  final ApiService apiService = ApiService();

  /*
  |--------------------------------------------------------------------------
  | Screen State
  |--------------------------------------------------------------------------
  | tables: loaded restaurant tables
  | isLoading: loading indicator state
  */
  List<dynamic> tables = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    /*
    |--------------------------------------------------------------------------
    | Initial Data Load
    |--------------------------------------------------------------------------
    | Loads restaurant tables immediately when screen opens.
    */
    loadTables();
  }

  /*
  |--------------------------------------------------------------------------
  | Load Restaurant Tables
  |--------------------------------------------------------------------------
  | Fetches all tables from Laravel backend.
  */
  Future<void> loadTables() async {
    try {
      final data = await apiService.getRestaurantTables();

      if (!mounted) return;

      setState(() {
        tables = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Table Status Color Helper
  |--------------------------------------------------------------------------
  | Returns table card color based on current table status.
  */
  Color tableColor(String status) {
    switch (status) {
      case 'occupied':
        return Colors.red.shade400;

      case 'reserved':
        return Colors.orange.shade400;

      case 'cleaning':
        return Colors.blueGrey.shade400;

      case 'available':
      default:
        return Colors.green.shade400;
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Open Dine-In Order Screen
  |--------------------------------------------------------------------------
  | Opens order-taking screen for selected restaurant table.
  */
  void openTableOrder(dynamic table) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderScreen(table: table, orderType: 'dine_in'),
      ),
    ).then((_) {
      /*
      |--------------------------------------------------------------------------
      | Refresh Tables After Returning
      |--------------------------------------------------------------------------
      | Ensures updated occupied/available statuses are reloaded.
      */
      setState(() {
        isLoading = true;
      });

      loadTables();
    });
  }

  /*
|--------------------------------------------------------------------------
| Build Screen
|--------------------------------------------------------------------------
*/

  @override
  Widget build(BuildContext context) {
    /*
  |--------------------------------------------------------------------------
  | Responsive Layout
  |--------------------------------------------------------------------------
  | Windows/Desktop:
  | - Large square table cards
  |
  | Android/Mobile:
  | - Compact horizontal table rows
  */

    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Tables'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: loadTables)],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tables.isEmpty
          ? const Center(child: Text('No restaurant tables found'))
          : GridView.builder(
              padding: EdgeInsets.all(isMobile ? 8 : 12),
              itemCount: tables.length,

              /*
                |--------------------------------------------------------------------------
                | Responsive Table Grid
                |--------------------------------------------------------------------------
                */
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isMobile ? 1 : 4,
                crossAxisSpacing: isMobile ? 8 : 12,
                mainAxisSpacing: isMobile ? 8 : 12,
                childAspectRatio: isMobile ? 5.5 : 1.1,
              ),

              itemBuilder: (context, index) {
                final table = tables[index];

                final status = table['status']?.toString() ?? 'available';

                return Card(
                  elevation: 5,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),

                    /*
                      |--------------------------------------------------------------------------
                      | Open Table Order
                      |--------------------------------------------------------------------------
                      */
                    onTap: () => openTableOrder(table),

                    child: Container(
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: tableColor(status)),

                      /*
                        |--------------------------------------------------------------------------
                        | Mobile Table Card
                        |--------------------------------------------------------------------------
                        */
                      child: isMobile
                          ? Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.table_restaurant, size: 18, color: Colors.white),

                                  const SizedBox(width: 8),

                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          table['table_name'] ?? 'Table',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),

                                        if (table['capacity'] != null)
                                          Text('${table['capacity']} seats', style: const TextStyle(color: Colors.white70, fontSize: 9)),
                                      ],
                                    ),
                                  ),

                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(20)),
                                    child: Text(
                                      status == 'occupied' ? 'BUSY' : status.toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          /*
                            |--------------------------------------------------------------------------
                            | Desktop Table Card
                            |--------------------------------------------------------------------------
                            */
                          : Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.table_restaurant, size: 52, color: Colors.white),

                                  const SizedBox(height: 16),

                                  Text(
                                    table['table_name'] ?? 'Table',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                  ),

                                  const SizedBox(height: 10),

                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.20), borderRadius: BorderRadius.circular(20)),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),

                                  if (table['capacity'] != null) ...[
                                    const SizedBox(height: 10),
                                    Text('Capacity: ${table['capacity']}', style: const TextStyle(color: Colors.white70)),
                                  ],
                                ],
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
