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

      setState(() {
        tables = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());

      setState(() {
        isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*
      |--------------------------------------------------------------------------
      | Background Styling
      |--------------------------------------------------------------------------
      */
      backgroundColor: const Color(0xFFF8FAFC),

      /*
      |--------------------------------------------------------------------------
      | App Bar
      |--------------------------------------------------------------------------
      */
      appBar: AppBar(
        title: const Text('Restaurant Tables'),

        actions: [
          /*
          |--------------------------------------------------------------------------
          | Manual Refresh Button
          |--------------------------------------------------------------------------
          | Reloads latest restaurant table statuses.
          */
          IconButton(
            onPressed: () {
              setState(() {
                isLoading = true;
              });

              loadTables();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      /*
      |--------------------------------------------------------------------------
      | Main Table Body
      |--------------------------------------------------------------------------
      */
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tables.isEmpty
          ? const Center(child: Text('No restaurant tables found', style: TextStyle(fontSize: 22)))
          : GridView.builder(
              padding: const EdgeInsets.all(4),
              itemCount: tables.length,

              /*
              |--------------------------------------------------------------------------
              | Table Grid Layout
              |--------------------------------------------------------------------------
              | Each card represents one restaurant table.
              */
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 5.5,
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

                      child: Padding(
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
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
