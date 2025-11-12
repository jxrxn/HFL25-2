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
        // Tillgänglig “canvas”
        final availW = c.maxWidth - horizontalPadding * 2;
        final availH = c.maxHeight;

        // 4 kolumner, 5 rader  → 3 resp. 4 gap
        final sideByW = (availW - gap * 3) / 4;
        final sideByH = (availH - gap * 4) / 5;
        final side = sideByW < sideByH ? sideByW : sideByH; // kvadrater!

        // Den verkliga rutnätsytan vi kommer att använda
        final gridW = side * 4 + gap * 3;
        final gridH = side * 5 + gap * 4;

        // Horisontellt: centrera inom paddat område
        final leftPad = horizontalPadding + (availW - gridW) / 2;

        // Vertikalt: bottenjustera (så sista raden linjerar i botten)
        final topPad = (availH - gridH);

        double xAt(int col) => leftPad + col * (side + gap);
        double yAt(int row) => topPad + row * (side + gap);

        Positioned btn(String label, int col, int row) => Positioned(
              left: xAt(col),
              top: yAt(row),
              width: side,
              height: side,
              child: CalcButton(
                label: label,
                onTap: () => onTap(label),
              ),
            );

        Positioned btnWide(String label, int col, int row) => Positioned(
              left: xAt(col),
              top: yAt(row),
              width: side * 2 + gap,
              height: side,
              child: CalcButton(
                label: label,
                onTap: () => onTap(label),
              ),
            );

        Positioned btnTall(String label, int col, int row) => Positioned(
              left: xAt(col),
              top: yAt(row),
              width: side,
              height: side * 2 + gap,
              child: CalcButton(
                label: label,
                onTap: () => onTap(label),
              ),
            );

        Positioned btnClear(int col, int row) => Positioned(
              left: xAt(col),
              top: yAt(row),
              width: side,
              height: side,
              child: GestureDetector(
                onLongPress: onLongClear, // långt tryck = AC
                child: CalcButton(
                  label: 'C',
                  onTap: () => onTap('C'), // kort tryck = backspace
                ),
              ),
            );

        return Stack(children: [
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
          btnTall('+', 3, 3),      // + = två rader hög (rad 3–4)

          // Rad 4
          btnClear(0, 4),          // C
          btnWide('=', 1, 4),      // = två kolumner bred
          // kolumn 3, rad 4 täcks av “+”
        ]);
      },
    );
  }
}