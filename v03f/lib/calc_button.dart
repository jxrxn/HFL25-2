import 'package:flutter/material.dart';

class CalcButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  /// Nyckel för själva knappen (används i tester)
  final Key? buttonKey;

  const CalcButton({
    super.key,
    required this.label,
    required this.onTap,
    this.buttonKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    // -- Typ --
    final bool isClear = label == 'C';
    final bool isEquals = label == '=';
    final bool isOp = ['+', '−', '×', '÷'].contains(label);

    // -- Blå "=" variant --
    // Ljust tema → blekare blå
    // Mörkt tema → starkare blå
    final Color equalsBg = isDark
        ? const Color(0xFF2563EB)  // starkare blå (typ Tailwind "blue-600")
        : const Color(0xFF93C5FD); // ljusare blå ("blue-300")

    final Color equalsFg = isDark
        ? Colors.white
        : Colors.black87;

    // -- Standardoperatorer --
    final Color opBg = scheme.primaryContainer;
    final Color opFg = scheme.onPrimaryContainer;

    // -- Övriga knappar --
    final Color numBg = scheme.surfaceContainerHighest;
    final Color numFg = scheme.onSurface;

    // -- Bakgrundsfärg --
    final Color bg = isClear
        ? Colors.red.shade700
        : (isEquals
            ? equalsBg
            : (isOp ? opBg : numBg));

    // -- Textfärg --
    final Color fg = isClear
        ? Colors.white
        : (isEquals
            ? equalsFg
            : (isOp ? opFg : numFg));

    return ElevatedButton(
      key: buttonKey,
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        padding: EdgeInsets.zero, // storlek styrs av ButtonGrid
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Text(label),
    );
  }
}