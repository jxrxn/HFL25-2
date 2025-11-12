// lib/ui/calc_button.dart
import 'package:flutter/material.dart';

class CalcButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Key? buttonKey;

  const CalcButton({
    super.key,
    required this.label,
    required this.onTap,
    this.buttonKey,
  });

  bool get _isOp    => '+-*/'.contains(label);
  bool get _isClear => label == 'C';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ElevatedButton(
      key: buttonKey,
      onPressed: onTap,
      style: ButtonStyle(
        // Bakgrundsfärg: röd för C, primär för operator, neutral för siffra
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (_isClear) return cs.errorContainer;
          if (_isOp)    return cs.primaryContainer;
          return cs.surfaceContainerHighest;
        }),
        // Textfärg: kontrast mot bakgrunden
        foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (_isClear) return cs.onErrorContainer;
          if (_isOp)    return cs.onPrimaryContainer;
          return cs.onSurface;
        }),
        // Ripple/hover (android/iOS använder pressed)
        overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.pressed)) {
            // ersätter withOpacity(0.08)
            return Colors.white.withValues(alpha: 0.08);
          }
          return null;
        }),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 18),
        ),
      ),
      child: Text(label),
    );
  }
}