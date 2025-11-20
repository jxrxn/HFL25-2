// lib/ui/display_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:auto_size_text/auto_size_text.dart';

class DisplayWidget extends StatelessWidget {
  final String valueText;
  final String stripText;

  const DisplayWidget({
    super.key,
    required this.valueText,
    required this.stripText,
  });

  /// Tunna mellanrum för tusental (för tal i form "12345.67").
  /// Arbetar alltid med punkt som decimal internt.
  String _groupThousands(String s) {
    final numberPattern = RegExp(r'^-?\d+(\.\d+)?$');
    if (!numberPattern.hasMatch(s)) return s;

    final negative = s.startsWith('-');
    var body = negative ? s.substring(1) : s;

    final parts = body.split('.');
    var intPart = parts[0];
    final fracPart = parts.length > 1 ? '.${parts[1]}' : '';

    final buf = StringBuffer();
    var count = 0;

    for (var i = intPart.length - 1; i >= 0; i--) {
      buf.write(intPart[i]);
      count++;
      if (count == 3 && i != 0) {
        buf.write('\u202F'); // tunt mellanrum
        count = 0;
      }
    }

    final reversed = buf.toString().runes.toList().reversed;
    final groupedInt = String.fromCharCodes(reversed);

    return '${negative ? '-' : ''}$groupedInt$fracPart';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final stripColor = isDark
        ? scheme.onSurface.withValues(alpha: 0.7)
        : scheme.onSurface.withValues(alpha: 0.6);

    // 1) Gruppera tusental för huvudtalet (med punkt internt)
    final groupedValue = _groupThousands(valueText);

    // 2) Konvertera visningen till svensk stil:
    //    - huvudtalet med kommatecken
    //    - remsan med kommatecken
    final displayValue = groupedValue.replaceAll('.', ',');
    final displayStrip = stripText.replaceAll('.', ',');

    return Container(
      width: double.infinity,
      color: scheme.surfaceContainerHighest,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
// ===== ÖVRE REMSAN – horisontellt scrollbar & klickbar =====
SizedBox(
  height: (theme.textTheme.bodyLarge?.fontSize ?? 16) * 1.4,
  child: GestureDetector(
    behavior: HitTestBehavior.opaque, // hela ytan blir klickbar
    onTap: () {
      if (displayStrip.isEmpty) return;

      Clipboard.setData(ClipboardData(text: displayStrip));

      final snackBar = SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? scheme.surfaceContainerLow
            : scheme.surfaceContainerHighest,
        content: Text(
          'Uträkning kopierad',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurface,
          ),
        ),
        duration: const Duration(milliseconds: 900),
      );

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
    },
    child: Align(
      alignment: Alignment.centerRight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true, // visa slutet (senaste) till höger
        child: Text(
          displayStrip,
          textAlign: TextAlign.right,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: stripColor,
            letterSpacing: 0.5,
          ),
        ),
      ),
    ),
  ),
),

          const SizedBox(height: 8),

          // ===== STORA TALLET — klickbart & auto-size =====
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (valueText.isEmpty) return;

                // Kopierar råvärdet (med punkt) – bra för datorer / klistra in.
                Clipboard.setData(ClipboardData(text: valueText));

                final snackBar = SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: isDark
                      ? scheme.surfaceContainerLow
                      : scheme.surfaceContainerHighest,
                  content: Text(
                    'Tal kopierat',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                  duration: const Duration(milliseconds: 900),
                );

                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(snackBar);
              },
              child: Align(
                alignment: Alignment.bottomRight,
                child: AutoSizeText(
                  displayValue,
                  key: const Key('display'),
                  maxLines: 1,
                  minFontSize: 18,
                  stepGranularity: 1,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.displayMedium?.copyWith(
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