import 'package:flutter/material.dart';

class CalcButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  /// Ny: key för *den tryckbara knappen*
  final Key? buttonKey;

  const CalcButton({
    super.key,
    required this.label,
    required this.onTap,
    this.buttonKey,
  });

  @override
  Widget build(BuildContext context) {
    final isOp = '+-*/'.contains(label);
    final isClear = label == 'C';

    return ElevatedButton(
      key: buttonKey,                    // <-- lägg nyckeln här
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isClear
            ? Colors.red.shade700
            : (isOp ? Colors.deepPurple : Colors.grey[800]),
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 18),
      ),
      child: Text(label),
    );
  }
}