import 'package:flutter/material.dart';

/*
|--------------------------------------------------------------------------
| Numeric Keypad Widget
|--------------------------------------------------------------------------
| Touch-friendly numeric keypad for POS terminals.
|
| Used for:
| - cash tendered amount
| - buzzer number later
| - quantity editing later
| - manual amount entry later
|
| This avoids dependency on a physical keyboard.
*/

class NumericKeypad extends StatelessWidget {
  /*
  |--------------------------------------------------------------------------
  | Callback Functions
  |--------------------------------------------------------------------------
  */

  final void Function(String value) onKeyTap;
  final VoidCallback onClear;
  final VoidCallback onBackspace;

  const NumericKeypad({
    super.key,
    required this.onKeyTap,
    required this.onClear,
    required this.onBackspace,
  });

  /*
  |--------------------------------------------------------------------------
  | Number Key
  |--------------------------------------------------------------------------
  */

  Widget _key(String value) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              onKeyTap(value);
            },
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Action Key
  |--------------------------------------------------------------------------
  */

  Widget _actionKey({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: onPressed,
            child: Icon(
              icon,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Build Keypad
  |--------------------------------------------------------------------------
  */

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _key('1'),
            _key('2'),
            _key('3'),
          ],
        ),

        Row(
          children: [
            _key('4'),
            _key('5'),
            _key('6'),
          ],
        ),

        Row(
          children: [
            _key('7'),
            _key('8'),
            _key('9'),
          ],
        ),

        Row(
          children: [
            _key('0'),
            _key('00'),
            _key('.'),
          ],
        ),

        Row(
          children: [
            _actionKey(
              icon: Icons.backspace,
              onPressed: onBackspace,
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: onClear,
                    child: const Text(
                      'C',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}