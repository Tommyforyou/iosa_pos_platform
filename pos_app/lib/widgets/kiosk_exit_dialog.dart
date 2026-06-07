import 'package:flutter/material.dart';

/*
|--------------------------------------------------------------------------
| Kiosk Exit Dialog
|--------------------------------------------------------------------------
*/

class KioskExitDialog extends StatefulWidget {
  const KioskExitDialog({super.key});

  @override
  State<KioskExitDialog> createState() => _KioskExitDialogState();
}

class _KioskExitDialogState extends State<KioskExitDialog> {
  /*
  |--------------------------------------------------------------------------
  | Controller
  |--------------------------------------------------------------------------
  */

  final TextEditingController pinController = TextEditingController();

  String? error;

  /*
  |--------------------------------------------------------------------------
  | Validate PIN
  |--------------------------------------------------------------------------
  */

  void validatePin() {
    if (pinController.text == '1234') {
      Navigator.pop(context, true);
    } else {
      setState(() {
        error = 'Invalid PIN';
      });
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Build
  |--------------------------------------------------------------------------
  */

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Exit Kiosk'),

      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter manager PIN'),

          const SizedBox(height: 15),

          TextField(
            controller: pinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              errorText: error,
            ),
          ),
        ],
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, false);
          },
          child: const Text('Cancel'),
        ),

        ElevatedButton(onPressed: validatePin, child: const Text('Exit')),
      ],
    );
  }
}
