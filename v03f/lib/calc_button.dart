import 'package:flutter/material.dart';

class CalcButton extends StatelessWidget {
  const CalcButton({
    super.key,
    required this.label,
    required this.onTap,
    this.onLongPress,
  });

  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  bool get _isOp => const {'÷','×','−','+'}.contains(label);
  bool get _isClear => label == 'C';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Färger
    final Color bg = _isClear
        ? Colors.red.shade700
        : (_isOp ? scheme.primaryContainer : scheme.surfaceContainerHighest);
    final Color fg = _isClear
        ? Colors.white
        : (_isOp ? scheme.onPrimaryContainer : scheme.onSurface);

    return AspectRatio(
      aspectRatio: 1, // kvadrat
      child: ElevatedButton(
        onPressed: onTap,
        onLongPress: onLongPress,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((_) => bg),
          foregroundColor: WidgetStateProperty.resolveWith((_) => fg),
          textStyle: WidgetStateProperty.resolveWith(
            (_) => const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
          shape: WidgetStateProperty.resolveWith(
            (_) => RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          padding: WidgetStateProperty.resolveWith(
            (_) => const EdgeInsets.symmetric(vertical: 18),
          ),
          // Inga deprecated MaterialState/withOpacity här
        ),
        child: Text(label),
      ),
    );
  }
}