// lib/calc_button.dart
import 'package:flutter/material.dart';

class CalcButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress; // för C = AC
  final Key? buttonKey;

  const CalcButton({
    super.key,
    required this.label,
    required this.onTap,
    this.onLongPress,
    this.buttonKey,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isOp    = '÷×−+=/'.contains(label); // inkluderar visningssymboler
    final isClear = label == 'C';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isClear
        ? (isDark ? Colors.red.shade700 : Colors.red.shade200)
        : (isOp ? scheme.primary : scheme.surfaceContainerHighest);

    final fg = isClear
        ? (isDark ? Colors.white : Colors.brown.shade900)
        : (isOp ? scheme.onPrimary : scheme.onSurface);

    return ElevatedButton(
      key: buttonKey,
      onPressed: onTap,
      onLongPress: onLongPress,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 18),
      ),
      child: Text(label),
    );
  }
}