import 'package:flutter/material.dart';

import '../services/api_service.dart';

/*
|--------------------------------------------------------------------------
| Supplier Screen
|--------------------------------------------------------------------------
| ERP supplier management dashboard.
*/

class SupplierScreen extends StatefulWidget {
  const SupplierScreen({super.key});

  @override
  State<SupplierScreen> createState() =>
      _SupplierScreenState();
}

class _SupplierScreenState
    extends State<SupplierScreen> {
  /*
  |--------------------------------------------------------------------------
  | API Service
  |--------------------------------------------------------------------------
  */

  final ApiService apiService = ApiService();

  /*
  |--------------------------------------------------------------------------
  | State
  |--------------------------------------------------------------------------
  */

  List<dynamic> suppliers = [];

  bool isLoading = true;

  final TextEditingController
      searchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    loadSuppliers();
  }

  @override
  void dispose() {
    searchController.dispose();

    super.dispose();
  }

  /*
  |--------------------------------------------------------------------------
  | Load Suppliers
  |--------------------------------------------------------------------------
  */

  Future<void> loadSuppliers() async {
    try {
      setState(() {
        isLoading = true;
      });

      final data =
          await apiService.getSuppliers(
        search:
            searchController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        suppliers = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  /*
  |--------------------------------------------------------------------------
  | KPI Count
  |--------------------------------------------------------------------------
  */

  int activeSuppliers() {
    return suppliers.where((supplier) {
      return supplier['is_active'] ==
          true;
    }).length;
  }

  /*
  |--------------------------------------------------------------------------
  | KPI Card
  |--------------------------------------------------------------------------
  */

  Widget kpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.all(18),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(22),

          border: Border.all(
            color: Colors.grey.shade200,
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withOpacity(0.04),

              blurRadius: 12,

              offset:
                  const Offset(0, 4),
            ),
          ],
        ),

        child: Row(
          children: [

            Container(
              width: 48,
              height: 48,

              decoration: BoxDecoration(
                color:
                    color.withOpacity(0.12),

                borderRadius:
                    BorderRadius.circular(
                        16),
              ),

              child: Icon(
                icon,
                color: color,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [

                  Text(
                    value,

                    overflow:
                        TextOverflow
                            .ellipsis,

                    style:
                        const TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                      height: 3),

                  Text(
                    title,

                    style: TextStyle(
                      color: Colors
                          .grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Supplier Info
  |--------------------------------------------------------------------------
  */

  Widget infoText({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      mainAxisSize:
          MainAxisSize.min,

      children: [

        Icon(
          icon,
          size: 16,
          color:
              Colors.grey.shade600,
        ),

        const SizedBox(width: 5),

        Text(
          '$label: ',

          style: TextStyle(
            color:
                Colors.grey.shade600,

            fontSize: 13,
          ),
        ),

        Text(
          value,

          style:
              const TextStyle(
            fontWeight:
                FontWeight.w600,

            fontSize: 13,
          ),
        ),
      ],
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Supplier Card
  |--------------------------------------------------------------------------
  */

  Widget supplierCard(
    dynamic supplier,
  ) {
    final name =
        supplier['name'] ??
            'Unknown Supplier';

    final brn =
        supplier['brn'] ?? '-';

    final vat =
        supplier['vat_number'] ??
            '-';

    final purchases =
        supplier[
                'purchases_count']
            ?.toString() ??
        '0';

    final active =
        supplier['is_active'] ==
            true;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),

      padding:
          const EdgeInsets.all(
        16,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
                22),

        border: Border.all(
          color:
              Colors.grey.shade200,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.03),

            blurRadius: 10,

            offset:
                const Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        children: [

          /*
          |--------------------------------------------------------------------------
          | Icon
          |--------------------------------------------------------------------------
          */

          Container(
            width: 54,
            height: 54,

            decoration:
                BoxDecoration(
              color: Colors.blue
                  .withOpacity(0.12),

              borderRadius:
                  BorderRadius
                      .circular(18),
            ),

            child: const Icon(
              Icons.business,

              color: Colors.blue,

              size: 28,
            ),
          ),

          const SizedBox(width: 14),

          /*
          |--------------------------------------------------------------------------
          | Supplier Details
          |--------------------------------------------------------------------------
          */

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [

                Row(
                  children: [

                    Expanded(
                      child: Text(
                        name,

                        overflow:
                            TextOverflow
                                .ellipsis,

                        style:
                            const TextStyle(
                          fontSize: 18,

                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),
                    ),

                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal:
                            10,

                        vertical: 5,
                      ),

                      decoration:
                          BoxDecoration(
                        color: active

                            ? Colors.green
                                .withOpacity(
                                    0.12)

                            : Colors.red
                                .withOpacity(
                                    0.12),

                        borderRadius:
                            BorderRadius
                                .circular(
                                    20),
                      ),

                      child: Text(
                        active
                            ? 'ACTIVE'
                            : 'INACTIVE',

                        style:
                            TextStyle(
                          color: active
                              ? Colors
                                  .green

                              : Colors
                                  .red,

                          fontWeight:
                              FontWeight
                                  .bold,

                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                    height: 8),

                Wrap(
                  spacing: 16,
                  runSpacing: 6,

                  children: [

                    infoText(
                      label: 'BRN',
                      value: brn,
                      icon:
                          Icons.badge,
                    ),

                    infoText(
                      label: 'VAT',
                      value: vat,
                      icon: Icons
                          .confirmation_number,
                    ),

                    infoText(
                      label:
                          'Purchases',
                      value: purchases,
                      icon: Icons
                          .shopping_cart_checkout,
                    ),
                  ],
                ),
              ],
            ),
          ),

          /*
          |--------------------------------------------------------------------------
          | Actions
          |--------------------------------------------------------------------------
          */

          ElevatedButton.icon(
            onPressed: () {

              /*
              |--------------------------------------------------------------------------
              | Supplier Detail
              |--------------------------------------------------------------------------
              */

            },

            icon: const Icon(
              Icons.visibility,
            ),

            label:
                const Text('View'),
          ),
        ],
      ),
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Build
  |--------------------------------------------------------------------------
  */

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(
        0xFFF4F6FA,
      ),

      body: SafeArea(
        child: Column(
          children: [

            /*
            |--------------------------------------------------------------------------
            | Header
            |--------------------------------------------------------------------------
            */

            Container(
              padding:
                  const EdgeInsets
                      .fromLTRB(
                24,
                18,
                24,
                18,
              ),

              decoration:
                  BoxDecoration(
                color: Colors.white,

                border: Border(
                  bottom:
                      BorderSide(
                    color: Colors
                        .grey
                        .shade200,
                  ),
                ),
              ),

              child: Row(
                children: [

                  IconButton(
                    onPressed: () {
                      Navigator.pop(
                          context);
                    },

                    icon: const Icon(
                      Icons
                          .arrow_back,
                    ),
                  ),

                  const SizedBox(
                      width: 8),

                  const Icon(
                    Icons.business,

                    color:
                        Colors.blue,

                    size: 32,
                  ),

                  const SizedBox(
                      width: 14),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [

                        Text(
                          'Suppliers',

                          style:
                              TextStyle(
                            fontSize:
                                26,

                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),

                        SizedBox(
                            height: 3),

                        Text(
                          'Manage suppliers and purchasing relationships.',

                          style:
                              TextStyle(
                            color: Colors
                                .grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  OutlinedButton
                      .icon(
                    onPressed:
                        loadSuppliers,

                    icon: const Icon(
                      Icons.refresh,
                    ),

                    label:
                        const Text(
                      'Refresh',
                    ),
                  ),
                ],
              ),
            ),

            /*
            |--------------------------------------------------------------------------
            | Content
            |--------------------------------------------------------------------------
            */

            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets
                        .all(22),

                child: Column(
                  children: [

                    /*
                    |--------------------------------------------------------------------------
                    | KPI
                    |--------------------------------------------------------------------------
                    */

                    Row(
                      children: [

                        kpiCard(
                          title:
                              'Total Suppliers',

                          value: suppliers
                              .length
                              .toString(),

                          icon: Icons
                              .business,

                          color:
                              Colors.blue,
                        ),

                        const SizedBox(
                            width: 14),

                        kpiCard(
                          title:
                              'Active Suppliers',

                          value:
                              activeSuppliers()
                                  .toString(),

                          icon: Icons
                              .verified,

                          color: Colors
                              .green,
                        ),
                      ],
                    ),

                    const SizedBox(
                        height: 18),

                    /*
                    |--------------------------------------------------------------------------
                    | Search
                    |--------------------------------------------------------------------------
                    */

                    Container(
                      padding:
                          const EdgeInsets
                              .all(18),

                      decoration:
                          BoxDecoration(
                        color:
                            Colors.white,

                        borderRadius:
                            BorderRadius
                                .circular(
                                    22),

                        border:
                            Border.all(
                          color: Colors
                              .grey
                              .shade200,
                        ),

                        boxShadow: [
                          BoxShadow(
                            color: Colors
                                .black
                                .withOpacity(
                                    0.03),

                            blurRadius:
                                10,

                            offset:
                                const Offset(
                                    0,
                                    4),
                          ),
                        ],
                      ),

                      child: Row(
                        children: [

                          Expanded(
                            child:
                                TextField(
                              controller:
                                  searchController,

                              onSubmitted:
                                  (_) {
                                loadSuppliers();
                              },

                              decoration:
                                  InputDecoration(
                                labelText:
                                    'Search supplier, BRN or VAT',

                                prefixIcon:
                                    const Icon(
                                  Icons
                                      .search,
                                ),

                                border:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                          14),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(
                              width: 12),

                          ElevatedButton
                              .icon(
                            onPressed:
                                loadSuppliers,

                            icon:
                                const Icon(
                              Icons.search,
                            ),

                            label:
                                const Text(
                              'Search',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                        height: 18),

                    /*
                    |--------------------------------------------------------------------------
                    | Supplier List
                    |--------------------------------------------------------------------------
                    */

                    Expanded(
                      child: isLoading

                          ? const Center(
                              child:
                                  CircularProgressIndicator(),
                            )

                          : suppliers
                                  .isEmpty

                              ? const Center(
                                  child:
                                      Text(
                                    'No suppliers found',
                                  ),
                                )

                              : ListView
                                  .builder(
                                  itemCount:
                                      suppliers
                                          .length,

                                  itemBuilder:
                                      (
                                    context,
                                    index,
                                  ) {
                                    return supplierCard(
                                      suppliers[
                                          index],
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}