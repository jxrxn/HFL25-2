// lib/ui/button_grid.dart
import 'package:flutter/material.dart';
import '../calc_button.dart';

class ButtonGrid extends StatelessWidget {
  const ButtonGrid({
    super.key,
    required this.onTap,
    this.onLongClear,
    this.gap = 12,
    this.horizontalPadding = 16,
  });

  final void Function(String value) onTap;
  final VoidCallback? onLongClear;
  final double gap;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final totalWidth = c.maxWidth;
        final totalHeight = c.maxHeight;

        const cols = 4;
        const rows = 5;

        // Kvadratiska celler
        final maxGridWidth = totalWidth - horizontalPadding * 2;
        final cellSizeByWidth = (maxGridWidth - gap * (cols - 1)) / cols;
        final cellSizeByHeight =
            (totalHeight - gap * (rows - 1)) / rows;
        final cell = cellSizeByWidth < cellSizeByHeight
            ? cellSizeByWidth
            : cellSizeByHeight;

        final gridWidth = cell * cols + gap * (cols - 1);
        final gridHeight = cell * rows + gap * (rows - 1);

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