import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../calc_button.dart';

class ButtonGrid extends StatelessWidget {
  final void Function(String) onTap;
  final VoidCallback onLongClear;
  final double gap;
  final double horizontalPadding;

  const ButtonGrid({
    super.key,
    required this.onTap,
    required this.onLongClear,
    this.gap = 3.0,
    this.horizontalPadding = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    const cols = 4;
    const rows = 5;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;

        // Om vi inte fått någon bredd alls: rita inget.
        if (maxWidth <= 0) {
          return const SizedBox.shrink();
        }

        // Använd bredden (med padding) och höjden för att hitta en cellstorlek
        // som får hela 4x5-gridet att få plats.
        final usableWidth = maxWidth - horizontalPadding * 2;

        // Om usableWidth blir negativ → rita inget.
        if (usableWidth <= 0) {
          return const SizedBox.shrink();
        }

        final double cellFromWidth =
            (usableWidth - gap * (cols - 1)) / cols;

        // maxHeight kan vara oändlig (t.ex. i en Expanded); då låter vi höjden
        // inte begränsa oss.
        double cellFromHeight;
        if (maxHeight.isInfinite) {
          cellFromHeight = cellFromWidth;
        } else {
          cellFromHeight = (maxHeight - gap * (rows - 1)) / rows;
        }

        // Hitta minsta cellstorleken – men om den blir <= 0, rita inget.
        final double cellSize =
            math.min(cellFromWidth, cellFromHeight);

        if (!cellSize.isFinite || cellSize <= 0) {
          return const SizedBox.shrink();
        }

        final double gridWidth =
            cellSize * cols + gap * (cols - 1);
        final double gridHeight =
            cellSize * rows + gap * (rows - 1);

        Widget place(
          String label, {
          required int col,
          required int row,
          int colSpan = 1,
          int rowSpan = 1,
          bool isClear = false,
        }) {
          final double left = col * (cellSize + gap);
          final double top = row * (cellSize + gap);
          final double width =
              cellSize * colSpan + gap * (colSpan - 1);
          final double height =
              cellSize * rowSpan + gap * (rowSpan - 1);

          return Positioned(
            left: left,
            top: top,
            width: width,
            height: height,
            child: GestureDetector(
              onLongPress: isClear ? onLongClear : null,
              child: CalcButton(
                label: label,
                onTap: () => onTap(label),
              ),
            ),
          );
        }

        return Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: gridWidth + horizontalPadding * 2,
            height: gridHeight,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
              ),
              child: Stack(
                children: [
                  // Rad 1: 7 8 9 ÷
                  place('7', col: 0, row: 0),
                  place('8', col: 1, row: 0),
                  place('9', col: 2, row: 0),
                  place('÷', col: 3, row: 0),

                  // Rad 2: 4 5 6 ×
                  place('4', col: 0, row: 1),
                  place('5', col: 1, row: 1),
                  place('6', col: 2, row: 1),
                  place('×', col: 3, row: 1),

                  // Rad 3: 1 2 3 −
                  place('1', col: 0, row: 2),
                  place('2', col: 1, row: 2),
                  place('3', col: 2, row: 2),
                  place('−', col: 3, row: 2),

                  // Rad 4: 0 , % + (övre halvan av +)
                  place('0', col: 0, row: 3),
                  place(',', col: 1, row: 3),
                  place('%', col: 2, row: 3),
                  // '+' två rader hög: rader 3–4
                  place('+', col: 3, row: 3, rowSpan: 2),

                  // Rad 5: C  = =  (nedre raden)
                  place('C', col: 0, row: 4, isClear: true),
                  // '=' två kolumner bred: kolumn 1–2
                  place('=', col: 1, row: 4, colSpan: 2),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}