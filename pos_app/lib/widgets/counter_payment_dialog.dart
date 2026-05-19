import 'package:flutter/material.dart';

import '../utils/money.dart';
import '../utils/discount.dart';
import 'numeric_keypad.dart';

/*
|--------------------------------------------------------------------------
| Counter Payment Dialog
|--------------------------------------------------------------------------
| Commercial fast-food style payment popup.
|
| Used by Counter POS after cashier presses PAY.
|
| Handles:
| - payment method
| - discount
| - buzzer number
| - cash tendered
| - change calculation
| - payment confirmation
*/

class CounterPaymentDialog extends StatefulWidget {
  final double subtotalAmount;

  const CounterPaymentDialog({super.key, required this.subtotalAmount});

  @override
  State<CounterPaymentDialog> createState() => _CounterPaymentDialogState();
}

class _CounterPaymentDialogState extends State<CounterPaymentDialog> {
  /*
  |--------------------------------------------------------------------------
  | Payment State
  |--------------------------------------------------------------------------
  */

  String paymentMethod = 'cash';
  double discountPercentage = 0;
  String tenderedInput = '';
  String inputMode = 'cash';

  /*
  |--------------------------------------------------------------------------
  | Controllers
  |--------------------------------------------------------------------------
  */

  final TextEditingController buzzerController = TextEditingController();

  /*
  |--------------------------------------------------------------------------
  | Options
  |--------------------------------------------------------------------------
  */

  final List<String> paymentMethods = [
    'cash',
    'card',
    'juice',
    'cheque',
    'complimentary',
  ];

  final List<double> discountOptions = [0, 5, 10, 15, 50, 100];

  @override
  void dispose() {
    buzzerController.dispose();
    super.dispose();
  }

  /*
  |--------------------------------------------------------------------------
  | Calculations
  |--------------------------------------------------------------------------
  */

  double get discountAmount {
    return calculateDiscountAmount(
      subtotal: widget.subtotalAmount,
      discountPercentage: discountPercentage,
    );
  }

  double get finalTotal {
    return calculateFinalTotal(
      subtotal: widget.subtotalAmount,
      discountPercentage: discountPercentage,
    );
  }

  double get vatIncluded {
    return calculateVatIncluded(finalTotal);
  }

  double get tenderedAmount {
    return double.tryParse(tenderedInput) ?? 0;
  }

  double get changeAmount {
    final change = tenderedAmount - finalTotal;

    if (change < 0) {
      return 0;
    }

    return change;
  }

  bool get canConfirm {
    if (paymentMethod == 'cash') {
      return tenderedAmount >= finalTotal;
    }

    return true;
  }

  /*
  |--------------------------------------------------------------------------
  | Keypad Actions
  |--------------------------------------------------------------------------
  */

  void keypadTap(String value) {
    setState(() {
      /*
    |--------------------------------------------------------------------------
    | Buzzer Mode
    |--------------------------------------------------------------------------
    */

      if (inputMode == 'buzzer') {
        buzzerController.text += value;
        return;
      }

      /*
    |--------------------------------------------------------------------------
    | Cash Mode
    |--------------------------------------------------------------------------
    */

      if (value == '.' && tenderedInput.contains('.')) {
        return;
      }

      tenderedInput += value;
    });
  }

  void keypadClear() {
    setState(() {
      /*
    |--------------------------------------------------------------------------
    | Clear Buzzer
    |--------------------------------------------------------------------------
    */

      if (inputMode == 'buzzer') {
        buzzerController.clear();
        return;
      }

      /*
    |--------------------------------------------------------------------------
    | Clear Cash
    |--------------------------------------------------------------------------
    */

      tenderedInput = '';
    });
  }

  void keypadBackspace() {
    setState(() {
      /*
    |--------------------------------------------------------------------------
    | Buzzer Mode
    |--------------------------------------------------------------------------
    */

      if (inputMode == 'buzzer') {
        if (buzzerController.text.isNotEmpty) {
          buzzerController.text = buzzerController.text.substring(
            0,
            buzzerController.text.length - 1,
          );
        }

        return;
      }

      /*
    |--------------------------------------------------------------------------
    | Cash Mode
    |--------------------------------------------------------------------------
    */

      if (tenderedInput.isNotEmpty) {
        tenderedInput = tenderedInput.substring(0, tenderedInput.length - 1);
      }
    });
  }

