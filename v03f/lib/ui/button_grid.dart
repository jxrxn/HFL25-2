// lib/ui/button_grid.dart
import 'package:flutter/material.dart';
import '../calc_button.dart';

class ButtonGrid extends StatelessWidget {
  const ButtonGrid({
    super.key,
    required this.onTap,
    this.onLongClear,
    this.gap = 3,
    this.horizontalPadding = 16,
  });

  /// Anropas när en knapp trycks.
  final void Function(String value) onTap;

  /// Anropas vid långt tryck på C (AC-funktion).
  final VoidCallback? onLongClear;

  /// Mellanrum mellan knapparna.
  final double gap;

  /// Horisontell padding innanför den givna bredden.
  final double horizontalPadding;

  @override
    Widget build(BuildContext context) {
    String keySuffix(String label) {
      switch (label) {
        case '÷':
          return '/';
        case '×':
          return '*';
        case '−':
          return '-';
        default:
          return label;
      }
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final totalHeight = constraints.maxHeight;

        const cols = 4;
        const rows = 5;

        // Tillgänglig bredd för själva gridet (innanför padding).
        final maxGridWidth = totalWidth - horizontalPadding * 2;

        // Cellstorlek beroende på bredd
        final cellSizeByWidth = (maxGridWidth - gap * (cols - 1)) / cols;

        // Cellstorlek beroende på höjd
        final cellSizeByHeight =
            (totalHeight - gap * (rows - 1)) / rows;

        // Vi vill ha kvadratiska knappar → ta minsta värdet
        final cell = cellSizeByWidth < cellSizeByHeight
            ? cellSizeByWidth
            : cellSizeByHeight;

        final gridWidth = cell * cols + gap * (cols - 1);
        final gridHeight = cell * rows + gap * (rows - 1);

        // Centrera gridet inom ytan
        final startX = (totalWidth - gridWidth) / 2;
        final startY = (totalHeight - gridHeight) / 2;

        double xAt(int col) => startX + col * (cell + gap);
        double yAt(int row) => startY + row * (cell + gap);

        Widget btn(String label, int col, int row) => Positioned(
              left: xAt(col),
              top: yAt(row),
              width: cell,
              height: cell,
              child: CalcButton(
                label: label,
                onTap: () => onTap(label),
                buttonKey: Key('btn-${keySuffix(label)}'),
              ),
            );

        Widget btnWide(String label, int col, int row) => Positioned(
              left: xAt(col),
              top: yAt(row),
              width: cell * 2 + gap,
              height: cell,
              child: CalcButton(
                label: label,
                onTap: () => onTap(label),
                buttonKey: Key('btn-${keySuffix(label)}'),
              ),
            );

        Widget btnTall(String label, int col, int row) => Positioned(
              left: xAt(col),
              top: yAt(row),
              width: cell,
              height: cell * 2 + gap,
              child: CalcButton(
                label: label,
                onTap: () => onTap(label),
                buttonKey: Key('btn-${keySuffix(label)}'),
              ),
            );

        Widget btnClear(int col, int row) => Positioned(
              left: xAt(col),
              top: yAt(row),
              width: cell,
              height: cell,
              child: GestureDetector(
                onLongPress: onLongClear,
                child: CalcButton(
                  label: 'C',
                  onTap: () => onTap('C'),
                  buttonKey: const Key('btn-C'),
                ),
              ),
            );

        return Stack(
          children: [
            // Rad 0
            btn('7', 0, 0),
            btn('8', 1, 0),
            btn('9', 2, 0),
            btn('÷', 3, 0),

            // Rad 1
            btn('4', 0, 1),
            btn('5', 1, 1),
            btn('6', 2, 1),
            btn('×', 3, 1),

            // Rad 2
            btn('1', 0, 2),
            btn('2', 1, 2),
            btn('3', 2, 2),
            btn('−', 3, 2),

            // Rad 3
            btn('0', 0, 3),
            btn(',', 1, 3),
            btn('%', 2, 3),

            // Rad 4 (C + “=”)
            btnClear(0, 4),
            btnWide('=', 1, 4),

            // + är två rader hög (rad 3–4, kolumn 3)
            btnTall('+', 3, 3),
          ],
        );
      },
    );
  }
}