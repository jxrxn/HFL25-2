// lib/ui/display_widget.dart
import 'package:flutter/material.dart';

class DisplayWidget extends StatelessWidget {
  final String valueText;
  final String stripText;

  const DisplayWidget({
    super.key,
    required this.valueText,
    required this.stripText,
  });

  // Lägg in tunna mellanslag som tusentalsavgränsare i heltalsdelen.
  // Format vi stöttar här: -1234, -1234.56, 1234, 1234.56
  String _groupThousands(String s) {
    final numberPattern = RegExp(r'^-?\d+(\.\d+)?$');
    if (!numberPattern.hasMatch(s)) return s; // t.ex. "Error" – lämna orörd

    final negative = s.startsWith('-');
    var body = negative ? s.substring(1) : s;

    final parts = body.split('.');
    var intPart = parts[0];
    final fracPart = parts.length > 1 ? '.${parts[1]}' : '';

    final buf = StringBuffer();
    var count = 0;

    // Bygg från höger → vänster
    for (var i = intPart.length - 1; i >= 0; i--) {
      buf.write(intPart[i]);
      count++;
      if (count == 3 && i != 0) {
        buf.write('\u2009'); // tunt mellanrum
        count = 0;
      }
    }

    // Vänd tillbaka
    final reversed = buf.toString().runes.toList().reversed;
    final groupedInt = String.fromCharCodes(reversed);

    final sign = negative ? '-' : '';
    return '$sign$groupedInt$fracPart';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final stripColor = isDark
        ? scheme.onSurface.withValues(alpha: 0.7)
        : scheme.onSurface.withValues(alpha: 0.6);

    final groupedValue = _groupThousands(valueText);

    return Container(
      width: double.infinity,
      color: scheme.surfaceContainerHighest,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Smala remsan med uttrycket
          Text(
            stripText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: stripColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          // Stora talet, nere till höger, kan scrollas horisontellt
          Expanded(
            child: Align(
              alignment: Alignment.bottomRight,
              child: SingleChildScrollView(
                reverse: true,
                scrollDirection: Axis.horizontal,
                child: Text(
                  groupedValue,
                  key: const Key('display'),
                  maxLines: 1,
                  softWrap: false,
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}