  void setExactCash() {
    setState(() {
      tenderedInput = finalTotal.toStringAsFixed(2);
    });
  }

  void setCashShortcut(String value) {
    setState(() {
      tenderedInput = value;
    });
  }

  /*
  |--------------------------------------------------------------------------
  | Confirm Payment
  |--------------------------------------------------------------------------
  */

  void confirmPayment() {
    Navigator.pop(context, {
      'payment_method': paymentMethod,
      'discount_percentage': discountPercentage,
      'discount_amount': discountAmount,
      'subtotal': widget.subtotalAmount,
      'tax_amount': vatIncluded,
      'total_amount': finalTotal,
      'buzzer_number': buzzerController.text.trim(),
      'cash_tendered': tenderedAmount,
      'change_amount': changeAmount,
    });
  }

  /*
  |--------------------------------------------------------------------------
  | Build
  |--------------------------------------------------------------------------
  */

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Payment'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Center(
          child: SizedBox(
            width: 1000,

            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),

                child: Column(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    /*
                |--------------------------------------------------------------------------
                | Main Content
                |--------------------------------------------------------------------------
                */
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        /*
                    |--------------------------------------------------------------------------
                    | Left Side: Payment Options
                    |--------------------------------------------------------------------------
                    */
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,

                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              /*
                          |--------------------------------------------------------------------------
                          | Title
                          |--------------------------------------------------------------------------
                          */
                              const Text(
                                'Payment',

                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 18),

                              /*
                              |--------------------------------------------------------------------------
                              | Buzzer Number
                              |--------------------------------------------------------------------------
                              */
                              TextField(
                                controller: buzzerController,
                                readOnly: true,

                                onTap: () {
                                  setState(() {
                                    inputMode = 'buzzer';
                                  });
                                },

                                decoration: InputDecoration(
                                  labelText: 'Buzzer Number',
                                  hintText: 'Tap to enter',

                                  prefixIcon: const Icon(
                                    Icons.notifications_active,
                                  ),

                                  suffixIcon: inputMode == 'buzzer'
                                      ? const Icon(
                                          Icons.dialpad,
                                          color: Colors.orange,
                                        )
                                      : null,

                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),

                              /*
                          |--------------------------------------------------------------------------
                          | Payment Method
                          |--------------------------------------------------------------------------
                          */
                              const Text(
                                'Payment Method',

                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),

                              const SizedBox(height: 8),

                              Wrap(
                                spacing: 8,
                                runSpacing: 8,

                                children: paymentMethods.map((method) {
                                  return ChoiceChip(
                                    label: Text(method.toUpperCase()),

                                    selected: paymentMethod == method,

                                    onSelected: (_) {
                                      setState(() {
                                        paymentMethod = method;

                                        if (method == 'complimentary') {
                                          discountPercentage = 100;

                                          tenderedInput = '';
                                        }

                                        if (method != 'cash') {
                                          tenderedInput = '';
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),

                              const SizedBox(height: 18),

                              /*
                          |--------------------------------------------------------------------------
                          | Discount
                          |--------------------------------------------------------------------------
                          */
                              const Text(
                                'Discount',

                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),

                              const SizedBox(height: 8),

                              Wrap(
                                spacing: 8,
                                runSpacing: 8,

                                children: discountOptions.map((discount) {
                                  return ChoiceChip(
                                    label: Text(
                                      '${discount.toStringAsFixed(0)}%',
                                    ),

                                    selected: discountPercentage == discount,

                                    onSelected: (_) {
                                      setState(() {
                                        discountPercentage = discount;

                                        if (discount == 100) {
                                          paymentMethod = 'complimentary';

                                          tenderedInput = '';
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),

                              const SizedBox(height: 18),

                              /*
                          |--------------------------------------------------------------------------
                          | Totals
                          |--------------------------------------------------------------------------
                          */
                              _PaymentSummaryRow(
                                label: 'Subtotal',

                                value: formatMoney(widget.subtotalAmount),
                              ),

                              _PaymentSummaryRow(
                                label:
                                    'Discount (${discountPercentage.toStringAsFixed(0)}%)',

                                value: '- ${formatMoney(discountAmount)}',
                              ),

                              _PaymentSummaryRow(
                                label: 'VAT Included',

                                value: formatMoney(vatIncluded),
                              ),

                              const Divider(),

                              _PaymentSummaryRow(
                                label: 'TOTAL',

                                value: formatMoney(finalTotal),

                                isBold: true,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 24),

                        /*
                    |--------------------------------------------------------------------------
                    | Right Side: Cash Keypad
                    |--------------------------------------------------------------------------
                    */
                        Expanded(
                          child: paymentMethod == 'cash'
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,

                                  children: [
                                    /*
                                    |--------------------------------------------------------------------------
                                    | Cash Tendered Title
                                    |--------------------------------------------------------------------------
                                    */
                                    const Text(
                                      'Cash Tendered',

                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    /*
                                    |--------------------------------------------------------------------------
                                    | Tendered Display
                                    |--------------------------------------------------------------------------
                                    */
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          inputMode = 'cash';
                                        });
                                      },

                                      child: Container(
                                        width: double.infinity,

                                        padding: const EdgeInsets.all(16),

                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,

                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),

                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),

                                        child: Text(
                                          tenderedInput.isEmpty
                                              ? 'Rs 0.00'
                                              : formatMoney(tenderedAmount),

                                          textAlign: TextAlign.right,

                                          style: const TextStyle(
                                            fontSize: 30,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    /*
                                    |--------------------------------------------------------------------------
                                    | Quick Cash Buttons
                                    |--------------------------------------------------------------------------
                                    */
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,

                                      children: [
                                        OutlinedButton(
                                          onPressed: setExactCash,

                                          child: const Text('Exact'),
                                        ),

                                        OutlinedButton(
                                          onPressed: () {
                                            setCashShortcut('500');
                                          },

                                          child: const Text('500'),
                                        ),

                                        OutlinedButton(
                                          onPressed: () {
                                            setCashShortcut('1000');
                                          },

                                          child: const Text('1000'),
                                        ),

                                        OutlinedButton(
                                          onPressed: () {
                                            setCashShortcut('2000');
                                          },

                                          child: const Text('2000'),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 8),

                                    /*
                                    |--------------------------------------------------------------------------
                                    | Change Amount
                                    |--------------------------------------------------------------------------
                                    */
                                    _PaymentSummaryRow(
                                      label: 'Change',

                                      value: formatMoney(changeAmount),

                                      isBold: true,
                                    ),

                                    const SizedBox(height: 8),

                                    /*
                                    |--------------------------------------------------------------------------
                                    | Numeric Keypad
                                    |--------------------------------------------------------------------------
                                    */
                                    NumericKeypad(
                                      onKeyTap: keypadTap,

                                      onClear: keypadClear,

                                      onBackspace: keypadBackspace,
                                    ),
                                  ],
                                )
                              : Center(
                                  child: Text(
                                    paymentMethod == 'complimentary'
                                        ? 'Complimentary transaction'
                                        : 'Confirm ${paymentMethod.toUpperCase()} payment after terminal approval.',

                                    textAlign: TextAlign.center,

                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    /*
                |--------------------------------------------------------------------------
                | Payment Action Buttons
                |--------------------------------------------------------------------------
                */
                    Row(
                      children: [
                        /*
                    |--------------------------------------------------------------------------
                    | Cancel Button
                    |--------------------------------------------------------------------------
                    */
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                            },

                            icon: const Icon(Icons.close),

                            label: const Text('Cancel'),
                          ),
                        ),

                        const SizedBox(width: 12),

                        /*
                    |--------------------------------------------------------------------------
                    | Pay Button
                    |--------------------------------------------------------------------------
                    */
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: canConfirm ? confirmPayment : null,

                            icon: const Icon(Icons.check_circle),

                            label: const Text('Pay'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/*
|--------------------------------------------------------------------------
| Payment Summary Row
|--------------------------------------------------------------------------
*/

class _PaymentSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _PaymentSummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: isBold ? 22 : 16,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
